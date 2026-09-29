import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/fondo_claro.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 1.4 — verificación de correo con código.
///
/// El correo trae un código de 6 dígitos (RF-01) que se escribe aquí. Antes era
/// un enlace, y eso obligaba a abrirlo en ESTE teléfono, se rompía si el
/// certificado del dominio no estaba listo, y en spam un enlace es justo lo que
/// a la gente le enseñaron a no pulsar.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.email, super.key});

  /// Correo al que se envió el código. Si es nulo, se lee del usuario en sesión.
  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldown = 60;

  /// Dígitos del código que manda el servidor.
  static const _largoCodigo = 6;

  final _codigo = TextEditingController();

  Timer? _timer;
  int _restante = _cooldown;
  bool _enviando = false;
  bool _verificando = false;
  String? _codigoError;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar(String email) async {
    if (_verificando) return;
    if (_codigo.text.length != _largoCodigo) {
      setState(() => _codigoError = 'El código tiene $_largoCodigo dígitos.');
      return;
    }

    setState(() {
      _verificando = true;
      _codigoError = null;
    });
    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .verificarConCodigo(email: email, codigo: _codigo.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cuenta quedó verificada.')),
      );

      // Con sesión: entra directo. Acaba de demostrar que controla el correo y
      // su contraseña la escribió hace treinta segundos; mandarlo al login a
      // repetirla es pedirle que demuestre dos veces lo mismo.
      //
      // No se navega a mano al inicio: se le dice al controlador quién entró y
      // el router decide. Desde aquí el destino real es completar el perfil
      // —universidad, condición y fecha del examen (RF-04)—, y esa regla vive
      // en la guarda, no repartida por las pantallas.
      if (usuario != null) {
        ref.read(authControllerProvider.notifier).setUser(usuario);
        return;
      }

      // Sin sesión, la cuenta ya estaba verificada: el servidor no comprobó el
      // código, así que quién es se decide en el login.
      context.go(Routes.login);
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _codigoError = e.message;
        _codigo.clear();
      });
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _restante = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restante <= 1) {
        t.cancel();
        if (mounted) setState(() => _restante = 0);
      } else if (mounted) {
        setState(() => _restante--);
      }
    });
  }

  Future<void> _reenviar() async {
    final email = widget.email ?? ref.read(currentUserProvider)?.email;
    if (email == null || _enviando) return;

    setState(() => _enviando = true);
    try {
      await ref.read(authRepositoryProvider).reenviarVerificacion(email);
      if (!mounted) return;
      setState(() {
        _codigo.clear();
        _codigoError = null;
      });
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un código nuevo.')),
      );
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String get _cooldownLabel {
    final m = _restante ~/ 60;
    final s = (_restante % 60).toString().padLeft(2, '0');
    return 'Reenviar en $m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? ref.watch(currentUserProvider)?.email ?? '';
    final puedeReenviar = _restante == 0 && !_enviando;

    // Sin tarjeta flotante, a diferencia del resto del bloque: aquí no hay
    // formulario, solo un mensaje y el código, centrados sobre el fondo claro.
    return Scaffold(
      body: FondoClaro(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space6,
                vertical: DesignTokens.space6,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _SobreFlotando()),
                    const SizedBox(height: DesignTokens.space5),
                    const Text(
                      'Revisa tu correo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: DesignTokens.textSecondaryLight,
                        ),
                        children: [
                          const TextSpan(text: 'Enviamos un código a\n'),
                          TextSpan(
                            text: email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.textPrimaryLight,
                            ),
                          ),
                          const TextSpan(
                            text: '\nEscríbelo aquí para continuar.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space5),
                    _CampoCodigo(
                      controller: _codigo,
                      error: _codigoError,
                      largo: _largoCodigo,
                      enabled: !_verificando,
                      onChanged: () => setState(() => _codigoError = null),
                      onSubmit: () => _verificar(email),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    // El principal, sólido; el reenvío, con borde (el mismo
                    // reparto que la web).
                    EnamButton(
                      label: 'Verificar cuenta',
                      loading: _verificando,
                      onPressed: () => _verificar(email),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    EnamOutlinedButton(
                      label: puedeReenviar ? 'Reenviar código' : _cooldownLabel,
                      onPressed: puedeReenviar ? _reenviar : null,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    TextButton(
                      onPressed: () => context.go(Routes.register),
                      child: const Text(
                        'Cambiar el correo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    // Salida de emergencia: sin esto, quien no recibe el
                    // código queda encerrado en esta pantalla.
                    TextButton(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: DesignTokens.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El sobre en su caja, subiendo y bajando en bucle.
class _SobreFlotando extends StatefulWidget {
  const _SobreFlotando();

  @override
  State<_SobreFlotando> createState() => _SobreFlotandoState();
}

class _SobreFlotandoState extends State<_SobreFlotando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caja = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: DesignTokens.brandSubtle,
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Icon(
        Symbols.mark_email_unread,
        size: 52,
        fill: 1,
        color: DesignTokens.actionLight,
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final vaiven = (t < 0.5 ? t : 1 - t) * 2;
        return Transform.translate(
          offset: Offset(0, -9 * Curves.easeInOut.transform(vaiven)),
          child: child,
        );
      },
      child: caja,
    );
  }
}

/// Campo de los 6 dígitos: el campo claro de la app, en grande.
class _CampoCodigo extends StatelessWidget {
  const _CampoCodigo({
    required this.controller,
    required this.largo,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController controller;
  final int largo;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          // Teclado numérico y autocompletado del código: iOS y Android lo
          // ofrecen encima del teclado y no hay que teclearlo.
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          textInputAction: TextInputAction.done,
          maxLength: largo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
            color: DesignTokens.textPrimaryLight,
          ),
          cursorColor: DesignTokens.actionLight,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
              // Texto grande: 3,5:1 le basta y no se confunde con un código
              // ya escrito.
              color: DesignTokens.borderLight,
            ),
            filled: true,
            fillColor: DesignTokens.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              vertical: DesignTokens.space4,
            ),
            enabledBorder: borde(DesignTokens.borderLight),
            focusedBorder: borde(DesignTokens.actionLight, 2),
            disabledBorder: borde(DesignTokens.borderSubtleLight),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: DesignTokens.space2),
          StateBanner(kind: BannerKind.error, message: error!),
        ],
      ],
    );
  }
}
