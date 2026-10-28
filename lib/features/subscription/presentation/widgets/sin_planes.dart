import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/config/contacto.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../../../shared/widgets/state_banner.dart';

/// La tienda no dio ningún plan. No es un callejón sin salida: se puede
/// reintentar y escribirnos, y una persona ayuda.
///
/// **Nada de la web** (políticas de pago de Google Play y de App Store): ni
/// enlaces ni «paga en otro sitio». WhatsApp es ayuda, no un medio de pago.
class SinPlanes extends StatelessWidget {
  const SinPlanes({
    required this.tienda,
    required this.plataforma,
    required this.vacio,
    required this.onReintentar,
    super.key,
  });

  /// «Google Play» o «App Store».
  final String tienda;

  /// «Android» o «iPhone», para quien ayuda.
  final String plataforma;

  /// La tienda respondió sin planes. Si no, la consulta falló.
  final bool vacio;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StateBanner(
          kind: BannerKind.info,
          message: vacio
              ? 'Los planes no están disponibles en tu cuenta de $tienda en '
                    'este momento. Escríbenos y te ayudamos.'
              : 'No pudimos cargar los planes. Inténtalo de nuevo o '
                    'escríbenos y te ayudamos.',
        ),
        const SizedBox(height: DesignTokens.space3),
        EnamButton(
          label: 'Escríbenos por WhatsApp',
          icon: Symbols.chat,
          onPressed: () => unawaited(
            Contacto.abrir(
              Contacto.soporte(
                mensaje:
                    'Hola, en la app de ENAM Prep ($plataforma) no me '
                    'aparecen los planes de $tienda.',
              ),
            ),
          ),
        ),
        TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
      ],
    );
  }
}
