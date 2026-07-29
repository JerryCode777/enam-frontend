import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 1.4 — espera de verificación de correo.
///
/// La verificación es **por enlace** (RF-01), no por código: el enlace abre la
/// app por deep link y de ahí se va a completar el perfil. Esta pantalla solo
/// espera y permite reenviar tras 60 s.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.email, super.key});

  /// Correo al que se envió el enlace. Si es nulo, se lee del usuario en sesión.
  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldown = 60;

  Timer? _timer;
  int _restante = _cooldown;
  bool _enviando = false;
  bool _enlaceVencido = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      // Reutiliza el flujo de recuperación: el backend reenvía el enlace.
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!mounted) return;
      setState(() => _enlaceVencido = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un enlace nuevo.')),
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
    final states = context.states;
    final email = widget.email ?? ref.watch(currentUserProvider)?.email ?? '';
    final puedeReenviar = _restante == 0 && !_enviando;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space8,
            vertical: DesignTokens.space6,
          ),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.space16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: states.info.tint,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                ),
                child: Icon(
                  Symbols.mark_email_unread,
                  size: 40,
                  color: states.info.onTint,
                ),
              ),
              const SizedBox(height: DesignTokens.space5),
              Text(
                'Revisa tu correo',
                style: context.texts.headlineMedium?.copyWith(
                  fontSize: DesignTokens.fontSize2xl - 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text.rich(
                TextSpan(
                  style: context.texts.bodyMedium?.copyWith(height: 1.55),
                  children: [
                    const TextSpan(text: 'Te enviamos un enlace de verificación a\n'),
                    TextSpan(
                      text: email,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.scheme.onSurface,
                      ),
                    ),
                    const TextSpan(
                      text: '\nÁbrelo desde este teléfono para continuar.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              if (_enlaceVencido) ...[
                const SizedBox(height: DesignTokens.space5),
                const StateBanner(
                  kind: BannerKind.warning,
                  message: 'El enlace venció. Pide uno nuevo para continuar.',
                ),
              ],
              const SizedBox(height: DesignTokens.space5),
              EnamOutlinedButton(
                label: puedeReenviar ? 'Reenviar enlace' : _cooldownLabel,
                height: 48,
                onPressed: puedeReenviar ? _reenviar : null,
              ),
              const SizedBox(height: DesignTokens.space2),
              TextButton(
                onPressed: () => context.go(Routes.register),
                child: const Text('Cambiar el correo'),
              ),
              const SizedBox(height: DesignTokens.space6),
              // Salida de emergencia: sin esto, un usuario con el enlace perdido
              // queda encerrado en esta pantalla.
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(color: context.scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
