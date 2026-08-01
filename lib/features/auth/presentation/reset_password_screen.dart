import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 1.8 — nueva contraseña.
///
/// Se llega desde "olvidé mi contraseña": el correo trae un código de 6 dígitos
/// que se escribe aquí junto con la contraseña nueva.
///
/// Antes se abría desde un enlace del correo. Eso obligaba a abrirlo en ESTE
/// dispositivo, moría si el certificado del dominio no estaba listo y en la
/// carpeta de spam un enlace es justo lo que a la gente le enseñaron a no
/// pulsar. El código se lee en la vista previa y se teclea donde haga falta.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.email, super.key});

  /// Correo al que se mandó el código. Llega desde la pantalla anterior; si
  /// falta, se pide aquí.
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const _minPassword = 8;

  /// Dígitos del código que manda el servidor.
  static const _largoCodigo = 6;

  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _codigo = TextEditingController();
  final _email = TextEditingController();

  String? _passwordError;
  String? _confirmError;
  String? _codigoError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _email.text = widget.email ?? '';
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _codigo.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _cumpleLargo => _password.text.length >= _minPassword;
  bool get _tieneNumero => _password.text.contains(RegExp(r'\d'));
  bool get _tieneLetra => _password.text.contains(RegExp('[a-zA-Z]'));
  bool get _coinciden =>
      _password.text.isNotEmpty && _password.text == _confirm.text;

  /// El diseño deshabilita "Guardar contraseña" hasta cumplir todos los
  /// requisitos, así que la coincidencia cuenta como uno más y no se valida
  /// solo al enviar.
  bool get _cumpleTodo =>
      _cumpleLargo && _tieneNumero && _tieneLetra && _coinciden;

  bool _validate() {
    setState(() {
      _codigoError = switch (_codigo.text) {
        '' => 'Escribe el código que te enviamos.',
        _ when _codigo.text.length != _largoCodigo =>
          'El código tiene $_largoCodigo dígitos.',
        _ => null,
      };
      _passwordError = switch (_password.text) {
        '' => 'Crea una contraseña.',
        _ when !_cumpleLargo => 'Debe tener al menos $_minPassword caracteres.',
        _ when !_tieneNumero || !_tieneLetra =>
          'Combina letras y números.',
        _ => null,
      };
      _confirmError = switch (_confirm.text) {
        '' => 'Repite la contraseña.',
        _ when _confirm.text != _password.text => 'Las contraseñas no coinciden.',
        _ => null,
      };
    });
    return _passwordError == null &&
        _confirmError == null &&
        _codigoError == null;
  }

  Future<void> _submit() async {
    if (_loading || !_validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        email: _email.text.trim(),
        codigo: _codigo.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu contraseña quedó actualizada.')),
      );
      context.go(Routes.login);
    } on UnauthorizedFailure {
      // El código no vale: se queda en el formulario, porque puede ser un
      // dígito mal escrito y quedan intentos.
      if (mounted) {
        setState(() {
          _codigoError = 'Ese código no es válido o ya venció.';
          _codigo.clear();
        });
      }
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        final dePassword = e.fieldErrors['password'];
        if (dePassword != null) {
          _passwordError = dePassword;
        } else {
          _codigoError = e.message;
          _codigo.clear();
        }
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
      titulo: 'Contraseña nueva',
      subtitulo: 'Escribe el código que te enviamos y elige tu contraseña.',
      iconoCabecera: Symbols.lock_reset,
      tamanoTitulo: 26,
      tarjeta: _formulario(context),
    );
  }

  List<Widget> _formulario(BuildContext context) => [
    // Solo si no llegó desde la pantalla anterior: quien viene de ahí ya lo
    // escribió una vez.
    if ((widget.email ?? '').isEmpty)
      EnamTextField(
        label: 'Correo',
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        enabled: !_loading,
      ),
    EnamTextField(
      label: 'Código de $_largoCodigo dígitos',
      controller: _codigo,
      error: _codigoError,
      // Teclado numérico y autocompletado del código: en iOS y Android el
      // sistema lo ofrece encima del teclado y no hay que teclearlo.
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      textInputAction: TextInputAction.next,
      autofocus: true,
      enabled: !_loading,
      onChanged: (_) => setState(() => _codigoError = null),
    ),
    EnamTextField(
      label: 'Nueva contraseña',
      controller: _password,
      error: _passwordError,
      obscure: true,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      enabled: !_loading,
      onChanged: (_) => setState(() => _passwordError = null),
    ),
    EnamTextField(
      label: 'Confírmala',
      controller: _confirm,
      error: _confirmError,
      obscure: true,
      textInputAction: TextInputAction.done,
      enabled: !_loading,
      onSubmitted: (_) => _submit(),
      onChanged: (_) => setState(() => _confirmError = null),
    ),
    // La lista se marca en vivo, así el usuario no descubre la regla recién al
    // enviar.
    _ListaRequisitos(
      children: [
        _Requisito(cumple: _cumpleLargo, texto: 'Mínimo $_minPassword caracteres'),
        _Requisito(cumple: _tieneNumero, texto: 'Al menos un número'),
        // Fuera del diseño a propósito: con sus tres reglas, "12345678" sería
        // una contraseña válida. Una fila más y deja de serlo.
        _Requisito(cumple: _tieneLetra, texto: 'Al menos una letra'),
        _Requisito(cumple: _coinciden, texto: 'Ambos campos coinciden'),
      ],
    ),
    EnamButton(
      label: 'Guardar contraseña',
      loading: _loading,
      onPressed: _cumpleTodo ? _submit : null,
    ),
  ];

}

/// La caja con borde que agrupa los requisitos, como en el diseño.
class _ListaRequisitos extends StatelessWidget {
  const _ListaRequisitos({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito({required this.cumple, required this.texto});

  final bool cumple;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final color = cumple
        ? states.success.onTint
        : context.scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space1),
      child: Row(
        children: [
          Icon(
            cumple ? Symbols.check_circle : Symbols.circle,
            size: 16,
            fill: cumple ? 1 : 0,
            color: color,
          ),
          const SizedBox(width: DesignTokens.space2),
          // Expanded para que el texto baje de línea a 360 px o con la fuente
          // del sistema ampliada, en vez de desbordar la fila.
          Expanded(
            child: Text(
              texto,
              style: context.texts.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
