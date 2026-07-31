import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';

/// Cabecera con degradado y esquinas inferiores redondeadas.
///
/// Es el patrón de cabecera del diseño: degradado diagonal, un círculo tenue
/// arriba a la derecha, y el título en blanco sobre él.
class GradientHeader extends StatelessWidget implements PreferredSizeWidget {
  const GradientHeader({
    required this.titulo,
    this.subtitulo,
    this.acciones = const [],
    this.mostrarVolver = true,
    this.bottom,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;
  final bool mostrarVolver;

  /// Contenido extra debajo del título, dentro del degradado.
  final Widget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(subtitulo == null ? 96 : 124);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // `maybeOf` y no `context.canPop()`: un widget compartido no debe exigir un
    // GoRouter en contexto. Sin router cae al Navigator, que es lo correcto en
    // tests y en cualquier uso fuera del árbol de rutas.
    final router = GoRouter.maybeOf(context);
    final puedeVolver =
        mostrarVolver &&
        (router?.canPop() ?? Navigator.of(context).canPop());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? DesignTokens.headerGradientLight
              : DesignTokens.headerGradientDark,
          stops: DesignTokens.headerGradientStops,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl),
        ),
      ),
      child: Stack(
        children: [
          // Círculo decorativo, recortado por las esquinas de la cabecera.
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                DesignTokens.space2,
                DesignTokens.space4,
                DesignTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (puedeVolver) ...[
                        _HeaderIconButton(
                          icon: Symbols.arrow_back,
                          tooltip: 'Atrás',
                          onPressed: () => router != null
                              ? router.pop()
                              : Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: DesignTokens.space3),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Una línea: los nombres largos del temario
                            // ("Emergencias y Cuidados Críticos Adultos")
                            // pasaban a dos y desbordaban la cabecera, que
                            // tiene alto fijo.
                            Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitulo != null)
                              Text(
                                subtitulo!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ...acciones,
                    ],
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: DesignTokens.space3),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de icono para usar sobre el degradado: fondo translúcido y borde tenue.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
        child: Container(
          // 44 de caja visible dentro de un área táctil de 48.
          width: DesignTokens.minTouchTarget,
          height: DesignTokens.minTouchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
