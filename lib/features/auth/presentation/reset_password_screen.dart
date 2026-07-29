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
  bool get _cumpleTodo => _cumpleLargo && _tieneNumero && _tieneLetra;

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
          child: _tokenInvalido ? _expired(context) : _form(context),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Crea tu contraseña nueva',
          style: context.texts.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: DesignTokens.lineHeightTight,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Elige una que no uses en otro sitio.',
          style: context.texts.bodyMedium,
        ),
        const SizedBox(height: DesignTokens.space5),
        EnamTextField(
          label: 'Contraseña nueva',
          controller: _password,
          error: _passwordError,
          obscure: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          autofocus: true,
          enabled: !_loading,
          onChanged: (_) => setState(() => _passwordError = null),
        ),
        const SizedBox(height: DesignTokens.space3),
        // Los requisitos se marcan en vivo, así el usuario no descubre la regla
        // recién al enviar.
        _Requisito(cumple: _cumpleLargo, texto: 'Al menos $_minPassword caracteres'),
        _Requisito(cumple: _tieneLetra, texto: 'Incluye letras'),
        _Requisito(cumple: _tieneNumero, texto: 'Incluye números'),
        const SizedBox(height: DesignTokens.space4),
        EnamTextField(
          label: 'Repite la contraseña',
          controller: _confirm,
          error: _confirmError,
          obscure: true,
          textInputAction: TextInputAction.done,
          enabled: !_loading,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
        ),
        const SizedBox(height: DesignTokens.space6),
        EnamButton(
          label: 'Guardar contraseña',
          loading: _loading,
          onPressed: _cumpleTodo ? _submit : null,
        ),
      ],
    );
  }

  Widget _expired(BuildContext context) {
    final states = context.states;

    return Column(
      children: [
        const SizedBox(height: DesignTokens.space10),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: states.warning.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          child: Icon(
            Symbols.link_off,
            size: 40,
            color: states.warning.onTint,
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
        Text(
          'Este enlace ya no sirve',
          style: context.texts.headlineMedium?.copyWith(
            fontSize: DesignTokens.fontSize2xl - 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        Text(
          'Los enlaces vencen por seguridad, y también dejan de servir después '
          'de usarse una vez. Pide uno nuevo.',
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium?.copyWith(height: 1.55),
        ),
        const SizedBox(height: DesignTokens.space6),
        EnamButton(
          label: 'Pedir un enlace nuevo',
          onPressed: () => context.go(Routes.forgotPassword),
        ),
      ],
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
