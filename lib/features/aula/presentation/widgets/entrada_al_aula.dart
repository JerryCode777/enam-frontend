import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/navegar.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../aula_providers.dart';

/// La entrada a los cursos desde el inicio, como «Cursos» en «Más formas de
/// estudiar» de la web: «Muy pronto» mientras ningún curso tiene clases, y
/// «Nuevo» cuando ya hay.
class EntradaAlAula extends ConsumerWidget {
  const EntradaAlAula({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursos = ref.watch(cursosProvider).value;
    final hayClases = cursos?.any((c) => !c.proximamente);
    final scheme = context.scheme;
    final info = context.states.info;

    return Card(
      child: InkWell(
        onTap: () => context.irA(Routes.cursos),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space3 + 1,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: info.tint,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(
                  Symbols.school,
                  size: 22,
                  fill: 1,
                  color: info.onTint,
                ),
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cursos',
                          style: context.texts.bodyLarge?.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (hayClases != null) ...[
                          const SizedBox(width: DesignTokens.space2),
                          _Pastilla(
                            texto: hayClases ? 'Nuevo' : 'Muy pronto',
                            destacada: hayClases,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Clases en video del temario oficial, con su práctica',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.texto, required this.destacada});

  final String texto;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final success = context.states.success;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: destacada ? success.tint : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        texto,
        style: context.texts.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: destacada ? success.onTint : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
