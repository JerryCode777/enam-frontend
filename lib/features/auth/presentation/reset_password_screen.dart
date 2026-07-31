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
/// Se abre desde el enlace del correo, que trae el token en la URL. Esta pantalla
/// **faltaba en el diseño del bloque 1** (estaba solo descrita en una anotación),
/// así que la construyo con los mismos patrones del resto: campo de 56 px,
/// validación inline y requisitos visibles mientras se escribe.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.token, super.key});

  /// Token del enlace del correo. Si es nulo, el enlace es inválido.
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const _minPassword = 8;

  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _passwordError;
  String? _confirmError;
  bool _loading = false;
  bool _tokenInvalido = false;

  @override
  void initState() {
    super.initState();
    _tokenInvalido = (widget.token ?? '').isEmpty;
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
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
    return _passwordError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (_loading || token == null || !_validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        token: token,
        newPassword: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu contraseña quedó actualizada.')),
      );
      context.go(Routes.login);
    } on UnauthorizedFailure {
      // Token vencido o ya usado: no tiene sentido dejar el formulario.
      if (mounted) setState(() => _tokenInvalido = true);
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = e.fieldErrors['password'] ?? e.message);
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tokenInvalido) {
      return AuthScaffold(
        titulo: 'Este enlace ya no sirve',
        iconoCabecera: Symbols.link_off,
        tamanoTitulo: 26,
        tarjeta: _expirado(context),
      );
    }

    return AuthScaffold(
      titulo: 'Contraseña nueva',
      subtitulo: 'Elige una que no uses en otro sitio.',
      iconoCabecera: Symbols.lock_reset,
      tamanoTitulo: 26,
      tarjeta: _formulario(context),
    );
  }

  List<Widget> _formulario(BuildContext context) => [
    EnamTextField(
      label: 'Nueva contraseña',
      controller: _password,
      error: _passwordError,
      obscure: true,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      autofocus: true,
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

  List<Widget> _expirado(BuildContext context) => [
    Text(
      'Los enlaces vencen por seguridad, y también dejan de servir después de '
      'usarse una vez. Pide uno nuevo.',
      style: context.texts.bodyMedium?.copyWith(height: 1.55),
    ),
    EnamButton(
      label: 'Pedir un enlace nuevo',
      onPressed: () => context.go(Routes.forgotPassword),
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
