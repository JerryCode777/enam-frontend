import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/auth_footer.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 1.3 — registro.
///
/// El consentimiento de términos es obligatorio y explícito (RNF-06, Ley 29733):
/// la casilla arranca desmarcada y sin ella el botón queda deshabilitado.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _nombreError;
  String? _emailError;
  String? _passwordError;
  bool _acepta = false;
  bool _loading = false;

  static const _minPassword = 8;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final nombre = _nombre.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _nombreError = nombre.isEmpty ? 'Ingresa tu nombre.' : null;
      _emailError = switch (email) {
        '' => 'Ingresa tu correo.',
        _ when !email.contains('@') || !email.contains('.') =>
          'Ese correo no parece válido.',
        _ => null,
      };
      _passwordError = switch (password.length) {
        0 => 'Crea una contraseña.',
        < _minPassword => 'Debe tener al menos $_minPassword caracteres.',
        _ => null,
      };
    });

    return _nombreError == null && _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (_loading || !_acepta || !_validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
        email: _email.text.trim(),
        password: _password.text,
        nombre: _nombre.text.trim(),
      );
      if (mounted) {
        context.go(Routes.verifyEmail, extra: _email.text.trim());
      }
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = e.fieldErrors['email'] ?? e.message;
        _passwordError = e.fieldErrors['password'];
      });
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Crea tu cuenta',
      subtitulo: 'Te tomará menos de un minuto.',
      mostrarVolver: true,
      alVolver: () => context.go(Routes.login),
      tarjeta: [
        EnamTextField(
          label: 'Nombre',
          controller: _nombre,
          error: _nombreError,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          enabled: !_loading,
          onChanged: (_) {
            if (_nombreError != null) setState(() => _nombreError = null);
          },
        ),
        EnamTextField(
          label: 'Correo',
          controller: _email,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          enabled: !_loading,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        EnamTextField(
          label: 'Contraseña',
          controller: _password,
          error: _passwordError,
          helper: 'Mínimo $_minPassword caracteres',
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !_loading,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
        ),
        _ConsentCheckbox(
          value: _acepta,
          onChanged: _loading
              ? null
              : (v) => setState(() => _acepta = v ?? false),
          onTapTerms: () => context.push(Routes.terms),
        ),
        EnamButton(
          label: 'Crear cuenta',
          loading: _loading,
          // Sin consentimiento no se puede continuar: es requisito legal, no
          // una preferencia.
          onPressed: _acepta ? _submit : null,
        ),
        AuthFooter(
          pregunta: '¿Ya tienes cuenta?',
          accion: 'Ingresa',
          onTap: _loading ? null : () => context.go(Routes.login),
        ),
        if (!_acepta)
          Text(
            'Necesitas aceptar los términos para continuar.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.onTapTerms,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback onTapTerms;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final linkStyle = context.texts.bodyMedium?.copyWith(
      color: states.info.onTint,
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El Checkbox de Material ya trae 48 × 48 de área táctil.
        Checkbox(value: value, onChanged: onChanged),
        const SizedBox(width: DesignTokens.space1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: DesignTokens.space3),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Acepto los ', style: context.texts.bodyMedium),
                GestureDetector(
                  onTap: onTapTerms,
                  child: Text('Términos', style: linkStyle),
                ),
                Text(' y la ', style: context.texts.bodyMedium),
                GestureDetector(
                  onTap: onTapTerms,
                  child: Text('Política de datos personales', style: linkStyle),
                ),
                Text(
                  ' (Ley N.º 29733)',
                  style: context.texts.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
