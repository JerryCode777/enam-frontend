import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../subscription/presentation/widgets/opciones_de_pago.dart'
    show enTiendaApple;
import '../domain/aula_models.dart';
import '../domain/segundos_vistos.dart';
import 'aula_providers.dart';
import 'muro_de_cursos.dart';
import 'widgets/presentacion.dart';
import 'widgets/temario_del_curso.dart';

/// Un curso: de qué va, quién lo da, cuánto llevas y su temario.
///
/// El botón para seguir lleva a `continuar`, que decide el servidor: la
/// próxima clase sin completar que la cuenta puede abrir. Como la web.
class CursoScreen extends ConsumerWidget {
  const CursoScreen({required this.cursoId, super.key});

  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curso = ref.watch(cursoProvider(cursoId));

    return Scaffold(
      appBar: GradientHeader(titulo: curso.value?.titulo ?? 'Curso'),
      body: curso.when(
        loading: () => const _Cargando(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: StateBanner(
            kind: BannerKind.error,
            message: e is NotFoundFailure
                ? 'Este curso no existe.'
                : 'No pudimos cargar el curso.',
            action: e is NotFoundFailure
                ? null
                : TextButton(
                    onPressed: () => ref.invalidate(cursoProvider(cursoId)),
                    child: const Text('Reintentar'),
                  ),
          ),
        ),
        data: (c) => RefreshIndicator(
          onRefresh: () => ref.refresh(cursoProvider(cursoId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space4,
              DesignTokens.space4,
              DesignTokens.space8,
            ),
            children: [
              _Presentacion(curso: c),
              if (!c.premium && c.gratis > 0) ...[
                const SizedBox(height: DesignTokens.space4),
                _ClasesGratis(gratis: c.gratis),
              ],
              const SizedBox(height: DesignTokens.space6),
              Text(
                'Temario',
                style: context.texts.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              TemarioDelCurso(curso: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _Presentacion extends StatelessWidget {
  const _Presentacion({required this.curso});

  final Curso curso;

  @override
  Widget build(BuildContext context) {
    final porVenir = curso.clases - curso.disponibles;
    final continuar = curso.continuar;
    final empezado =
        curso.completadas > 0 || (continuar?.progreso.segundosVistos ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortadaDeCurso(
          titulo: curso.titulo,
          areaId: curso.areaId,
          portadaUrl: curso.portadaUrl,
        ),
        const SizedBox(height: DesignTokens.space4),
        if (curso.lema.isNotEmpty)
          Text(
            curso.lema,
            style: context.texts.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              // Sin color propio en el tema: en oscuro salía negro.
              color: context.scheme.onSurface,
              height: DesignTokens.lineHeightTight,
            ),
          ),
        if (curso.descripcion.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.space2),
          Text(
            curso.descripcion,
            style: context.texts.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
        if (curso.profe case final profe?) ...[
          const SizedBox(height: DesignTokens.space4),
          LineaDelProfe(
            profe: profe,
            areaId: curso.areaId,
            subtitulo: 'Profe del curso',
            tamano: 44,
          ),
        ],
        const SizedBox(height: DesignTokens.space4),
        Text(
          curso.disponibles == 0
              ? 'Las clases de este curso llegan pronto.'
              : '${clasesEnTexto(curso.disponibles)} · '
                    '${duracionCorta(curso.duracionS)}'
                    '${porVenir > 0 ? ' · $porVenir más en camino' : ''}',
          style: context.texts.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (curso.disponibles > 0) ...[
          const SizedBox(height: DesignTokens.space2),
          BarraDeAvance(
            valor: curso.completadas / curso.disponibles,
            etiqueta: 'Avance en ${curso.titulo}',
            color: colorDeCurso(context, curso.areaId),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            '${curso.completadas} de ${curso.disponibles} clases vistas',
            style: context.texts.bodySmall,
          ),
        ],
        if (continuar != null) ...[
          const SizedBox(height: DesignTokens.space4),
          EnamButton(
            label: empezado ? 'Seguir con el curso' : 'Empezar el curso',
            icon: Symbols.play_arrow,
            onPressed: () =>
                context.irA(Routes.claseOf(curso.id, continuar.id)),
          ),
        ],
      ],
    );
  }
}

/// Cuántas clases de este curso abre la cuenta gratis.
class _ClasesGratis extends ConsumerWidget {
  const _ClasesGratis({required this.gratis});

  final int gratis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final success = context.states.success;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: success.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: gratis == 1
                      ? 'Tienes 1 clase gratis'
                      : 'Tienes $gratis clases gratis',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                  text:
                      ' en este curso, con su práctica. El resto es de '
                      'Premium.',
                ),
              ],
            ),
            style: context.texts.bodyMedium?.copyWith(
              color: success.onTint,
              height: 1.5,
            ),
          ),
          // En Android no se vende en la app: sin botón (ver
          // `abrirMuroDeCursos`).
          if (enTiendaApple)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => abrirMuroDeCursos(context, ref),
              child: const Text('Ver Premium'),
            ),
        ],
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
      children: const [
        SkeletonBox(height: 190, radius: DesignTokens.radiusLg),
        SizedBox(height: DesignTokens.space4),
        SkeletonBox(height: 28, radius: DesignTokens.radiusSm),
        SizedBox(height: DesignTokens.space2),
        SkeletonBox(height: 60, radius: DesignTokens.radiusSm),
        SizedBox(height: DesignTokens.space6),
        SkeletonBox(height: 280, radius: DesignTokens.radiusLg),
      ],
    );
  }
}
