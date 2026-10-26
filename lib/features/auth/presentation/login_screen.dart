import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/auth_footer.dart';
import '../../../shared/widgets/aviso_legal_al_continuar.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/fondo_claro.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/ecg_line.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/social_buttons.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../consentimiento/presentation/casilla_de_comerciales.dart';
import 'eventos_de_registro.dart';
import 'verify_email_screen.dart' show CodigoPorVerificar;

/// El 403 del login con un correo que todavía no se verificó. El servidor ya
/// mandó un código nuevo: se va a escribirlo.
bool esCorreoSinVerificar(Object error) =>
    error is ForbiddenFailure && error.code == 'EMAIL_NOT_VERIFIED';

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
  bool _comerciales = false;

  /// El correo de un registro que se quedó sin escribir su código, si hay.
  String? _pendiente;

  @override
  void initState() {
    super.initState();
    unawaited(_leerPendiente());
  }

  Future<void> _leerPendiente() async {
    try {
      final email = await ref.read(appPrefsProvider).verificacionPendiente();
      if (mounted && email != null) setState(() => _pendiente = email);
    } on Object {
      // Sin preferencias no hay aviso; el login sigue igual.
    }
  }

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
      final entro = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle(
            aceptaTerminos: true,
            aceptaComerciales: comercialesDelAlta(_comerciales),
          );
      if (!entro && mounted) _fallo('google', 'proveedor_cancelado');
    } on Object catch (error) {
      // Lo que falla dentro de Google —una configuración, la huella SHA— llega
      // como `UnknownFailure`: es del proveedor, no «otro».
      if (mounted) {
        _fallo(
          'google',
          error is UnknownFailure ? 'proveedor_error' : motivoDeFallo(error),
        );
      }
      // En snackbar y no bajo los campos: el fallo no viene de lo que el
      // usuario escribió, así que señalarle la contraseña sería engañoso.
      if (mounted) {
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
      final entro = await ref
          .read(authControllerProvider.notifier)
          .signInWithApple(
            aceptaTerminos: true,
            aceptaComerciales: comercialesDelAlta(_comerciales),
          );
      if (!entro && mounted) _fallo('apple', 'proveedor_cancelado');
    } on Object catch (error) {
      if (mounted) _fallo('apple', motivoDeFallo(error));
      if (mounted) {
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
      // Si llegó aquí, entró: el router se encarga de sacar de esta pantalla.
    } on Object catch (error) {
      // El fallo llega como excepción, no leyendo el estado: con credenciales
      // malas el usuario sigue sin sesión, esta pantalla no se desmonta y el
      // error se puede enseñar donde toca.
      if (!mounted) return;
      if (esCorreoSinVerificar(error)) {
        // No es un error: le falta el código, y acaba de salir uno nuevo.
        // Antes se quedaba aquí con un aviso y sin forma de escribirlo.
        final email = _email.text.trim();
        await ref.read(appPrefsProvider).guardarVerificacionPendiente(email);
        if (mounted) {
          context.go(Routes.verifyEmail, extra: CodigoPorVerificar(email));
        }
        return;
      }
      _fallo('correo', motivoDeFallo(error));
      _showFailure(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// `registro_fallido` desde esta pantalla (catálogo 19).
  void _fallo(String metodo, String motivo) =>
      registrarFallo(ref, metodo: metodo, motivo: motivo);

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
      body: FondoClaro(
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
                      if (_pendiente case final pendiente?)
                        _CodigoPendiente(
                          email: pendiente,
                          onTap: _ocupado
                              ? null
                              : () => context.go(
                                  Routes.verifyEmail,
                                  // El código pudo vencer: reenviar, ya.
                                  extra: CodigoPorVerificar(
                                    pendiente,
                                    recienEnviado: false,
                                  ),
                                ),
                        ),
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
                              : () => context.irA(
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
                      // Google y Apple también crean cuentas, y desde aquí:
                      // la casilla vale para el alta y el servidor la ignora
                      // en una cuenta que ya existía. Antes de los botones,
                      // para que se vea antes de tocarlos.
                      if (_hayProveedores)
                        CasillaDeComerciales(
                          value: _comerciales,
                          onChanged: _ocupado
                              ? null
                              : (v) => setState(() => _comerciales = v),
                        ),
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
                      // Debajo de los botones y siempre a la vista: es lo que
                      // convierte el toque en consentimiento previo e
                      // informado, sin sacar a nadie del camino.
                      if (_hayProveedores) const AvisoLegalAlContinuar(),
                      AuthFooter(
                        pregunta: '¿Primera vez?',
                        accion: 'Crea tu cuenta',
                        onTap: _ocupado
                            ? null
                            : () => context.go(Routes.register),
                      ),
                      // Ayuda para desarrollo: con mocks, estos correos disparan
                      // cada camino de error sin tocar código.
                      //
                      // La condición mira los mocks y no el modo de compilación:
                      // en debug contra el backend real ninguno de esos correos
                      // entra, y el cartel prometía lo contrario.
                      if (AppConfig.useMocks)
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

/// Un registro que se quedó sin escribir su código: la vuelta a escribirlo.
class _CodigoPendiente extends StatelessWidget {
  const _CodigoPendiente({required this.email, required this.onTap});

  final String email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StateBanner(
      kind: BannerKind.info,
      message: 'Te falta verificar $email.',
      action: TextButton(
        onPressed: onTap,
        child: const Text('Ingresar código'),
      ),
    );
  }
}

/// Logo, saludo y el electrocardiograma sobre el degradado.
class _CabeceraMarca extends StatelessWidget {
  const _CabeceraMarca();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
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
              // El azulejo de marca: sobre el fondo claro, la cruz blanca
              // necesita su propio fondo azul para verse.
              BrandMarkTile(size: 52, radio: 16),
              SizedBox(width: DesignTokens.space3),
              Text(
                'ENAM Prep',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space5),
          Text(
            'Hola de nuevo',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: DesignTokens.textPrimaryLight,
            ),
          ),
          SizedBox(height: DesignTokens.space3),
          // El mismo trazo del splash, aquí más pequeño y discreto.
          EcgLine(
            width: 170,
            height: 22,
            opacity: 0.7,
            strokeWidth: 2,
            color: DesignTokens.actionLight,
          ),
        ],
      ),
    );
  }
}
