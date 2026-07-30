import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

/// Pantalla de andamiaje: existe, navega y muestra qué irá aquí.
///
/// Se reemplaza por la pantalla real cuando llegue su diseño. Mientras tanto
/// permite recorrer la app completa y verificar que el router funciona.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.titulo,
    required this.descripcion,
    this.requisitos = const [],
    this.acciones = const [],
    super.key,
  });

  /// Nombre de la pantalla.
  final String titulo;

  /// Qué hace, en una frase.
  final String descripcion;

  /// Requerimientos del SSD que cubre (p. ej. `['RF-16', 'RN-02']`).
  final List<String> requisitos;

  /// Navegación de salida, para poder recorrer el flujo.
  final List<({String label, String ruta})> acciones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sin GoRouter cae al Navigator: la pantalla debe poder pintarse en tests.
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => router != null
                    ? router.pop()
                    : Navigator.of(context).maybePop(),
                tooltip: 'Atrás',
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.construction_outlined,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: DesignTokens.space2),
                          Text(
                            'Pendiente de diseño',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space3),
                      Text(titulo, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: DesignTokens.space2),
                      Text(descripcion, style: theme.textTheme.bodyLarge),
                      if (requisitos.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.space4),
                        Wrap(
                          spacing: DesignTokens.space2,
                          runSpacing: DesignTokens.space2,
                          children: [
                            for (final r in requisitos)
                              Chip(
                                label: Text(r),
                                labelStyle: theme.textTheme.bodySmall,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (acciones.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space6),
                Text('Ir a', style: theme.textTheme.titleMedium),
                const SizedBox(height: DesignTokens.space3),
                for (final accion in acciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                    child: OutlinedButton(
                      onPressed: () => context.push(accion.ruta),
                      child: Text(accion.label),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
