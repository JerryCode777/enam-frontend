import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/auth_scaffold.dart';
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
    return AuthScaffold(
      titulo: _enviado ? 'Enlace enviado' : 'Recupera tu acceso',
      subtitulo: _enviado
          ? null
          : 'Te enviaremos un enlace para crear una nueva.',
      mostrarVolver: true,
      tamanoTitulo: 26,
      // El diseño resuelve el envío dentro de la misma tarjeta, no en otra
      // pantalla: así el usuario no pierde de vista a qué correo lo mandó.
      tarjeta: _enviado ? _enviadoTarjeta(context) : _formulario(context),
    );
  }

  List<Widget> _formulario(BuildContext context) => [
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
    EnamButton(label: 'Enviar enlace', loading: _loading, onPressed: _submit),
    AuthTintNote(
      icono: Symbols.info,
      texto: Text(
        'Si el correo existe, llega en 1-2 minutos. Revisa también el spam.',
        style: context.texts.bodySmall?.copyWith(
          height: 1.5,
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    ),
  ];

  List<Widget> _enviadoTarjeta(BuildContext context) {
    final states = context.states;
    final puedeReenviar = _restante == 0 && !_loading;

    return [
      Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: states.success.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
          ),
          child: Icon(
            Symbols.mark_email_read,
            size: 36,
            fill: 1,
            color: states.success.onTint,
          ),
        ),
      ),
      Text(
        // El mismo texto exista o no la cuenta: no confirmamos correos.
        'Si ${_email.text.trim()} tiene una cuenta, el enlace ya está en '
        'camino. Ábrelo desde este teléfono.',
        textAlign: TextAlign.center,
        style: context.texts.bodyMedium?.copyWith(height: 1.55),
      ),
      EnamOutlinedButton(
        label: puedeReenviar
            ? 'Reenviar enlace'
            : 'Reenviar en 0:${(_restante % 60).toString().padLeft(2, '0')}',
        height: 48,
        onPressed: puedeReenviar ? _submit : null,
      ),
    ];
  }
}
