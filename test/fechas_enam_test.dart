import 'package:enam_app/features/auth/presentation/complete_profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las fechas del ENAM que ofrece completar perfil son las que publica
/// ASPEFAM (aspefam.org.pe/enam), y nunca una que ya pasó.
void main() {
  test('el ordinario 2026 es el 22 de noviembre, no el 12 de diciembre', () {
    final fechas = fechasEnamPublicadas.map((f) => f.fecha);
    expect(fechas, contains(DateTime(2026, 11, 22)));
    expect(fechas, isNot(contains(DateTime(2026, 12, 12))));
  });

  test('sin fechas que ASPEFAM no publicó', () {
    // El extraordinario 2027 todavía no está publicado.
    expect(fechasEnamPublicadas.where((f) => f.fecha.year == 2027), isEmpty);
  });

  test('el mismo día del examen se ofrece; al día siguiente, no', () {
    expect(fechasEnamPorVenir(DateTime(2026, 11, 22, 20)), hasLength(1));
    expect(fechasEnamPorVenir(DateTime(2026, 11, 23)), isEmpty);
  });
}
