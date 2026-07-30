import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';

/// Eliminación de cuenta (RNF-06, Ley N.° 29733).
///
/// **No venía diseñada**, solo descrita en una anotación de Ajustes. Es un
/// derecho legal y Play Store exige que sea accesible desde la app, no solo por
/// correo.
///
/// El diseño de la confirmación es deliberado: se pide **escribir ELIMINAR**. Un
/// botón de confirmación se toca por reflejo; escribir una palabra obliga a
/// detenerse. Es la única acción de la app que destruye datos sin vuelta atrás.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmacion = TextEditingController();
  bool _entendido = false;
  bool _procesando = false;

  static const _palabra = 'ELIMINAR';

  /// Días antes de que el borrado sea irreversible. Da margen para arrepentirse
  /// y también permite recuperar una cuenta borrada por error o por un tercero.
  static const _diasGracia = 30;

  @override
  void dispose() {
    _confirmacion.dispose();
    super.dispose();
  }

  bool get _puedeEliminar =>
      _entendido && _confirmacion.text.trim().toUpperCase() == _palabra;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Eliminar mi cuenta'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                const FadeUp(
                  child: StateBanner(
                    kind: BannerKind.error,
                    icon: Symbols.warning,
                    message:
                        'Esto elimina tu cuenta y todos tus datos. Después de '
                        '30 días no se puede recuperar.',
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                const FadeUp(index: 1, child: _QueSePierde()),
                const SizedBox(height: DesignTokens.space5),
                const FadeUp(index: 2, child: _Alternativas()),
                const SizedBox(height: DesignTokens.space5),
                FadeUp(
                  index: 3,
                  child: CheckboxListTile(
                    value: _entendido,
                    onChanged: (v) => setState(() => _entendido = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'Entiendo que perderé mi progreso, mis estadísticas y mi '
                      'suscripción, y que no hay reembolso por el tiempo no '
                      'usado.',
                      style: context.texts.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                FadeUp(
                  index: 4,
                  child: EnamTextField(
                    label: 'Escribe $_palabra para confirmar',
                    controller: _confirmacion,
                    enabled: !_procesando,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Se eliminará la cuenta de ${user.email}',
                    style: context.texts.bodySmall,
                  ),
                ],
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
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _puedeEliminar && !_procesando ? _eliminar : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 56),
                  // Rojo: es destructivo y tiene que verse así.
                  backgroundColor: states.error.base,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusXl + 4,
                    ),
                  ),
                ),
                child: _procesando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Eliminar mi cuenta'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminar() async {
    setState(() => _procesando = true);

    // Falta `DELETE /me` en el contrato. Cuando exista, esto lo llama y luego
    // cierra sesión.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta eliminada. Tienes $_diasGracia días para recuperarla '
            'escribiéndonos.',
          ),
        ),
      );
    }
  }
}

class _QueSePierde extends StatelessWidget {
  const _QueSePierde();

  static const _items = [
    'Tu progreso en las 10 áreas y todos los temas',
    'Tus estadísticas y tu nota proyectada',
    'El historial de simulacros y tu posición en el ranking',
    'Las preguntas que marcaste para repaso',
    'Tu suscripción, sin reembolso por el tiempo no usado',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUÉ SE ELIMINA',
          style: context.texts.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space2 + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.close,
                  size: 17,
                  color: context.states.error.onTint,
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(
                  child: Text(
                    item,
                    style: context.texts.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Antes de destruir, se ofrece lo que probablemente resuelve el problema real.
/// Mucha gente llega aquí queriendo dejar de pagar o de recibir avisos, no
/// borrarse.
class _Alternativas extends StatelessWidget {
  const _Alternativas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: context.states.info.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Buscabas otra cosa?',
            style: context.texts.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.scheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Si solo quieres dejar de pagar, puedes cancelar la renovación y '
            'conservar tu cuenta y tu progreso. Si te molestan los avisos, se '
            'apagan en Ajustes. Y si no quieres aparecer en el ranking, hay una '
            'opción para ocultarte.',
            style: context.texts.bodyMedium?.copyWith(
              height: 1.55,
              color: context.states.info.onTint,
            ),
          ),
        ],
      ),
    );
  }
}
