import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../shared/widgets/brand_gradient.dart';
import '../../../shared/widgets/brand_mark.dart';

/// Pantalla 1.1 — carga inicial.
///
/// El router decide a dónde ir cuando el arranque se resuelve; esta pantalla
/// no navega por su cuenta ni tiene un tiempo mínimo. Si la sesión y las
/// preferencias están listas en 200 ms, se ve 200 ms.
///
/// Lo que sí hace es no dejar a nadie mirando un logo sin saber qué pasa:
///
/// - Si tarda más de un instante, aparece una indicación discreta de carga,
///   sin porcentajes: no hay manera honesta de saber cuánto falta.
/// - Si pasan [esperaAntesDeAvisar] sin resolverse, o si la comprobación de la
///   sesión falló, dice qué ocurre y ofrece reintentar. El botón no deja lanzar
///   un segundo intento mientras el primero sigue en curso.
///
/// Antes la marca latía, una línea de ECG se dibujaba y una barra cruzaba sin
/// parar. Era movimiento perpetuo en la primera pantalla de la app, y con la
/// espera mínima retirada tampoco daría tiempo a verlo.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Cuánto se espera antes de decir que algo va lento (plan §5).
  static const esperaAntesDeAvisar = Duration(seconds: 8);

  /// Cuánto se espera antes de enseñar el indicador de carga. Menos que esto
  /// se percibe como instantáneo, y un indicador que aparece y desaparece en
  /// un parpadeo distrae más de lo que informa.
  static const esperaAntesDeIndicar = Duration(milliseconds: 400);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _indicar;
  Timer? _avisar;
  bool _mostrarIndicador = false;
  bool _tardando = false;

  @override
  void initState() {
    super.initState();
    _programarTemporizadores();
  }

  void _programarTemporizadores() {
    _indicar?.cancel();
    _avisar?.cancel();
    _indicar = Timer(SplashScreen.esperaAntesDeIndicar, () {
      if (mounted) setState(() => _mostrarIndicador = true);
    });
    _avisar = Timer(SplashScreen.esperaAntesDeAvisar, () {
      if (mounted) setState(() => _tardando = true);
    });
  }

  @override
  void dispose() {
    _indicar?.cancel();
    _avisar?.cancel();
    super.dispose();
  }

  /// Vuelve a pedir la sesión y las preferencias.
  ///
  /// Solo se relanza lo que falló o sigue sin resolver: invalidar una
  /// preferencia ya leída no aporta nada y reiniciaría su lectura.
  void _reintentar() {
    final auth = ref.read(authControllerProvider);
    final startup = ref.read(startupProvider);
    if (auth.isLoading && startup.isLoading) return;

    if (!auth.hasValue || auth.hasError) ref.invalidate(authControllerProvider);
    if (!startup.hasValue || startup.hasError) ref.invalidate(startupProvider);

    setState(() {
      _tardando = false;
      _mostrarIndicador = false;
    });
    _programarTemporizadores();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final startup = ref.watch(startupProvider);

    // Riverpod reintenta solo un provider que falla, y mientras lo hace el
    // estado sigue llevando el error. Basta con que lo lleve: a quien mira la
    // pantalla le da igual si hay un reintento automático en marcha.
    final fallo = auth.hasError || startup.hasError;
    final reintentando =
        (auth.isLoading && !auth.hasError) ||
        (startup.isLoading && !startup.hasError);

    final aviso = fallo
        ? (
            titulo: 'No pudimos conectar',
            mensaje:
                'Revisa tu conexión a internet. Tus descargas y tu avance '
                'siguen guardados en el teléfono.',
          )
        : _tardando
        ? (
            titulo: 'Está tardando más de lo normal',
            mensaje: 'Puede ser la conexión. Seguimos intentándolo.',
          )
        : null;

    return Scaffold(
      body: BrandGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space6,
            ),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _Marca(),
                const Spacer(flex: 2),
                SizedBox(
                  // Alto reservado: el aviso aparece sin empujar la marca.
                  height: 180,
                  child: AnimatedSwitcher(
                    duration: Motion.duration(context, Motion.normal),
                    child: aviso != null
                        ? _Aviso(
                            key: ValueKey(aviso.titulo),
                            titulo: aviso.titulo,
                            mensaje: aviso.mensaje,
                            // Durante un intento el botón se desactiva: dos
                            // intentos a la vez solo compiten por la red.
                            onReintentar: reintentando && !fallo
                                ? null
                                : _reintentar,
                          )
                        : _mostrarIndicador
                        ? const _Cargando(key: ValueKey('cargando'))
                        : const SizedBox.shrink(),
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

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ENAM Prep. Tu preparación para el ENAM',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(child: BrandMark(size: 56)),
          ),
          const SizedBox(height: DesignTokens.space5),
          const Text(
            'ENAM Prep',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Tu preparación para el ENAM',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    // Con el movimiento reducido la rueda se sustituye por el texto solo: el
    // estado se sigue leyendo, que es lo que importa.
    final reducido = Motion.reduced(context);
    return Semantics(
      liveRegion: true,
      label: 'Cargando',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (!reducido)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Cargando…',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.titulo,
    required this.mensaje,
    required this.onReintentar,
    super.key,
  });

  final String titulo;
  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Symbols.wifi_off,
            size: 24,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          // Blanco sobre la marca: es el único botón de la pantalla y tiene
          // que verse sobre el degradado.
          FilledButton(
            onPressed: onReintentar,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DesignTokens.onActionDark,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
              disabledForegroundColor: DesignTokens.onActionDark,
              minimumSize: const Size(160, DesignTokens.minTouchTarget),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
