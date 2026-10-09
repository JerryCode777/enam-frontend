import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/aula_models.dart';
import '../domain/segundos_vistos.dart';
import 'aula_providers.dart';
import 'widgets/presentacion.dart';

/// El catálogo del aula: «Seguir viendo», el repaso final destacado y los
/// cursos por área. Los textos son los de `CursosScreen.tsx`.
class CursosScreen extends ConsumerWidget {
  const CursosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursos = ref.watch(cursosProvider);

    return Scaffold(
      appBar: const GradientHeader(
        titulo: 'Cursos',
        // El de la web («Clases en video del temario oficial del ENAM, cada
        // una con su práctica.») no cabe junto al botón de atrás en un
        // teléfono: se corta. Este dice lo mismo en lo que cabe.
        subtitulo: 'Clases en video, cada una con su práctica',
      ),
      body: cursos.when(
        loading: () => const _Cargando(),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: StateBanner(
            kind: BannerKind.error,
            message: 'No pudimos cargar los cursos.',
            action: TextButton(
              onPressed: () => ref.invalidate(cursosProvider),
              child: const Text('Reintentar'),
            ),
          ),
        ),
        data: (lista) => RefreshIndicator(
          onRefresh: () async {
            refrescarAvance(ref);
            await ref.read(cursosProvider.future);
          },
          child: _Catalogo(cursos: lista),
        ),
      ),
    );
  }
}

class _Catalogo extends StatelessWidget {
  const _Catalogo({required this.cursos});

  final List<CursoResumen> cursos;

  @override
  Widget build(BuildContext context) {
    // El repaso final va primero y en grande: es el curso de las últimas
    // semanas, y no es un área más.
    final repaso = cursos.where((c) => c.esRepaso).toList();
    final areas = cursos.where((c) => !c.esRepaso).toList();
    final nadaTodavia = cursos.every((c) => c.proximamente);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space8,
      ),
      children: [
        const _SeguirViendo(),
        if (nadaTodavia) ...[
          const _PrimerasClases(),
          const SizedBox(height: DesignTokens.space4),
        ],
        for (final c in repaso) ...[
          _TarjetaDeCurso(curso: c, destacado: true),
          const SizedBox(height: DesignTokens.space4),
        ],
        if (areas.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: DesignTokens.space1,
              bottom: DesignTokens.space2,
            ),
            child: Text(
              'Por área',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _Rejilla(cursos: areas),
        ],
      ],
    );
  }
}

/// Una columna en el teléfono y dos en cuanto caben.
class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.cursos});

  final List<CursoResumen> cursos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 600 ? 2 : 1;
        const hueco = DesignTokens.space3;
        final ancho =
            (constraints.maxWidth - hueco * (columnas - 1)) / columnas;
        return Wrap(
          spacing: hueco,
          runSpacing: hueco,
          children: [
            for (final c in cursos)
              SizedBox(
                width: ancho,
                child: _TarjetaDeCurso(curso: c),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaDeCurso extends StatelessWidget {
  const _TarjetaDeCurso({required this.curso, this.destacado = false});

  final CursoResumen curso;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    // Sin ninguna clase en el temario no hay nada que abrir. Con temario pero
    // sin videos sí: se ve lo que viene.
    final abrible = curso.clases > 0;

    final contenido = curso.portadaUrl == null
        ? _SinPortada(curso: curso, destacado: destacado)
        : _ConPortada(curso: curso);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: abrible
          ? InkWell(
              onTap: () => context.irA(Routes.cursoOf(curso.id)),
              child: contenido,
            )
          : Semantics(
              label: '${curso.titulo}, próximamente',
              child: ExcludeSemantics(child: contenido),
            ),
    );
  }
}

/// Con la portada compuesta: ya trae el nombre, el profe y las clases, así
/// que debajo va solo lo que es de esta cuenta: el avance y «Seguir viendo».
class _ConPortada extends ConsumerWidget {
  const _ConPortada({required this.curso});

  final CursoResumen curso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seguir = ref.watch(seguirViendoProvider).value;
    final aMedias = seguir?.cursoId == curso.id ? seguir : null;
    final debajo = [
      if (curso.proximamente)
        const Align(
          alignment: Alignment.centerLeft,
          child: EtiquetaProximamente(),
        ),
      if (curso.completadas > 0) _Avance(curso: curso),
      if (aMedias != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () =>
                context.irA(Routes.claseOf(curso.id, aMedias.clase.id)),
            icon: const Icon(Symbols.play_circle, fill: 1),
            label: const Text('Seguir viendo'),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A todo el ancho de la tarjeta, que ya recorta las esquinas.
        PortadaDeCurso(
          titulo: curso.titulo,
          areaId: curso.areaId,
          portadaUrl: curso.portadaUrl,
          radio: 0,
        ),
        if (debajo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space3,
              DesignTokens.space3,
              DesignTokens.space3,
              DesignTokens.space2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: DesignTokens.space2,
              children: debajo,
            ),
          ),
      ],
    );
  }
}

/// Sin portada: el degradado del área con el título, el lema, el profe y las
/// clases.
class _SinPortada extends StatelessWidget {
  const _SinPortada({required this.curso, required this.destacado});

  final CursoResumen curso;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortadaDeCurso(
          titulo: curso.titulo,
          areaId: curso.areaId,
          radio: DesignTokens.radiusMd,
        ),
        Padding(
          padding: const EdgeInsets.all(DesignTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (destacado) ...[
                Text(
                  'Para las últimas semanas',
                  style: context.texts.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: context.scheme.primary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
              ],
              if (curso.lema.isNotEmpty) ...[
                Text(
                  curso.lema,
                  style: context.texts.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
              ],
              if (curso.profe case final profe?) ...[
                LineaDelProfe(profe: profe, areaId: curso.areaId),
                const SizedBox(height: DesignTokens.space3),
              ],
              _Pie(curso: curso),
            ],
          ),
        ),
      ],
    );
  }
}

/// «N de M vistas», con su barra.
class _Avance extends StatelessWidget {
  const _Avance({required this.curso});

  final CursoResumen curso;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BarraDeAvance(
          valor: curso.completadas / curso.disponibles,
          etiqueta: 'Avance en ${curso.titulo}',
          color: colorDeCurso(context, curso.areaId),
        ),
        const SizedBox(height: DesignTokens.space1),
        Text(
          '${curso.completadas} de ${curso.disponibles} vistas',
          style: context.texts.bodySmall,
        ),
      ],
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.curso});

  final CursoResumen curso;

  @override
  Widget build(BuildContext context) {
    if (curso.proximamente) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: EtiquetaProximamente(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${clasesEnTexto(curso.disponibles)} · '
          '${duracionCorta(curso.duracionS)}',
          style: context.texts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (curso.completadas > 0) ...[
          const SizedBox(height: DesignTokens.space2),
          _Avance(curso: curso),
        ],
      ],
    );
  }
}

/// La clase a medias más reciente. Sin nada a medias no se pinta.
class _SeguirViendo extends ConsumerWidget {
  const _SeguirViendo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seguir = ref.watch(seguirViendoProvider).value;
    if (seguir == null) return const SizedBox.shrink();
    final clase = seguir.clase;
    final scheme = context.scheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.irA(Routes.claseOf(seguir.cursoId, clase.id)),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                Icon(
                  Symbols.play_circle,
                  size: 40,
                  fill: 1,
                  color: scheme.primary,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seguir viendo · ${seguir.cursoTitulo}',
                        style: context.texts.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clase.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          // Sin color propio en el tema: en oscuro salía negro.
                          color: context.scheme.onSurface,
                        ),
                      ),
                      if (clase.duracionS > 0) ...[
                        const SizedBox(height: DesignTokens.space2),
                        BarraDeAvance(
                          valor:
                              clase.progreso.segundosVistos / clase.duracionS,
                          etiqueta: 'Lo que llevas de la clase',
                          alto: 4,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimerasClases extends StatelessWidget {
  const _PrimerasClases();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Las primeras clases llegan muy pronto',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              'Estamos grabando los cursos con referencias de normas, guías y '
              'libros. Mientras, mira lo que viene.',
              style: context.texts.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space4),
            child: SkeletonBox(height: 260, radius: DesignTokens.radiusLg),
          ),
      ],
    );
  }
}
