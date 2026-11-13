import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/correo.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/fondo_claro.dart';
import '../../../shared/widgets/state_banner.dart';
import 'eventos_de_registro.dart';

/// A dónde va la pantalla del código: el correo, y si el código acaba de
/// salir (al registrarse, o al entrar con la cuenta sin verificar) o no (al
/// volver desde el login con un registro a medias, cuando el código pudo
/// vencer y el reenvío tiene que estar a mano).
class CodigoPorVerificar {
  const CodigoPorVerificar(
    this.email, {
    this.recienEnviado = true,
    this.password,
  });

  final String email;
  final bool recienEnviado;

  /// La que acaba de escribir en el registro o el login, si la hay: así
  /// corregir el correo no le pide escribirla otra vez. Solo en memoria.
  final String? password;
}

/// Deja solo los dígitos del código y corta en [largo].
///
/// Se pega del correo —«123 456», «123-456», « 123456 »— y antes `maxLength`
/// cortaba lo pegado **antes** de quitar nada: «123 456» quedaba en «123 45»,
/// seis caracteres que se mandaban y el servidor rechazaba.
class SoloDigitosDelCodigo extends TextInputFormatter {
  const SoloDigitosDelCodigo(this.largo);

  final int largo;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > largo) digitos = digitos.substring(0, largo);
    if (digitos == newValue.text) return newValue;
    return TextEditingValue(
      text: digitos,
      selection: TextSelection.collapsed(offset: digitos.length),
    );
  }
}

/// La pista bajo el código. Pequeña y siempre a la vista: el correo suele
/// caer en spam o en Promociones, y es lo primero que hay que mirar.
const pistaDeSpam = '¿No te llegó? Revisa tu carpeta de spam o promociones.';

/// Pantalla 1.4 — verificación de correo con código.
///
/// El correo trae un código de 6 dígitos (RF-01) que se escribe aquí. Antes era
/// un enlace, y eso obligaba a abrirlo en ESTE teléfono, se rompía si el
/// certificado del dominio no estaba listo, y en spam un enlace es justo lo que
/// a la gente le enseñaron a no pulsar.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    this.email,
    this.codigoRecienEnviado = true,
    this.password,
    super.key,
  });

  /// Correo al que se envió el código. Si es nulo, se lee del usuario en sesión.
  final String? email;

  /// Si el código acaba de salir. Si no, «Reenviar código» está disponible
  /// desde el principio, sin esperar el minuto.
  final bool codigoRecienEnviado;

  /// Ver [CodigoPorVerificar.password].
  final String? password;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldown = 60;

  /// Dígitos del código que manda el servidor.
  static const _largoCodigo = 6;

  final _codigo = TextEditingController();

  Timer? _timer;
  int _restante = 0;
  bool _enviando = false;
  bool _verificando = false;
  String? _codigoError;

  /// El correo al que se mandó el código: cambia si lo corrige aquí.
  String? _correo;
  String? _password;

  String get _email =>
      _correo ?? widget.email ?? ref.read(currentUserProvider)?.email ?? '';

  @override
  void initState() {
    super.initState();
    _password = widget.password;
    if (widget.codigoRecienEnviado) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar(String email) async {
    if (_verificando) return;
    final codigo = _codigo.text;
    if (codigo.length != _largoCodigo) {
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
          .verificarConCodigo(email: email, codigo: codigo);
      // Verificada (o ya lo estaba): ya no hay código pendiente que retomar.
      await ref.read(appPrefsProvider).olvidarVerificacionPendiente();
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
      if (e is ValidationFailure) {
        registrarFallo(ref, metodo: 'correo', motivo: 'codigo_invalido');
      }
      setState(() {
        _codigoError = switch (e) {
          // Sin mensaje propio del servidor: decir qué hacer, no solo que no.
          ValidationFailure(:final message) when message.isEmpty =>
            'Ese código no es válido o ya venció. Revisa el último correo o '
                'pide uno nuevo.',
          _ => e.message,
        };
        _codigo.clear();
      });
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  void _startCooldown([int segundos = _cooldown]) {
    _timer?.cancel();
    setState(() => _restante = segundos);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restante <= 1) {
        t.cancel();
        if (mounted) setState(() => _restante = 0);
      } else if (mounted) {
        setState(() => _restante--);
      }
    });
  }

  /// «¿Correo equivocado? Cámbialo»: el código va al correo nuevo, en la
  /// misma cuenta. Antes este botón llevaba al registro, y la persona creaba
  /// una cuenta nueva dejando la otra con el correo malo.
  Future<void> _cambiarCorreo({String? sugerido}) async {
    final actual = _email;
    if (actual.isEmpty) return;
    final cambio = await showModalBottomSheet<_Cambio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaCambiarCorreo(
        actual: actual,
        sugerido: sugerido ?? sugerenciaDeCorreo(actual),
        password: _password,
      ),
    );
    if (cambio == null || !mounted) return;

    final prefs = ref.read(appPrefsProvider);
    switch (cambio) {
      case _Cambiado(:final email, :final password):
        await prefs.guardarVerificacionPendiente(email);
        if (!mounted) return;
        setState(() {
          _correo = email;
          _password = password;
          _codigo.clear();
          _codigoError = null;
        });
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te enviamos un código nuevo a $email.')),
        );
      case _YaVerificada():
        await prefs.olvidarVerificacionPendiente();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu cuenta ya estaba verificada. Ingresa con ella.'),
          ),
        );
        context.go(Routes.login);
    }
  }

  Future<void> _reenviar() async {
    final email = _email;
    if (email.isEmpty || _enviando) return;

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
    } on RateLimitFailure catch (e) {
      // Demasiado pronto: la espera es la que dice el servidor.
      if (!mounted) return;
      _startCooldown(e.retryAfter?.inSeconds ?? _cooldown);
      showErrorSnack(context, e.message);
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
    final email =
        _correo ?? widget.email ?? ref.watch(currentUserProvider)?.email ?? '';
    final sugerido = sugerenciaDeCorreo(email);
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
                    if (sugerido != null) ...[
                      const SizedBox(height: DesignTokens.space3),
                      _AvisoDeCorreo(
                        sugerido: sugerido,
                        onCorregir: () => _cambiarCorreo(sugerido: sugerido),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space5),
                    _CampoCodigo(
                      controller: _codigo,
                      error: _codigoError,
                      largo: _largoCodigo,
                      enabled: !_verificando,
                      onChanged: () {
                        setState(() => _codigoError = null);
                        // Pegado o autocompletado entero: se verifica solo.
                        if (_codigo.text.length == _largoCodigo) {
                          unawaited(_verificar(email));
                        }
                      },
                      onSubmit: () => _verificar(email),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    const Text(
                      pistaDeSpam,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: DesignTokens.textSecondaryLight,
                      ),
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
                      onPressed: _enviando || _verificando
                          ? null
                          : _cambiarCorreo,
                      child: const Text(
                        '¿Correo equivocado? Cámbialo',
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
          // Sin `maxLength`: cortaba lo pegado antes de limpiarlo.
          inputFormatters: [SoloDigitosDelCodigo(largo)],
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

/// «¿Quisiste decir …@gmail.com?» bajo el correo, cuando el dominio parece
/// mal escrito: es la razón más común de que el código no llegue.
class _AvisoDeCorreo extends StatelessWidget {
  const _AvisoDeCorreo({required this.sugerido, required this.onCorregir});

  final String sugerido;
  final VoidCallback onCorregir;

  @override
  Widget build(BuildContext context) {
    final aviso = context.states.warning;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space3,
        DesignTokens.space2,
        DesignTokens.space1,
        DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: aviso.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '¿Quisiste decir '),
                  TextSpan(
                    text: sugerido,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
              style: TextStyle(fontSize: 14, height: 1.4, color: aviso.onTint),
            ),
          ),
          TextButton(onPressed: onCorregir, child: const Text('Corregir')),
        ],
      ),
    );
  }
}

/// Lo que devuelve la hoja de cambiar el correo.
sealed class _Cambio {
  const _Cambio();
}

final class _Cambiado extends _Cambio {
  const _Cambiado(this.email, this.password);

  final String email;
  final String password;
}

final class _YaVerificada extends _Cambio {
  const _YaVerificada();
}

/// El correo nuevo y, si no se tiene de antes, la contraseña: es la prueba de
/// que la cuenta es suya (aquí no hay sesión).
class _HojaCambiarCorreo extends ConsumerStatefulWidget {
  const _HojaCambiarCorreo({
    required this.actual,
    this.sugerido,
    this.password,
  });

  final String actual;
  final String? sugerido;
  final String? password;

  @override
  ConsumerState<_HojaCambiarCorreo> createState() => _HojaCambiarCorreoState();
}

class _HojaCambiarCorreoState extends ConsumerState<_HojaCambiarCorreo> {
  late final _correo = TextEditingController(
    text: widget.sugerido ?? widget.actual,
  );
  final _clave = TextEditingController();

  /// Se pide si no llegó, o si la que llegó no sirvió.
  late bool _pedirClave = widget.password == null;
  String? _correoError;
  String? _claveError;
  String? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    final nuevo = _correo.text.trim();
    final password = _pedirClave ? _clave.text : widget.password!;
    setState(() {
      _correoError = switch (nuevo) {
        '' => 'Ingresa tu correo.',
        _ when !nuevo.contains('@') || !nuevo.contains('.') =>
          'Ese correo no parece válido.',
        _ when nuevo.toLowerCase() == widget.actual.toLowerCase() =>
          'Es el mismo correo de ahora.',
        _ => null,
      };
      _claveError = password.isEmpty ? 'Ingresa tu contraseña.' : null;
      _error = null;
    });
    if (_correoError != null || _claveError != null) return;

    setState(() => _enviando = true);
    try {
      final quedo = await ref
          .read(authRepositoryProvider)
          .cambiarCorreo(
            email: widget.actual,
            password: password,
            emailNuevo: nuevo,
          );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(quedo == null ? const _YaVerificada() : _Cambiado(quedo, password));
    } on UnauthorizedFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _pedirClave = true;
        _clave.clear();
        _claveError = e.message;
      });
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _correoError =
            e.fieldErrors['emailNuevo'] ??
            (e.code == 'EMAIL_TAKEN'
                ? 'Ese correo ya tiene una cuenta. Ingresa con él.'
                : e.message),
      );
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space6,
        0,
        DesignTokens.space6,
        DesignTokens.space6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cambia tu correo',
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Ahora es '),
                  TextSpan(
                    text: widget.actual,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text:
                        '. Te mandaremos un código nuevo al correo que '
                        'escribas, en la misma cuenta.',
                  ),
                ],
              ),
              style: context.texts.bodyMedium?.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            EnamTextField(
              label: 'Correo correcto',
              controller: _correo,
              error: _correoError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _pedirClave
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              enabled: !_enviando,
              onSubmitted: _pedirClave ? null : (_) => _enviar(),
              onChanged: (_) {
                if (_correoError != null) setState(() => _correoError = null);
              },
            ),
            if (_pedirClave) ...[
              const SizedBox(height: DesignTokens.space3),
              EnamTextField(
                label: 'Tu contraseña',
                helper: 'La que pusiste al crear la cuenta.',
                controller: _clave,
                error: _claveError,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !_enviando,
                onSubmitted: (_) => _enviar(),
                onChanged: (_) {
                  if (_claveError != null) setState(() => _claveError = null);
                },
              ),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: DesignTokens.space3),
              Text(error, style: TextStyle(color: context.states.error.base)),
            ],
            const SizedBox(height: DesignTokens.space4),
            EnamButton(
              label: 'Enviar el código ahí',
              loading: _enviando,
              onPressed: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}
