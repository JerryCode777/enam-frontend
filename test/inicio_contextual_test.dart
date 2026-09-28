import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ayuda/inicio.dart';
import 'ayuda/offline.dart';

/// El inicio pinta una siguiente acción distinta en cada estado (plan §5), y
/// nunca una cifra que no venga de los datos.
///
/// La regla en sí está en `siguiente_accion_test.dart`; esto comprueba que la
/// pantalla la usa y que el texto que ve la persona es el acordado con la web.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> montar(
    WidgetTester tester,
    EstadoInicio estado, {
    AlmacenEnMemoria? almacen,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesDeInicio(estado, almacen: almacen),
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  final esperado = <EstadoInicio, (String titulo, String boton)>{
    EstadoInicio.retomar: ('Continúa tu práctica', 'Retomar'),
    EstadoInicio.primeraPractica: ('Empieza con una práctica corta', 'Empezar'),
    EstadoInicio.areaPrioritaria: ('Practica Medicina', 'Practicar Medicina'),
    EstadoInicio.elegirArea: ('Elige un área para practicar', 'Elegir área'),
    EstadoInicio.sinConexion: ('Practica sin conexión', 'Ver lo descargado'),
  };

  for (final MapEntry(key: estado, value: (titulo, boton))
      in esperado.entries) {
    testWidgets('${estado.name}: «$titulo»', (tester) async {
      await montar(tester, estado);
      expect(find.text(titulo), findsOneWidget);
      expect(find.widgetWithText(FilledButton, boton), findsOneWidget);
    });
  }

  testWidgets('la acción principal cabe en el primer vistazo de 390 × 844', (
    tester,
  ) async {
    await montar(tester, EstadoInicio.areaPrioritaria);
    final boton = tester.getRect(
      find.widgetWithText(FilledButton, 'Practicar Medicina'),
    );
    expect(boton.bottom, lessThan(844));
  });

  testWidgets('el área prioritaria dice por qué, con datos reales', (
    tester,
  ) async {
    await montar(tester, EstadoInicio.areaPrioritaria);
    // Medicina: 62 de 120.
    expect(
      find.text('Pesa 40 preguntas en el ENAM y vas en 52 % de acierto.'),
      findsOneWidget,
    );
  });

  testWidgets('cargando: esqueleto, sin botones ni cifras', (tester) async {
    await montar(tester, EstadoInicio.cargando);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('ya no hay variación semanal inventada', (tester) async {
    await montar(tester, EstadoInicio.areaPrioritaria);
    await tester.scrollUntilVisible(find.text('Nota proyectada'), 200);
    expect(find.textContaining('esta semana'), findsNothing);
  });

  testWidgets('sin respuestas, la nota proyectada no aparece', (tester) async {
    await montar(tester, EstadoInicio.primeraPractica);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.text('Nota proyectada'), findsNothing);
  });

  testWidgets('lo respondido sin señal se anuncia, sin decir «sincronizado»', (
    tester,
  ) async {
    final almacen = AlmacenEnMemoria();
    for (final p in ['p1', 'p2']) {
      await almacen.encolar('u1', (
        sesionId: 's1',
        preguntaId: p,
        opcionId: 'a',
        tiempoMs: 1000,
        marcada: false,
        respondidaEn: DateTime(2026, 7, 30),
      ));
    }

    await montar(tester, EstadoInicio.sinConexion, almacen: almacen);

    expect(find.text('2 respuestas por enviar'), findsOneWidget);
    expect(find.textContaining('sincronizad'), findsNothing);
  });
}
