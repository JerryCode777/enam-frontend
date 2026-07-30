import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';

/// Pantallas de sistema que no venían en el diseño.
///
/// Las tres tienen algo en común: el usuario **no puede hacer nada** para
/// resolverlas. Por eso el copy no pide una acción imposible ni culpa a la
/// conexión del usuario cuando el problema es nuestro.

/// Mantenimiento programado (RNF-03).
///
/// El SSD prohíbe ventanas de mantenimiento en fechas de simulacro nacional y en
/// las 4 semanas previas a un ENAM real, así que esta pantalla debería verse
/// poco. Cuando se vea, dice hasta cuándo.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({required this.hasta, super.key});

  /// Hasta cuándo dura, según `/system/maintenance`. `null` si no se sabe.
  final String? hasta;

  @override
  Widget build(BuildContext context) {
    return _Sistema(
      icono: Symbols.construction,
      color: context.states.warning,
      titulo: 'Estamos en mantenimiento',
      cuerpo: hasta == null
          ? 'Volvemos en un rato. Tu progreso está a salvo.'
          : 'Volvemos $hasta. Tu progreso está a salvo.',
      // Lo primero que piensa alguien al ver esto es si perdió su avance.
      extra: 'Si tenías un simulacro en curso, se retoma donde quedó.',
    );
  }
}

/// Versión mínima no soportada.
///
/// Ocurre cuando el contrato de la API cambió de forma incompatible. Es un
/// callejón sin salida a propósito: dejar entrar a una versión que va a fallar
/// en runtime es peor que bloquearla.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  static const _playStore =
      'https://play.google.com/store/apps/details?id=pe.jakstech.enam_app';

  @override
  Widget build(BuildContext context) {
    return _Sistema(
      icono: Symbols.system_update,
      color: context.states.info,
      titulo: 'Actualiza para continuar',
      cuerpo:
          'Esta versión de la app ya no es compatible. La actualización es '
          'rápida y no pierdes nada de tu progreso.',
      accion: ('Actualizar en Play Store', () async {
        final uri = Uri.parse(_playStore);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }),
    );
  }
}

/// Sin conexión y sin descargas disponibles (RF-31, RF-33).
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({this.onReintentar, super.key});

  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Sistema(
      icono: Symbols.cloud_off,
      color: context.states.info,
      titulo: 'Sin conexión',
      // No dice "revisa tu internet": puede ser nuestro servidor.
      cuerpo:
          'No pudimos conectar. Puedes seguir practicando con las áreas que '
          'tengas descargadas.',
      extra:
          'Los simulacros nacionales necesitan conexión y no funcionan con las '
          'descargas.',
      accion: onReintentar == null
          ? null
          : ('Reintentar', () async => onReintentar!()),
    );
  }
}

/// Cuerpo común de las tres. Mismo layout, distinto contenido.
class _Sistema extends StatelessWidget {
  const _Sistema({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.cuerpo,
    this.extra,
    this.accion,
  });

  final IconData icono;
  final StateColor color;
  final String titulo;
  final String cuerpo;
  final String? extra;
  final (String, Future<void> Function())? accion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.space8),
            child: FadeUp(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, size: 40, color: color.base),
                  ),
                  const SizedBox(height: DesignTokens.space5),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: context.texts.headlineMedium?.copyWith(
                      fontSize: DesignTokens.fontSize2xl - 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    cuerpo,
                    textAlign: TextAlign.center,
                    style: context.texts.bodyMedium?.copyWith(height: 1.55),
                  ),
                  if (extra != null) ...[
                    const SizedBox(height: DesignTokens.space4),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space3 + 1),
                      decoration: BoxDecoration(
                        color: context.scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd + 2,
                        ),
                      ),
                      child: Text(
                        extra!,
                        textAlign: TextAlign.center,
                        style: context.texts.bodySmall?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                  if (accion != null) ...[
                    const SizedBox(height: DesignTokens.space6),
                    EnamButton(
                      label: accion!.$1,
                      onPressed: () => accion!.$2(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
