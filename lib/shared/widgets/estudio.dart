import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';
import 'enam_button.dart';
import 'state_banner.dart';

/// Componentes de composición compartidos por inicio, temario y resultados.
///
/// Son los del sistema visual del rediseño (plan §3): cada uno existe una vez
/// y todas las pantallas lo toman de aquí. Sus equivalentes web tienen el mismo
/// nombre en `src/components/ui/` y los mismos tokens (diseno/TOKENS.md). La
/// galería interna (`/dev/componentes`) los muestra en todos sus estados.

// ==================== ETIQUETA DE ESTADO ====================

/// Píldora corta con icono y texto. El color nunca va solo: el estado se lee
/// también por el icono y la palabra.
class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({
    required this.texto,
    this.tipo = BannerKind.info,
    this.icono,
    super.key,
  });

  final String texto;
  final BannerKind tipo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final c = _colores(context, tipo);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2 + 2,
        vertical: DesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono ?? _iconoDe(tipo), size: 16, fill: 1, color: c.onTint),
          const SizedBox(width: DesignTokens.space1),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: c.onTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

StateColor _colores(BuildContext context, BannerKind tipo) => switch (tipo) {
  BannerKind.info => context.states.info,
  BannerKind.success => context.states.success,
  BannerKind.warning => context.states.warning,
  BannerKind.error => context.states.error,
};

IconData _iconoDe(BannerKind tipo) => switch (tipo) {
  BannerKind.info => Symbols.info,
  BannerKind.success => Symbols.check_circle,
  BannerKind.warning => Symbols.warning,
  BannerKind.error => Symbols.error,
};

// ==================== TÍTULO DE SECCIÓN ====================

/// El rótulo que abre un grupo de bloques, con un enlace opcional a la derecha.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {this.enlace, this.onEnlace, super.key});

  final String texto;
  final String? enlace;
  final VoidCallback? onEnlace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                texto,
                style: context.texts.titleMedium?.copyWith(
                  fontSize: DesignTokens.fontSizeMd,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (enlace != null)
            TextButton(
              onPressed: onEnlace,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                ),
                foregroundColor: context.states.info.onTint,
                textStyle: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(enlace!),
            ),
        ],
      ),
    );
  }
}

// ==================== BLOQUE DE SIGUIENTE ACCIÓN ====================

/// El bloque dominante del inicio: qué hacer ahora y un botón para hacerlo.
///
/// Es el único elemento de la pantalla con el botón principal dentro, y por
/// eso gana la jerarquía sin necesitar degradado ni tamaño desmedido. Lo que
/// explica la sugerencia va en [criterio]: una recomendación sin motivo parece
/// arbitraria, y un motivo inventado es peor que ninguno.
class BloqueSiguienteAccion extends StatelessWidget {
  const BloqueSiguienteAccion({
    required this.antetitulo,
    required this.titulo,
    required this.accion,
    required this.onAccion,
    this.icono = Symbols.play_circle,
    this.detalle,
    this.criterio,
    this.progreso,
    this.secundaria,
    this.onSecundaria,
    this.acento,
    super.key,
  });

  /// Rótulo corto encima del título: «Tu siguiente paso», «Sin conexión».
  final String antetitulo;
  final String titulo;
  final String? detalle;

  /// Por qué se sugiere esto. Una línea, con datos reales.
  final String? criterio;

  /// De 0 a 1 si hay un avance que mostrar (una sesión a medias).
  final double? progreso;

  final IconData icono;
  final String accion;
  final VoidCallback? onAccion;
  final String? secundaria;
  final VoidCallback? onSecundaria;

  /// Color del acento lateral. Por defecto, el de acción.
  final Color? acento;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = acento ?? scheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102338).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El acento: una franja, no un fondo de color. Marca que este es el
            // bloque que importa sin teñir el texto que hay que leer.
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space5,
                  DesignTokens.space5,
                  DesignTokens.space5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(icono, size: 20, fill: 1, color: color),
                        const SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: Text(
                            antetitulo,
                            style: context.texts.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Semantics(
                      header: true,
                      child: Text(
                        titulo,
                        style: context.texts.headlineMedium?.copyWith(
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (detalle != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        detalle!,
                        style: context.texts.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (progreso != null) ...[
                      const SizedBox(height: DesignTokens.space3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progreso!.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                    if (criterio != null) ...[
                      const SizedBox(height: DesignTokens.space3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Symbols.lightbulb,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.space1 + 2),
                          Expanded(
                            child: Text(
                              criterio!,
                              style: context.texts.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space4),
                    EnamButton(label: accion, onPressed: onAccion),
                    if (secundaria != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      TextButton(
                        onPressed: onSecundaria,
                        child: Text(secundaria!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== RESUMEN MÉTRICO ====================

/// Una cifra con su rótulo y su contexto.
typedef Metrica = ({String valor, String etiqueta, String? detalle});

/// Hasta tres cifras en un solo bloque, separadas por líneas finas.
///
/// Un bloque y no tres tarjetas: tres tarjetas iguales pesan lo mismo que la
/// acción principal y convierten el resumen en protagonista.
class ResumenMetrico extends StatelessWidget {
  const ResumenMetrico({required this.metricas, this.onTap, super.key});

  final List<Metrica> metricas;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    assert(metricas.length <= 3, 'Tres cifras como máximo (plan §6)');
    final scheme = context.scheme;

    final celdas = [
      for (final m in metricas)
        Expanded(
          child: Semantics(
            label: [m.valor, m.etiqueta, ?m.detalle].join(', '),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.headlineMedium?.copyWith(
                      fontSize: 22,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.etiqueta,
                    maxLines: 2,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (m.detalle != null)
                    Text(
                      m.detalle!,
                      maxLines: 2,
                      style: context.texts.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ),
    ];

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < celdas.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(width: 1, color: scheme.outlineVariant),
                  celdas[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== FILA DE ÁREA ====================

/// Una fila escaneable del temario: color del área, nombre, peso y avance.
///
/// Sin respuestas no hay dominio que mostrar, y un 0 % se leería como un mal
/// resultado. Con [acierto] nulo la fila dice «Aún sin práctica» y la barra no
/// se pinta.
class FilaDeArea extends StatelessWidget {
  const FilaDeArea({
    required this.nombre,
    required this.color,
    required this.onTap,
    this.peso,
    this.acierto,
    super.key,
  });

  final String nombre;
  final Color color;

  /// Preguntas que aporta al examen.
  final int? peso;

  /// De 0 a 1, o nulo si todavía no respondió nada.
  final double? acierto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final pct = acierto;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: DesignTokens.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (peso != null) '$peso preguntas en el ENAM',
                        pct == null
                            ? 'Aún sin práctica'
                            : '${(pct * 100).round()} % de acierto',
                      ].join(' · '),
                      style: context.texts.bodyMedium,
                    ),
                    if (pct != null) ...[
                      const SizedBox(height: DesignTokens.space2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Icon(
                Symbols.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ESTADOS VACÍO Y DE ERROR ====================

/// Lo que se muestra cuando no hay nada, o cuando algo falló.
///
/// Siempre dice qué pasó y qué se puede hacer. Un error sin salida deja a la
/// persona mirando la pantalla; un vacío sin acción parece un error.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    required this.titulo,
    required this.mensaje,
    this.icono = Symbols.inbox,
    this.accion,
    this.onAccion,
    this.esError = false,
    super.key,
  });

  /// El estado de error con su «Reintentar». El texto dice qué no se pudo
  /// hacer, sin culpar ni dar detalles técnicos.
  const EstadoVacio.error({
    required this.mensaje,
    required VoidCallback onReintentar,
    this.titulo = 'No pudimos cargar esto',
    super.key,
  }) : icono = Symbols.cloud_off,
       accion = 'Reintentar',
       onAccion = onReintentar,
       esError = true;

  final String titulo;
  final String mensaje;
  final IconData icono;
  final String? accion;
  final VoidCallback? onAccion;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = esError
        ? context.states.error.onTint
        : scheme.onSurfaceVariant;

    return Semantics(
      liveRegion: esError,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: esError
                    ? context.states.error.tint
                    : scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 28, color: color),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium,
            ),
            if (accion != null) ...[
              const SizedBox(height: DesignTokens.space4),
              OutlinedButton(onPressed: onAccion, child: Text(accion!)),
            ],
          ],
        ),
      ),
    );
  }
}
