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
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/brand_gradient.dart';
import '../../../shared/widgets/ecg_line.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/social_buttons.dart';
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
  bool _loadingApple = false;

  /// Cualquier login en curso: bloquea el resto de la pantalla, para que no se
  /// puedan lanzar dos a la vez.
  bool get _ocupado => _loading || _loadingGoogle || _loadingApple;

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

      // Igual que en el login normal: el router redirige solo si el estado
      // pasó a autenticado; si quedó en error, se muestra aquí.
      //
      // En snackbar y no bajo los campos: el fallo no viene de lo que el
      // usuario escribió, así que señalarle la contraseña sería engañoso.
      final error = ref.read(authControllerProvider).error;
      if (error != null && mounted) {
        showErrorSnack(
          context,
          error is Failure ? error.message : 'No se pudo continuar con Google.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _submitApple() async {
    if (_ocupado) return;

    setState(() => _loadingApple = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithApple();

      final error = ref.read(authControllerProvider).error;
      if (error != null && mounted) {
        showErrorSnack(
          context,
          error is Failure ? error.message : 'No se pudo continuar con Apple.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingApple = false);
    }
  }

  Future<void> _submit() async {
    if (_ocupado || !_validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: _email.text.trim(), password: _password.text);

      // El router redirige solo cuando cambia el estado de auth. Si el estado
      // quedó en error, hay que mostrarlo aquí.
      final state = ref.read(authControllerProvider);
      final error = state.error;
      if (error != null && mounted) _showFailure(error);
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

  /// Si hay al menos un proveedor externo que mostrar.
  bool get _hayProveedores =>
      AppConfig.googleSignInHabilitado ||
      (ref.read(appleDisponibleProvider).value ?? false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _CabeceraMarca(),
                const SizedBox(height: DesignTokens.space3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    0,
                    DesignTokens.space4,
                    DesignTokens.space6,
                  ),
                  child: AuthCard(
                    children: [
                      EnamTextField(
                        label: 'Correo',
                        controller: _email,
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        enabled: !_ocupado,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                      ),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _ocupado
                              ? null
                              : () => context.push(
                                  Routes.forgotPassword,
                                  // Se lleva lo que ya escribió: volver a
                                  // teclear el correo justo cuando no
                                  // recuerdas algo es fricción gratuita.
                                  extra: _email.text.trim().isEmpty
                                      ? null
                                      : _email.text.trim(),
                                ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      EnamButton(
                        label: 'Ingresar',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      if (_hayProveedores) const SeparadorAuth(),
                      if (AppConfig.googleSignInHabilitado)
                        GoogleButton(
                          loading: _loadingGoogle,
                          onPressed: _ocupado ? null : _submitGoogle,
                        ),
                      // Solo en iOS: si la app ofrece otro proveedor externo,
                      // App Store exige también "Sign in with Apple", y en
                      // Android el botón no le diría nada a nadie.
                      if (ref.watch(appleDisponibleProvider).value ?? false)
                        AppleButton(
                          loading: _loadingApple,
                          onPressed: _ocupado ? null : _submitApple,
                        ),
                      AuthFooter(
                        pregunta: '¿Primera vez?',
                        accion: 'Crea tu cuenta',
                        onTap: _ocupado ? null : () => context.go(Routes.register),
                      ),
                      // Ayuda para desarrollo: con mocks, estos correos disparan
                      // cada camino de error sin tocar código.
                      if (const bool.fromEnvironment('dart.vm.product') == false)
                        Text(
                          'Modo desarrollo · cualquier correo entra · '
                          'contraseña "error" falla · nuevo2@enam.pe entra con '
                          'perfil incompleto',
                          textAlign: TextAlign.center,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.scheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                    ],
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

/// Logo, saludo y el electrocardiograma sobre el degradado.
class _CabeceraMarca extends StatelessWidget {
  const _CabeceraMarca();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space6,
        DesignTokens.space5,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Symbols.stethoscope,
                  size: 28,
                  fill: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              const Text(
                'ENAM Prep',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space5),
          const Text(
            'Hola de nuevo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          // El mismo trazo del splash, aquí más pequeño y discreto.
          const EcgLine(
            width: 170,
            height: 22,
            opacity: 0.7,
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }
}
