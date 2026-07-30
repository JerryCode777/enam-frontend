import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';

/// Cambiar contraseña desde la sesión activa.
///
/// Pide la contraseña actual: sin eso, alguien con el teléfono desbloqueado
/// podría cambiarla y quedarse con la cuenta.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  static const _minPassword = 8;

  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  String? _errorActual;
  String? _errorNueva;
  String? _errorConfirmar;
  bool _guardando = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool get _cumpleLargo => _nueva.text.length >= _minPassword;
  bool get _tieneNumero => _nueva.text.contains(RegExp(r'\d'));
  bool get _tieneLetra => _nueva.text.contains(RegExp('[a-zA-Z]'));
  bool get _cumpleTodo => _cumpleLargo && _tieneNumero && _tieneLetra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Cambiar contraseña'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                FadeUp(
                  child: EnamTextField(
                    label: 'Contraseña actual',
                    controller: _actual,
                    error: _errorActual,
                    obscure: true,
                    enabled: !_guardando,
                    onChanged: (_) {
                      if (_errorActual != null) {
                        setState(() => _errorActual = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                FadeUp(
                  index: 1,
                  child: EnamTextField(
                    label: 'Contraseña nueva',
                    controller: _nueva,
                    error: _errorNueva,
                    obscure: true,
                    enabled: !_guardando,
                    onChanged: (_) => setState(() => _errorNueva = null),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                _Requisito(
                  cumple: _cumpleLargo,
                  texto: 'Al menos $_minPassword caracteres',
                ),
                _Requisito(cumple: _tieneLetra, texto: 'Incluye letras'),
                _Requisito(cumple: _tieneNumero, texto: 'Incluye números'),
                const SizedBox(height: DesignTokens.space4),
                FadeUp(
                  index: 2,
                  child: EnamTextField(
                    label: 'Repite la contraseña nueva',
                    controller: _confirmar,
                    error: _errorConfirmar,
                    obscure: true,
                    enabled: !_guardando,
                    onChanged: (_) {
                      if (_errorConfirmar != null) {
                        setState(() => _errorConfirmar = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                const FadeUp(
                  index: 3,
                  child: StateBanner(
                    icon: Symbols.devices,
                    message:
                        'Al cambiarla, se cierran las sesiones abiertas en otros '
                        'dispositivos.',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: context.scheme.surface,
              border: Border(
                top: BorderSide(color: context.scheme.outlineVariant),
              ),
            ),
            child: EnamButton(
              label: 'Guardar contraseña',
              loading: _guardando,
              onPressed: _cumpleTodo ? _guardar : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    setState(() {
      _errorActual = _actual.text.isEmpty ? 'Ingresa tu contraseña actual.' : null;
      _errorConfirmar = _confirmar.text != _nueva.text
          ? 'Las contraseñas no coinciden.'
          : null;
      // Cambiarla por la misma no aporta nada y confunde.
      _errorNueva = _nueva.text == _actual.text
          ? 'La nueva tiene que ser distinta de la actual.'
          : null;
    });

    if (_errorActual != null ||
        _errorConfirmar != null ||
        _errorNueva != null) {
      return;
    }

    setState(() => _guardando = true);
    try {
      // Falta `POST /me/password` en el contrato. Se reutiliza resetPassword
      // como puente hasta que exista.
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: _actual.text, newPassword: _nueva.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada')),
      );
      context.pop();
    } on UnauthorizedFailure {
      if (mounted) {
        setState(() => _errorActual = 'Esa no es tu contraseña actual.');
      }
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito({required this.cumple, required this.texto});

  final bool cumple;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final color = cumple
        ? context.states.success.onTint
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
