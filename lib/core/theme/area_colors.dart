import 'package:flutter/material.dart';

/// Paleta categórica para las 10 áreas del blueprint.
///
/// Criterios:
/// - Tonos separados en el círculo cromático para que se distingan entre sí.
/// - Evita apoyar la distinción solo en rojo/verde (deuteranopía es el tipo de
///   daltonismo más común). Emergencias es el único rojo y no tiene un verde
///   adyacente en el orden de presentación.
/// - Cada área tiene variante clara y oscura, porque el mismo tono no cumple
///   contraste en ambos temas.
///
/// El color **nunca** debe ser el único portador de información: siempre va
/// acompañado del nombre del área o de una etiqueta.
abstract final class AreaColors {
  static const Map<String, ({Color light, Color dark})> _palette = {
    // Clínico Médicas
    'medicina': (light: Color(0xFF2563EB), dark: Color(0xFF60A5FA)), // azul
    'pediatria': (light: Color(0xFFD97706), dark: Color(0xFFFBBF24)), // ámbar
    'emergencias': (light: Color(0xFFDC2626), dark: Color(0xFFF87171)), // rojo

    // Clínico Quirúrgicas
    'gineco-obstetricia': (
      light: Color(0xFFDB2777),
      dark: Color(0xFFF472B6),
    ), // rosa
    'cirugia': (light: Color(0xFF7C3AED), dark: Color(0xFFA78BFA)), // violeta

    // Transversales
    'salud-publica': (light: Color(0xFF059669), dark: Color(0xFF34D399)), // verde
    'ciencias-basicas': (light: Color(0xFF0891B2), dark: Color(0xFF22D3EE)), // cian
    'etica': (light: Color(0xFF92400E), dark: Color(0xFFD6A75C)), // marrón
    'investigacion': (light: Color(0xFF4F46E5), dark: Color(0xFF818CF8)), // índigo
    'gestion': (light: Color(0xFF475569), dark: Color(0xFF94A3B8)), // pizarra
  };

  /// Color del área para el brillo dado.
  ///
  /// Devuelve un gris neutro si el backend manda un área desconocida, en vez de
  /// reventar: la app no debe caerse porque agregaron un área nueva.
  static Color of(String areaId, Brightness brightness) {
    final entry = _palette[areaId];
    if (entry == null) {
      return brightness == Brightness.light
          ? const Color(0xFF6B7280)
          : const Color(0xFF9CA3AF);
    }
    return brightness == Brightness.light ? entry.light : entry.dark;
  }

  /// Versión tenue del color del área, para fondos de chips y tarjetas.
  static Color subtleOf(String areaId, Brightness brightness) {
    final base = of(areaId, brightness);
    return base.withValues(alpha: brightness == Brightness.light ? 0.12 : 0.20);
  }

  /// Ayuda para tests: todos los ids que tienen color asignado.
  static Iterable<String> get knownAreaIds => _palette.keys;
}
