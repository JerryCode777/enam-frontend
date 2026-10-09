import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/navegar.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/aula_models.dart';
import '../../domain/segundos_vistos.dart';
import '../muro_de_cursos.dart';
import 'presentacion.dart';

/// Los módulos y sus clases, como `TemarioDelCurso.tsx`.
///
/// - Una clase que viene no se abre.
/// - Una con candado abre el muro **sin pedir la clase**: ya se sabe la
///   respuesta.
/// - Las demás abren la clase. Desde la clase ([actual] no nulo) se reemplaza
///   la pantalla, para que «atrás» vuelva al curso y no a la clase anterior.
class TemarioDelCurso extends StatelessWidget {
  const TemarioDelCurso({
    required this.curso,
    this.actual,
    this.compacto = false,
    super.key,
  });

  final Curso curso;

  /// La clase que se está viendo, si se está en una.
  final String? actual;

  /// Sin la descripción de cada módulo.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (curso.modulos.isEmpty) {
      return Text(
        'El temario de este curso se publica junto con sus primeras clases.',
        style: context.texts.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, m) in curso.modulos.indexed) ...[
          if (i > 0) const SizedBox(height: DesignTokens.space4),
          _Modulo(
            numero: i + 1,
            modulo: m,
            curso: curso,
            actual: actual,
            compacto: compacto,
          ),
        ],
      ],
    );
  }
}

class _Modulo extends StatelessWidget {
  const _Modulo({
    required this.numero,
    required this.modulo,
    required this.curso,
    required this.actual,
    required this.compacto,
  });

  final int numero;
  final Modulo modulo;
  final Curso curso;
  final String? actual;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final disponibles = modulo.disponibles.toList();
    final duracion = disponibles.fold(0, (s, c) => s + c.duracionS);
    final scheme = context.scheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space3,
              DesignTokens.space4,
              DesignTokens.space2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Módulo $numero · ${modulo.titulo}',
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    // Sin color propio en el tema: en oscuro salía negro.
                    color: context.scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                if (disponibles.isEmpty)
                  const EtiquetaProximamente()
                else
                  Text(
                    '${clasesEnTexto(disponibles.length)} · '
                    '${duracionCorta(duracion)}',
                    style: context.texts.bodySmall,
                  ),
                if (!compacto && modulo.descripcion.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space1),
                  Text(modulo.descripcion, style: context.texts.bodySmall),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          for (final c in modulo.clases)
            _FilaDeClase(
              clase: c,
              curso: curso,
              actual: c.id == actual,
              desdeUnaClase: actual != null,
            ),
        ],
      ),
    );
  }
}

class _FilaDeClase extends ConsumerWidget {
  const _FilaDeClase({
    required this.clase,
    required this.curso,
    required this.actual,
    required this.desdeUnaClase,
  });

  final ClaseResumen clase;
  final Curso curso;
  final bool actual;
  final bool desdeUnaClase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.scheme;
    final states = context.states;
    final completada = clase.progreso.completada;

    final (icono, color) = switch (clase) {
      _ when completada => (Symbols.check_circle, states.success.base),
      _ when !clase.disponible => (Symbols.schedule, scheme.onSurfaceVariant),
      _ when clase.bloqueada => (Symbols.lock, states.warning.onTint),
      _ => (Symbols.play_circle, scheme.primary),
    };

    final avance = clase.avance;
    final fila = Container(
      color: actual ? states.info.tint : null,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, fill: 1, color: color),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clase.titulo,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: actual ? FontWeight.w800 : FontWeight.w600,
                    color: clase.disponible ? null : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Wrap(
                  spacing: DesignTokens.space2,
                  runSpacing: DesignTokens.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!clase.disponible)
                      const EtiquetaProximamente()
                    else
                      Text(
                        duracionCorta(clase.duracionS),
                        style: context.texts.bodySmall,
                      ),
                    if (!curso.premium && clase.gratis && clase.disponible)
                      const EtiquetaGratis(),
                    if (completada)
                      Text(
                        'Vista',
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: states.success.onTint,
                        ),
                      ),
                  ],
                ),
                if (avance != null) ...[
                  const SizedBox(height: DesignTokens.space2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: BarraDeAvance(
                      valor: avance,
                      etiqueta: 'Lo que llevas de la clase',
                      alto: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final etiqueta = [
      clase.titulo,
      if (clase.bloqueada && clase.disponible) 'Premium',
      if (!clase.disponible) 'próximamente',
    ].join(', ');

    if (!clase.disponible || actual) {
      return Semantics(
        label: etiqueta,
        selected: actual,
        child: ExcludeSemantics(child: fila),
      );
    }

    return Semantics(
      button: true,
      label: etiqueta,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () {
            if (clase.bloqueada) {
              abrirMuroDeCursos(context, ref);
              return;
            }
            final ruta = Routes.claseOf(curso.id, clase.id);
            if (desdeUnaClase) {
              context.pushReplacement(ruta);
            } else {
              context.irA(ruta);
            }
          },
          child: fila,
        ),
      ),
    );
  }
}
