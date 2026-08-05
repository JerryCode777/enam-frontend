import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:enam_app/features/duelo/presentation/widgets/resultado_del_duelo.dart';
import 'package:enam_app/features/duelo/presentation/widgets/sala_de_espera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las reglas del duelo diario gratuito, vistas desde la pantalla (RF-65).
///
/// Lo que se prueba es que **no se ofrezca lo que el servidor va a rechazar**.
/// El pase no da bot, no da revancha y no guarda revisión; dejar esos botones
/// puestos lleva al usuario a un error después de haber jugado bien.
void main() {
  Widget montar(Widget hijo) =>
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: hijo));

  const ficha = DueloDTO(
    id: 'duelo-1',
    estado: EstadoDuelo.esperando,
    origen: OrigenDuelo.aleatorio,
    esTuyo: true,
  );

  group('la oferta del bot en la sala de espera', () {
    testWidgets('con plan, el botón se puede pulsar', (tester) async {
      await tester.pumpWidget(
        montar(
          SalaDeEspera(
            duelo: ficha,
            sinRival: true,
            aceptandoBot: false,
            onAceptarBot: () {},
          ),
        ),
      );

      expect(find.text('Jugar contra el bot'), findsOneWidget);
      expect(find.text('Solo con plan'), findsNothing);
    });

    testWidgets('con el pase llega igual, apagada y diciendo por qué', (
      tester,
    ) async {
      // La primera versión NO se la mandaba, y era peor: se quedaba mirando una
      // pantalla de espera sin nada que hacer ni nada que leer. Enseñarla
      // apagada es el mejor momento que tiene el duelo para explicar qué se
      // gana pagando.
      await tester.pumpWidget(
        montar(
          SalaDeEspera(
            duelo: ficha,
            sinRival: true,
            botBloqueado: true,
            aceptandoBot: false,
            onAceptarBot: () {},
          ),
        ),
      );

      expect(find.text('Solo con plan'), findsOneWidget);
      expect(
        find.textContaining('sin esperar a que haya alguien'),
        findsOneWidget,
      );
    });

    testWidgets('seguir esperando nunca se bloquea', (tester) async {
      // Es lo que mantiene la cola llena, que era el punto de regalar el duelo.
      // Si además se le cerrara la espera, el pase no serviría para nada.
      await tester.pumpWidget(
        montar(
          SalaDeEspera(
            duelo: ficha,
            sinRival: true,
            botBloqueado: true,
            aceptandoBot: false,
            onAceptarBot: () {},
          ),
        ),
      );

      expect(find.textContaining('seguimos buscándote rival'), findsOneWidget);
    });
  });

  group('el resultado de un duelo jugado con el pase', () {
    ResultadoDelDuelo resultado({required bool conPase}) => ResultadoDelDuelo(
      resultado: FinalDeDuelo(
        desenlace: Desenlace.ganaste,
        tusAciertos: 7,
        rivalAciertos: 4,
        tuNota: 14,
        conPaseGratis: conPase,
        revision: conPase
            ? const []
            : const [PreguntaRevisada(orden: 1, enunciado: '¿Qué?')],
      ),
      rival: 'Luis',
      onRevancha: () {},
      onRevisar: () {},
      onOtroOponente: () {},
      onInicio: () {},
    );

    testWidgets('no ofrece revancha ni revisión', (tester) async {
      await tester.pumpWidget(montar(resultado(conPase: true)));

      expect(find.textContaining('Revancha'), findsNothing);
      expect(find.textContaining('Revisar'), findsNothing);
    });

    testWidgets('dice qué falta en vez de dejar un hueco', (tester) async {
      // Quitar dos botones y no poner nada deja una pantalla que parece rota. Y
      // lo que se dice es cierto: las explicaciones son exactamente lo que le
      // faltó a esta partida.
      await tester.pumpWidget(montar(resultado(conPase: true)));

      expect(
        find.textContaining('no se guarda la revisión'),
        findsOneWidget,
      );
    });

    testWidgets('el marcador y la nota se enseñan igual que a cualquiera', (
      tester,
    ) async {
      // Lo que se recorta es el material de estudio, no el duelo. Quien juega
      // gratis juega de verdad: ve quién ganó y con cuánto.
      await tester.pumpWidget(montar(resultado(conPase: true)));

      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(find.text('14.00'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('pagando siguen estando los dos botones', (tester) async {
      // El candado no puede habérselos llevado por delante a quien sí paga.
      await tester.pumpWidget(montar(resultado(conPase: false)));

      expect(find.textContaining('Revancha con Luis'), findsOneWidget);
      expect(find.textContaining('Revisar la'), findsOneWidget);
    });
  });
}
