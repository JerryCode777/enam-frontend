import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 1.6 — recuperación de contraseña.
///
/// **Nunca revela si el correo existe** (RNF-04): el mensaje de confirmación es
/// el mismo haya cuenta o no. Enumerar correos registrados es una fuga de datos.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const _cooldown = 60;

  final _email = TextEditingController();
  String? _emailError;
  bool _loading = false;
  bool _enviado = false;

  Timer? _timer;
  int _restante = 0;

  @override
  void dispose() {
    _email.dispose();
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

  Future<void> _submit() async {
    final email = _email.text.trim();

    setState(() {
      _emailError = switch (email) {
        '' => 'Ingresa tu correo.',
        _ when !email.contains('@') || !email.contains('.') =>
          'Ese correo no parece válido.',
        _ => null,
      };
    });
    if (_emailError != null || _loading) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!mounted) return;
      setState(() => _enviado = true);
      _startCooldown();
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space6,
            DesignTokens.space2,
            DesignTokens.space6,
            DesignTokens.space6,
          ),
          child: _enviado ? _sent(context) : _form(context),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recupera tu acceso',
          style: context.texts.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Te enviaremos un enlace para crear una contraseña nueva.',
          style: context.texts.bodyMedium,
        ),
        const SizedBox(height: DesignTokens.space5),
        EnamTextField(
          label: 'Correo',
          controller: _email,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          autofocus: true,
          enabled: !_loading,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: DesignTokens.space5),
        EnamButton(
          label: 'Enviar enlace',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: DesignTokens.space5),
        const StateBanner(
          message:
              'Si el correo existe, el enlace llega en 1-2 minutos. Revisa '
              'también el spam.',
        ),
      ],
    );
  }

  Widget _sent(BuildContext context) {
    final states = context.states;
    final puedeReenviar = _restante == 0 && !_loading;

    return Column(
      children: [
        const SizedBox(height: DesignTokens.space10),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: states.success.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          child: Icon(
            Symbols.mark_email_read,
            size: 40,
            color: states.success.onTint,
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
        Text(
          'Enlace enviado',
          style: context.texts.headlineMedium?.copyWith(
            fontSize: DesignTokens.fontSize2xl - 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        Text(
          // El mismo texto exista o no la cuenta: no confirmamos correos.
          'Si ${_email.text.trim()} tiene una cuenta, el enlace ya está en '
          'camino. Ábrelo desde este teléfono.',
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium?.copyWith(height: 1.55),
        ),
        const SizedBox(height: DesignTokens.space6),
        EnamOutlinedButton(
          label: puedeReenviar
              ? 'Reenviar enlace'
              : 'Reenviar en 0:${(_restante % 60).toString().padLeft(2, '0')}',
          height: 48,
          onPressed: puedeReenviar ? _submit : null,
        ),
      ],
    );
  }
}
