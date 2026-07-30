import 'package:enam_app/core/theme/motion.dart';
import 'package:enam_app/shared/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las animaciones tienen que desaparecer —no acortarse— cuando el sistema pide
/// reducir el movimiento. Hay gente a la que el movimiento le produce mareo, y
/// esta app se usa cansado.
void main() {
  Widget wrap(Widget child, {bool reducirMovimiento = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducirMovimiento),
      child: Scaffold(body: child),
    ),
  );

  group('Respeto por reduce-motion', () {
    testWidgets('FadeUp muestra el hijo de inmediato, sin opacidad', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const FadeUp(child: Text('hola')), reducirMovimiento: true),
      );

      expect(find.text('hola'), findsOneWidget);
      // Sin animación no debe envolver en Opacity ni desplazar.
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('FadeUp sí anima cuando el movimiento está permitido', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const FadeUp(child: Text('hola'))));
      await tester.pump();

      expect(find.byType(Opacity), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('hola'), findsOneWidget);
    });

    testWidgets('AnimatedNumber llega a su valor final', (tester) async {
      await tester.pumpWidget(wrap(const AnimatedNumber(value: 12.4)));
      await tester.pumpAndSettle();

      // Dos decimales: la escala vigesimal se lee "12.40" (RN-01).
      expect(find.text('12.40'), findsOneWidget);
    });

    testWidgets('AnimatedNumber sin animación muestra el valor de una', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AnimatedNumber(value: 20), reducirMovimiento: true),
      );
      await tester.pump();

      expect(find.text('20.00'), findsOneWidget);
    });

    testWidgets('Shimmer no aplica el degradado si hay que reducir', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const SkeletonBox(height: 40), reducirMovimiento: true),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('Motion.duration devuelve cero con reduce-motion', (
      tester,
    ) async {
      late Duration conReduccion;
      late Duration sinReduccion;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              conReduccion = Motion.duration(context, Motion.normal);
              return const SizedBox.shrink();
            },
          ),
          reducirMovimiento: true,
        ),
      );
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              sinReduccion = Motion.duration(context, Motion.normal);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(conReduccion, Duration.zero);
      expect(sinReduccion, Motion.normal);
    });
  });

  group('Escalonado', () {
    testWidgets('StaggeredColumn pinta todos sus hijos', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StaggeredColumn(
            spacing: 8,
            children: [Text('uno'), Text('dos'), Text('tres')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('uno'), findsOneWidget);
      expect(find.text('dos'), findsOneWidget);
      expect(find.text('tres'), findsOneWidget);
    });

    testWidgets('el escalonado se topa para que las listas largas no tarden', (
      tester,
    ) async {
      // Con 120 elementos sin tope, el último entraría a los 5,4 s.
      const ultimo = 119;
      final escalonReal =
          Motion.stagger * ultimo.clamp(0, Motion.maxStaggerIndex);
      final escalonSinTope = Motion.stagger * ultimo;

      expect(escalonReal, Motion.stagger * Motion.maxStaggerIndex);
      expect(escalonReal, lessThan(escalonSinTope));
      expect(escalonReal.inMilliseconds, lessThan(500));
    });
  });
}
