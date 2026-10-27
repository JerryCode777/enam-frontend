import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/features/subscription/data/google_play_iap_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Por qué Planes queda vacío en Android (catálogo 37).
void main() {
  test('el instalador, en tres clases', () {
    expect(instaladorDe('com.android.vending'), 'play');
    expect(instaladorDe('com.google.android.feedback'), 'play');
    expect(instaladorDe(null), 'ninguno');
    expect(instaladorDe(''), 'ninguno');
    expect(instaladorDe('com.google.android.packageinstaller'), 'otro');
  });

  test('solo viaja lo que se sabe', () {
    expect(const DiagnosticoDePlay().propiedades, isEmpty);
    expect(
      const DiagnosticoDePlay(
        pais: 'pe',
        productosTienda: 6,
        noEncontrados: 0,
        instalador: 'play',
      ).propiedades,
      {
        'pais_tienda': 'pe',
        'productos_tienda': '6',
        'no_encontrados': '0',
        'instalador': 'play',
      },
    );
  });

  test('los enteros viajan como número y fuera de rango no viajan', () {
    final limpias = propiedadesValidas(
      Evento.planesNoDisponibles,
      {
        'medio': 'google_play',
        'motivo': 'vacio',
        'productos_tienda': '0',
        'no_encontrados': '99',
        'pais_tienda': 'PE',
      },
      plataforma: 'android',
    );
    expect(limpias, {
      'medio': 'google_play',
      'motivo': 'vacio',
      'productos_tienda': 0,
    });
  });
}
