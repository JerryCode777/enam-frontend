import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';

/// Términos de uso y política de datos personales.
///
/// **No venía en el diseño** pero es obligatoria: el registro enlaza a ambos
/// documentos, la Ley N.° 29733 de Protección de Datos Personales del Perú exige
/// informar el tratamiento de datos (RNF-06), y Play Store no publica una app
/// que recoja datos sin política de privacidad accesible.
///
/// El texto de abajo es un **borrador estructural**, no un documento legal
/// revisado. Antes de publicar tiene que pasar por alguien con criterio legal:
/// los plazos, la base legal del tratamiento y los datos del responsable son
/// afirmaciones que obligan a la empresa.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const _secciones = <({String titulo, List<String> parrafos})>[
    (
      titulo: 'Quién es responsable de tus datos',
      parrafos: [
        'ENAM Prep es operado por Jaks Tech SAC (RUC 20614811804), que actúa '
            'como responsable del tratamiento de tus datos personales.',
        'Para cualquier consulta sobre tus datos puedes escribirnos desde la '
            'sección de Ayuda de la app.',
      ],
    ),
    (
      titulo: 'Qué datos recogemos y para qué',
      parrafos: [
        'Datos de tu cuenta: correo, nombre, universidad, tu situación respecto '
            'al examen y la fecha objetivo. Sirven para identificarte, ajustar tu '
            'plan de estudio y mostrarte la cuenta regresiva.',
        'Datos de tu actividad: qué preguntas respondiste, si acertaste, cuánto '
            'tardaste y qué marcaste para repaso. Sin ellos no podríamos '
            'calcular tus estadísticas ni tu nota proyectada.',
        'Datos técnicos: modelo de dispositivo y versión de la app, para '
            'diagnosticar fallas.',
      ],
    ),
    (
      titulo: 'Con quién los compartimos',
      parrafos: [
        'Con Culqi, únicamente para procesar tus pagos. No almacenamos los '
            'datos de tu tarjeta en ningún momento.',
        'Con el proveedor de notificaciones, solo el identificador necesario '
            'para enviarte los avisos que hayas activado.',
        'No vendemos tus datos ni los cedemos para publicidad.',
      ],
    ),
    (
      titulo: 'Tus derechos',
      parrafos: [
        'Puedes acceder a tus datos, corregirlos, oponerte a su tratamiento y '
            'pedir su eliminación. La Ley N.° 29733 te reconoce estos derechos.',
        'La eliminación de tu cuenta está disponible directamente en Ajustes, '
            'sin tener que escribirnos.',
      ],
    ),
    (
      titulo: 'El ranking es opcional',
      parrafos: [
        'Aparecer en el ranking público es una opción que puedes apagar cuando '
            'quieras desde Ajustes. Si la apagas, tus notas siguen contando para '
            'tus estadísticas pero nadie más ve tu nombre.',
      ],
    ),
    (
      titulo: 'El contenido es nuestro',
      parrafos: [
        'Las preguntas, explicaciones e imágenes del banco son propiedad de '
            'Jaks Tech SAC. Tu suscripción te da acceso personal para estudiar, '
            'no derecho a copiarlas, redistribuirlas ni publicarlas.',
        'Las preguntas llevan una marca de agua con tu identificador para '
            'desalentar su difusión no autorizada.',
      ],
    ),
    (
      titulo: 'Sobre el ENAM',
      parrafos: [
        // Importante: evita que alguien nos atribuya carácter oficial.
        'ENAM Prep es una herramienta de estudio independiente. No tiene '
            'vínculo con ASPEFAM ni con ninguna entidad oficial, y no gestiona '
            'ni interviene en tu inscripción al examen.',
        'La nota proyectada es una estimación basada en tu práctica. No '
            'predice tu resultado real.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Términos y privacidad',
            subtitulo: 'Ley N.° 29733 · Protección de Datos Personales',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                for (var i = 0; i < _secciones.length; i++)
                  FadeUp(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: DesignTokens.space6,
                      ),
                      child: _Seccion(seccion: _secciones[i]),
                    ),
                  ),
                FadeUp(
                  index: _secciones.length,
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.space4),
                    decoration: BoxDecoration(
                      color: context.scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusLg,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Symbols.info,
                          size: 20,
                          color: context.scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: DesignTokens.space3),
                        Expanded(
                          child: Text(
                            'Si cambiamos algo importante de estos términos te '
                            'avisamos en la app antes de que entre en vigencia.',
                            style: context.texts.bodySmall?.copyWith(
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.seccion});

  final ({String titulo, List<String> parrafos}) seccion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          seccion.titulo,
          style: context.texts.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        for (final p in seccion.parrafos)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3),
            child: Text(
              p,
              // Interlineado holgado: es lectura larga, igual que los casos
              // clínicos.
              style: context.texts.bodyMedium?.copyWith(
                height: DesignTokens.lineHeightRelaxed,
              ),
            ),
          ),
      ],
    );
  }
}
