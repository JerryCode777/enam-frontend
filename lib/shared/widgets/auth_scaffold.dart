import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/state_colors.dart';
import 'fondo_claro.dart';

/// Andamiaje común de las pantallas de acceso (1.3 a 1.8).
///
/// Todas comparten la misma composición: el fondo claro de la app con dos
/// halos de marca, la cabecera en tinta y una tarjeta con el formulario. Era
/// un degradado azul marino a pantalla completa con la cabecera en blanco; el
/// producto pidió la primera impresión en el tema claro, igual que la web.
/// Está en un widget y no copiado seis veces porque el bloque entero ya cambió
/// de lenguaje visual una vez, y volverá a cambiar.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.titulo,
    required this.tarjeta,
    this.subtitulo,
    this.iconoCabecera,
    this.mostrarVolver = false,
    this.alVolver,
    this.tamanoTitulo = 28,
    super.key,
  });

  final String titulo;

  /// Contenido de la tarjeta flotante. Se separa con 16 px entre elementos.
  final List<Widget> tarjeta;

  final String? subtitulo;

  /// Icono en la caja de vidrio junto al título. Con [mostrarVolver] se usa
  /// una flecha atrás en su lugar.
  final IconData? iconoCabecera;

  final bool mostrarVolver;
  final VoidCallback? alVolver;

  /// El diseño usa 28 px en registro y login, y 26 px donde el título es más
  /// largo y necesita dos líneas.
  final double tamanoTitulo;

  @override
  Widget build(BuildContext context) {
    final hayCaja = mostrarVolver || iconoCabecera != null;

    return Scaffold(
      body: FondoClaro(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space5,
                    DesignTokens.space4,
                    DesignTokens.space5,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hayCaja)
                        Row(
                          children: [
                            _CajaVidrio(
                              icono: mostrarVolver
                                  ? Symbols.arrow_back
                                  : iconoCabecera!,
                              onTap: mostrarVolver
                                  ? (alVolver ?? () => _volver(context))
                                  : null,
                            ),
                            const SizedBox(width: DesignTokens.space3 + 2),
                            Expanded(
                              child: Text(titulo, style: _estiloTitulo),
                            ),
                          ],
                        )
                      else
                        Text(titulo, style: _estiloTitulo),
                      if (subtitulo != null) ...[
                        const SizedBox(height: DesignTokens.space1 + 2),
                        Text(
                          subtitulo!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: DesignTokens.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    0,
                    DesignTokens.space4,
                    DesignTokens.space6,
                  ),
                  child: AuthCard(children: tarjeta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _estiloTitulo => TextStyle(
    fontSize: tamanoTitulo,
    fontWeight: FontWeight.w800,
    height: 1.25,
    color: DesignTokens.textPrimaryLight,
  );

  /// Vuelve atrás, o al login si no hay a dónde volver.
  ///
  /// El caso sin historial es real: la pantalla 1.8 se abre desde un enlace del
  /// correo, así que la pila de navegación está vacía.
  static void _volver(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }
}

/// La tarjeta blanca flotante del diseño, con su entrada deslizando.
class AuthCard extends StatefulWidget {
  const AuthCard({required this.children, super.key});

  final List<Widget> children;

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tarjeta = Container(
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: context.scheme.outlineVariant),
        // Sombra suave: sobre el fondo claro, la de antes (pensada para el
        // azul marino) manchaba.
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102338).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.children.length; i++) ...[
            if (i > 0) const SizedBox(height: DesignTokens.space4),
            widget.children[i],
          ],
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Motion.enter.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
        );
      },
      child: tarjeta,
    );
  }
}

/// Caja con un icono junto al título: superficie con borde, en tinta.
class _CajaVidrio extends StatelessWidget {
  const _CajaVidrio({required this.icono, this.onTap});

  final IconData icono;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final caja = Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceLight,
        border: Border.all(color: DesignTokens.borderSubtleLight),
        borderRadius: BorderRadius.circular(16),
      ),
      // La flecha de volver, en tinta; el icono de la pantalla, en el color
      // de acción.
      child: Icon(
        icono,
        size: 22,
        color: icono == Symbols.arrow_back
            ? DesignTokens.textPrimaryLight
            : DesignTokens.actionLight,
      ),
    );

    if (onTap == null) return caja;

    return Semantics(
      label: 'Volver',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: caja,
      ),
    );
  }
}

/// Aviso en tinte de marca dentro de la tarjeta, como el de 1.6 y 1.7.
class AuthTintNote extends StatelessWidget {
  const AuthTintNote({
    required this.icono,
    required this.texto,
    this.iconoRelleno = false,
    super.key,
  });

  final IconData icono;
  final Widget texto;
  final bool iconoRelleno;

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;

    return Container(
      decoration: BoxDecoration(
        color: info.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4 - 2,
        vertical: DesignTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 20,
            fill: iconoRelleno ? 1 : 0,
            color: info.onTint,
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(child: texto),
        ],
      ),
    );
  }
}
