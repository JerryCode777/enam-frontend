import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/auth_footer.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/google_button.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 1.5 — login con correo y contraseña, y con Google.
///
/// RF-01/RF-02 del SSD solo contemplan correo y contraseña, pero el diseño
/// incluye "o continúa con Google" y esa fue la decisión del cliente. Queda
/// anotado en IMPLEMENTACION.md como desviación consciente del SSD.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _loading = false;
  bool _loadingGoogle = false;

  /// Cualquier login en curso: bloquea el resto de la pantalla, para que no se
  /// puedan lanzar los dos a la vez.
  bool get _ocupado => _loading || _loadingGoogle;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Valida en el cliente antes de gastar una llamada de red.
  bool _validate() {
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _emailError = switch (email) {
        '' => 'Ingresa tu correo.',
        _ when !email.contains('@') || !email.contains('.') =>
          'Ese correo no parece válido.',
        _ => null,
      };
      _passwordError = password.isEmpty ? 'Ingresa tu contraseña.' : null;
    });

    return _emailError == null && _passwordError == null;
  }

  Future<void> _submitGoogle() async {
    if (_ocupado) return;

    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();

      // Si el login funcionó, el router ya desmontó esta pantalla y ni el
      // ref ni el context se pueden tocar (Riverpod lanza si se intenta).
      if (!mounted) return;

      // Igual que en el login normal: el router redirige solo si el estado
      // pasó a autenticado; si quedó en error, se muestra aquí.
      //
      // En snackbar y no bajo los campos: el fallo no viene de lo que el
      // usuario escribió, así que señalarle la contraseña sería engañoso.
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        showErrorSnack(
          context,
          error is Failure ? error.message : 'No se pudo continuar con Google.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _submit() async {
    if (_ocupado || !_validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: _email.text.trim(), password: _password.text);

      // Si el login funcionó, el router ya desmontó esta pantalla y ni el
      // ref ni el context se pueden tocar (Riverpod lanza si se intenta).
      if (!mounted) return;

      // El router redirige solo cuando cambia el estado de auth. Si el estado
      // quedó en error, hay que mostrarlo aquí.
      final state = ref.read(authControllerProvider);
      final error = state.error;
      if (error != null) _showFailure(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFailure(Object error) {
    switch (error) {
      // Credenciales malas: el error va bajo la contraseña, no en un snackbar
      // que desaparece. Y el mensaje no culpa al usuario.
      case UnauthorizedFailure(:final message):
        setState(() => _passwordError = message);
      case ValidationFailure(:final fieldErrors, :final message):
        setState(() {
          _emailError = fieldErrors['email'];
          _passwordError = fieldErrors['password'] ?? message;
        });
      case Failure(:final message):
        showErrorSnack(context, message);
      default:
        showErrorSnack(context, 'Ocurrió un error inesperado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space6,
            DesignTokens.space12,
            DesignTokens.space6,
            DesignTokens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: states.info.tint,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMd + 2,
                      ),
                    ),
                    child: Icon(
                      Symbols.stethoscope,
                      size: 24,
                      fill: 1,
                      color: states.info.onTint,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Text(
                    'ENAM Prep',
                    style: context.texts.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space6),
              Text(
                'Hola de nuevo',
                style: context.texts.headlineMedium?.copyWith(
                  fontSize: DesignTokens.fontSize2xl + 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DesignTokens.space5),
              EnamTextField(
                label: 'Correo',
                controller: _email,
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !_ocupado,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: DesignTokens.space4),
              EnamTextField(
                label: 'Contraseña',
                controller: _password,
                error: _passwordError,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !_ocupado,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
              const SizedBox(height: DesignTokens.space2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _ocupado
                      ? null
                      : () => context.push(Routes.forgotPassword),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              EnamButton(
                label: 'Ingresar',
                loading: _loading,
                onPressed: _submit,
              ),
              if (AppConfig.googleSignInHabilitado) ...[
                const SizedBox(height: DesignTokens.space5),
                const SeparadorAuth(),
                const SizedBox(height: DesignTokens.space4),
                GoogleButton(
                  loading: _loadingGoogle,
                  onPressed: _ocupado ? null : _submitGoogle,
                ),
              ],
              const SizedBox(height: DesignTokens.space4),
              AuthFooter(
                pregunta: '¿Primera vez?',
                accion: 'Crea tu cuenta',
                onTap: _ocupado ? null : () => context.go(Routes.register),
              ),
              const SizedBox(height: DesignTokens.space4),
              // Ayuda para desarrollo: con mocks, estos correos disparan cada
              // camino de error sin tocar código.
              if (const bool.fromEnvironment('dart.vm.product') == false)
                Text(
                  'Modo desarrollo · cualquier correo entra · '
                  'contraseña "error" falla · nuevo2@enam.pe entra con perfil '
                  'incompleto',
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
