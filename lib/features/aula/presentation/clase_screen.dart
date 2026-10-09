import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'reproductor/reproductor_de_clase.dart';
import 'widgets/presentacion.dart';
import 'widgets/temario_del_curso.dart';

/// La clase: el video, cómo practicarla, de qué va y sus referencias.
///
/// Los textos son los de `ClaseScreen.tsx` de la web. Debajo va el temario del
/// curso, que en la web es la columna de al lado.
class ClaseScreen extends ConsumerWidget {
  const ClaseScreen({required this.cursoId, required this.claseId, super.key});

  final String cursoId;
  final String claseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clase = ref.watch(claseProvider(claseId));
    final curso = ref.watch(cursoProvider(cursoId)).value;

    // La clase es de pago: el muro sale solo, como en la web, y la pantalla
    // queda con el aviso por si se cierra.
    ref.listen(claseProvider(claseId), (antes, ahora) {
      if (esClaseDePago(ahora.error) && !esClaseDePago(antes?.error)) {
        abrirMuroDeCursos(context, ref);
      }
    });

    return Scaffold(
      appBar: GradientHeader(
        titulo: clase.value?.cursoTitulo ?? curso?.titulo ?? 'Clase',
      ),
      body: clase.when(
        loading: () => const _Cargando(),
        error: (e, _) => esClaseDePago(e)
            ? _ClaseBloqueada(cursoId: cursoId)
            : _Fallo(
                error: e,
                alReintentar: () => ref.invalidate(claseProvider(claseId)),
              ),
        data: (c) => _Contenido(clase: c, curso: curso),
      ),
    );
  }
}

class _Contenido extends ConsumerStatefulWidget {
  const _Contenido({required this.clase, required this.curso});

  final Clase clase;
  final Curso? curso;

  @override
  ConsumerState<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends ConsumerState<_Contenido> {
  late bool _vista = widget.clase.progreso.completada;

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;
    final curso = widget.curso;
    final scheme = context.scheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space8,
      ),
      children: [
        if (clase.conVideo)
          ReproductorDeClase(
            key: ValueKey(clase.id),
            clase: clase,
            alCompletar: () => setState(() => _vista = true),
          )
        else
          _SinVideo(clase: clase, curso: curso),
        const SizedBox(height: DesignTokens.space4),
        Text(
          clase.titulo,
          style: context.texts.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            // Sin color propio en el tema: en oscuro salía negro.
            color: context.scheme.onSurface,
            height: DesignTokens.lineHeightTight,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        Wrap(
          spacing: DesignTokens.space4,
          runSpacing: DesignTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (clase.profe case final profe?)
              LineaDelProfe(profe: profe, areaId: curso?.areaId, tamano: 24),
            if (clase.duracionS > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.space1),
                  Text(
                    duracionCorta(clase.duracionS),
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            if (_vista)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.check_circle,
                    size: 16,
                    fill: 1,
                    color: context.states.success.base,
                  ),
                  const SizedBox(width: DesignTokens.space1),
                  Text(
                    'Vista',
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.states.success.onTint,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.space5),
        _Acciones(clase: clase),
        const SizedBox(height: DesignTokens.space6),
        _Pestanas(clase: clase),
        if (curso != null) ...[
          const SizedBox(height: DesignTokens.space6),
          Text(
            'Temario del curso',
            style: context.texts.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          TemarioDelCurso(curso: curso, actual: clase.id, compacto: true),
        ],
        const SizedBox(height: DesignTokens.space6),
        const AvisoPlanaVirtual(),
      ],
    );
  }
}

/// Sin video todavía: la miniatura o la portada, con «llega pronto».
class _SinVideo extends StatelessWidget {
  const _SinVideo({required this.clase, required this.curso});

  final Clase clase;
  final Curso? curso;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Stack(
        alignment: Alignment.center,
        children: [
          switch (clase.miniaturaUrl) {
            final url? => AspectRatio(
              aspectRatio: 16 / 9,
              child: ImagenFirmada(url: url),
            ),
            null => PortadaDeCurso(
              titulo: clase.cursoTitulo,
              areaId: curso?.areaId,
              portadaUrl: curso?.portadaUrl,
              radio: 0,
            ),
          },
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
          Text(
            'Esta clase llega pronto',
            style: context.texts.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// «Practicar este tema» y las clases de al lado.
class _Acciones extends ConsumerStatefulWidget {
  const _Acciones({required this.clase});

  final Clase clase;

  @override
  ConsumerState<_Acciones> createState() => _AccionesState();
}

class _AccionesState extends ConsumerState<_Acciones> {
  bool _creando = false;

  /// La práctica de la clase es una sesión como cualquier otra: se abre en la
  /// pantalla de preguntas de siempre.
  Future<void> _practicar() async {
    if (_creando) return;
    setState(() => _creando = true);
    try {
      final sesion = await ref
          .read(aulaRepositoryProvider)
          .practica(widget.clase.id);
      if (mounted) context.irA(Routes.practiceSessionOf(sesion.id));
    } on Failure catch (e) {
      if (!mounted) return;
      if (esClaseDePago(e)) {
        await abrirMuroDeCursos(context, ref);
      } else {
        showErrorSnack(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  void _irA(Vecina vecina) {
    if (vecina.bloqueada) {
      abrirMuroDeCursos(context, ref);
      return;
    }
    // Se reemplaza: «atrás» vuelve al curso, no a la clase anterior.
    context.pushReplacement(Routes.claseOf(widget.clase.cursoId, vecina.id));
  }

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;
    final anterior = clase.anterior;
    final siguiente = clase.siguiente;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clase.practicaDisponible && clase.disponible) ...[
          EnamButton(
            label: 'Practicar este tema',
            icon: Symbols.target,
            loading: _creando,
            onPressed: _practicar,
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            '5 preguntas del banco sobre este tema, con la explicación de cada '
            'una.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: DesignTokens.space4),
        ],
        if (anterior != null || siguiente != null)
          Row(
            children: [
              if (anterior != null)
                Expanded(
                  child: _Vecina(
                    vecina: anterior,
                    siguiente: false,
                    alTocar: () => _irA(anterior),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: DesignTokens.space3),
              if (siguiente != null)
                Expanded(
                  child: _Vecina(
                    vecina: siguiente,
                    siguiente: true,
                    alTocar: () => _irA(siguiente),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
      ],
    );
  }
}

class _Vecina extends StatelessWidget {
  const _Vecina({
    required this.vecina,
    required this.siguiente,
    required this.alTocar,
  });

  final Vecina vecina;
  final bool siguiente;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final etiqueta = siguiente ? 'Siguiente' : 'Anterior';
    final flecha = Icon(
      siguiente ? Symbols.chevron_right : Symbols.chevron_left,
      size: 20,
    );
    return Tooltip(
      message: vecina.bloqueada ? '${vecina.titulo} (Premium)' : vecina.titulo,
      child: OutlinedButton(
        onPressed: alTocar,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
          foregroundColor: context.scheme.onSurface,
          side: BorderSide(color: context.scheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!siguiente) flecha,
            if (vecina.bloqueada) ...[
              const Icon(Symbols.lock, size: 16),
              const SizedBox(width: DesignTokens.space1),
            ],
            Flexible(
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (siguiente) flecha,
          ],
        ),
      ),
    );
  }
}

/// «Lo que aprendes» y «Referencias», como las pestañas de la web.
class _Pestanas extends StatefulWidget {
  const _Pestanas({required this.clase});

  final Clase clase;

  @override
  State<_Pestanas> createState() => _PestanasState();
}

class _PestanasState extends State<_Pestanas> {
  int _actual = 0;

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;
    return Semantics(
      label: 'Sobre la clase',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: 0, label: Text('Lo que aprendes')),
              ButtonSegment(
                value: 1,
                label: Text('Referencias (${clase.referencias.length})'),
              ),
            ],
            selected: {_actual},
            onSelectionChanged: (s) => setState(() => _actual = s.first),
          ),
          const SizedBox(height: DesignTokens.space4),
          if (_actual == 0)
            _LoQueAprendes(clase: clase)
          else
            _Referencias(referencias: clase.referencias),
        ],
      ),
    );
  }
}

class _LoQueAprendes extends StatelessWidget {
  const _LoQueAprendes({required this.clase});

  final Clase clase;

  @override
  Widget build(BuildContext context) {
    final success = context.states.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in clase.objetivos)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.check, size: 18, color: success.base),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Text(
                    o,
                    style: context.texts.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        if (clase.temas.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Temas del temario oficial',
            style: context.texts.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              for (final t in clase.temas)
                Chip(label: Text(t), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      ],
    );
  }
}

class _Referencias extends StatelessWidget {
  const _Referencias({required this.referencias});

  final List<Referencia> referencias;

  @override
  Widget build(BuildContext context) {
    if (referencias.isEmpty) {
      return Text(
        'Las referencias se publican junto con el video de la clase.',
        style: context.texts.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in referencias)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3),
            child: _Referencia(referencia: r),
          ),
      ],
    );
  }
}

class _Referencia extends StatelessWidget {
  const _Referencia({required this.referencia});

  final Referencia referencia;

  @override
  Widget build(BuildContext context) {
    final r = referencia;
    final enlace = r.enlace;
    final scheme = context.scheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.id} · ${r.tipo.etiqueta}',
              style: context.texts.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              r.cita,
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (r.detalle.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space1),
              Text(r.detalle, style: context.texts.bodySmall),
            ],
            if (enlace != null)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => launchUrl(
                  Uri.parse(enlace),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Symbols.open_in_new, size: 18),
                label: Text(
                  r.url == null && r.doi != null
                      ? 'DOI ${r.doi}'
                      : 'Abrir la fuente',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La clase es de pago. El muro ya se abrió; esto queda detrás.
class _ClaseBloqueada extends ConsumerWidget {
  const _ClaseBloqueada({required this.cursoId});

  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warning = context.states.warning;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: warning.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Icon(
                Symbols.lock,
                size: 28,
                fill: 1,
                color: warning.onTint,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Esta clase es de Premium',
              textAlign: TextAlign.center,
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Las clases gratis de cada curso siguen abiertas para ti.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.space5),
            // En Android no se vende en la app (ver `abrirMuroDeCursos`).
            if (enTiendaApple) ...[
              EnamButton(
                label: 'Ver Premium',
                onPressed: () => abrirMuroDeCursos(context, ref),
              ),
              const SizedBox(height: DesignTokens.space2),
            ],
            EnamOutlinedButton(
              label: 'Ver el temario',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(Routes.cursoOf(cursoId));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Fallo extends StatelessWidget {
  const _Fallo({required this.error, required this.alReintentar});

  final Object error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final noExiste = error is NotFoundFailure;
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: StateBanner(
        kind: BannerKind.error,
        message: noExiste
            ? 'Esta clase no existe'
            : 'No pudimos cargar la clase',
        action: noExiste
            ? null
            : TextButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
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
      children: const [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: SkeletonBox(height: double.infinity),
        ),
        SizedBox(height: DesignTokens.space4),
        SkeletonBox(height: 28, radius: DesignTokens.radiusSm),
        SizedBox(height: DesignTokens.space3),
        SkeletonBox(height: 20, radius: DesignTokens.radiusSm),
        SizedBox(height: DesignTokens.space5),
        SkeletonBox(height: 56, radius: DesignTokens.radiusXl),
      ],
    );
  }
}
