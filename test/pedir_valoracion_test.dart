import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/valoracion/pedir_valoracion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// En Play había una sola reseña, de 1★. Pedir la valoración en mal momento
/// baja la nota media, que es justo lo que se quería subir: las guardas son
/// la función entera.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final alta = DateTime(2026, 10, 1);
  final hoy = DateTime(2026, 10, 20);

  late _Tienda tienda;
  late _Analitica analitica;
  late PedirValoracion servicio;

  setUp(() {
    tienda = _Tienda();
    analitica = _Analitica();
    servicio = PedirValoracion(tienda: tienda, analitica: analitica);
  });

  Future<void> terminarSesiones(int n) async {
    for (var i = 0; i < n; i++) {
      await servicio.anotarSesionTerminada('s$i', ahora: alta);
    }
  }

  Future<bool> pedir({
    bool bueno = true,
    DateTime? cuenta,
    DateTime? ahora,
    MomentoDeValoracion momento = MomentoDeValoracion.practica,
  }) => servicio.siTocara(
    momento: momento,
    buenResultado: bueno,
    cuentaCreada: cuenta ?? alta,
    ahora: ahora ?? hoy,
  );

  test('con todo a favor se pide, se anota y se mide', () async {
    await terminarSesiones(3);

    expect(await pedir(momento: MomentoDeValoracion.examenPasado), isTrue);
    expect(tienda.peticiones, 1);
    expect(analitica.registrados, ['valoracion_pedida momento=examen_pasado']);
  });

  test('tras un mal resultado, nunca', () async {
    await terminarSesiones(5);

    expect(await pedir(bueno: false), isFalse);
    expect(tienda.peticiones, 0);
    expect(analitica.registrados, isEmpty);
  });

  test('con menos de tres sesiones terminadas, no', () async {
    await terminarSesiones(2);

    expect(await pedir(), isFalse);
    expect(tienda.peticiones, 0);
  });

  test('una sesión que se vuelve a abrir no cuenta dos veces', () async {
    for (var i = 0; i < 3; i++) {
      await servicio.anotarSesionTerminada('la-misma', ahora: alta);
    }

    expect(await pedir(), isFalse);
  });

  test('con la cuenta de menos de tres días, no', () async {
    await terminarSesiones(3);

    expect(await pedir(cuenta: hoy.subtract(const Duration(days: 2))), isFalse);
    expect(await pedir(cuenta: hoy.subtract(const Duration(days: 3))), isTrue);
  });

  test('sin la fecha de alta, cuenta desde la primera sesión vista', () async {
    await terminarSesiones(3); // la primera, el día del alta

    expect(
      await servicio.siTocara(
        momento: MomentoDeValoracion.practica,
        buenResultado: true,
        ahora: alta.add(const Duration(days: 2)),
      ),
      isFalse,
    );
    expect(
      await servicio.siTocara(
        momento: MomentoDeValoracion.practica,
        buenResultado: true,
        ahora: alta.add(const Duration(days: 3)),
      ),
      isTrue,
    );
  });

  test('una vez cada treinta días, aunque el sistema no enseñe nada', () async {
    await terminarSesiones(3);

    expect(await pedir(), isTrue);
    expect(await pedir(ahora: hoy.add(const Duration(days: 29))), isFalse);
    expect(await pedir(ahora: hoy.add(const Duration(days: 30))), isTrue);
    expect(tienda.peticiones, 2);
  });

  test('si la tienda no está disponible, no se pide ni se mide', () async {
    tienda.disponible = false;
    await terminarSesiones(3);

    expect(await pedir(), isFalse);
    expect(analitica.registrados, isEmpty);
  });

  test(
    '«Califica ENAM Prep» abre la ficha de la tienda, sin preguntar',
    () async {
      await servicio.abrirFicha();

      expect(tienda.fichaAbierta, '6797157623');
      expect(tienda.peticiones, 0);
    },
  );

  group('qué es un buen resultado', () {
    test('práctica: 70 % o más en 10 preguntas o más', () {
      expect(PedirValoracion.practicaBuena(correctas: 7, total: 10), isTrue);
      expect(PedirValoracion.practicaBuena(correctas: 6, total: 10), isFalse);
      // 4 de 4 es suerte, no una buena sesión.
      expect(PedirValoracion.practicaBuena(correctas: 9, total: 9), isFalse);
      expect(PedirValoracion.practicaBuena(correctas: 0, total: 0), isFalse);
    });

    test('simulacro o examen pasado: una nota que aprueba', () {
      expect(PedirValoracion.notaBuena(14), isTrue);
      expect(PedirValoracion.notaBuena(9), isFalse);
    });

    test('solo justo después: un resumen viejo del historial no', () {
      final ahora = DateTime(2026, 10, 20, 12);
      expect(
        recienTerminada(DateTime(2026, 10, 20, 11, 50), ahora: ahora),
        isTrue,
      );
      expect(recienTerminada(DateTime(2026, 10, 18), ahora: ahora), isFalse);
      expect(recienTerminada(null, ahora: ahora), isTrue);
    });
  });

  testWidgets('la pantalla de resultados la pide sin ningún diálogo propio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'valoracion_sesiones_terminadas': ['a', 'b'],
      'valoracion_desde_ms': DateTime(2026).millisecondsSinceEpoch,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pedirValoracionProvider.overrideWithValue(servicio),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: ValoracionAlAparecer(
            sessionId: 'c',
            momento: MomentoDeValoracion.practica,
            buenResultado: true,
            child: Text('Buena sesión'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(tienda.peticiones, 1);
    // Ni «¿te gusta la app?» ni nada antes del diálogo nativo.
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Buena sesión'), findsOneWidget);
  });
}

class _Tienda implements InAppReview {
  bool disponible = true;
  int peticiones = 0;
  String? fichaAbierta;

  @override
  Future<bool> isAvailable() async => disponible;

  @override
  Future<void> requestReview() async => peticiones++;

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async => fichaAbierta = appStoreId;
}

class _Analitica implements Analitica {
  final registrados = <String>[];

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      registrados.add(
        [
          evento.nombre,
          for (final p in propiedades.entries) '${p.key}=${p.value}',
        ].join(' '),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
