@Tags(['golden'])
library;

import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:enam_app/features/auth/presentation/complete_profile_screen.dart';
import 'package:enam_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:enam_app/features/auth/presentation/login_screen.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/auth/presentation/reset_password_screen.dart';
import 'package:enam_app/features/auth/presentation/splash_screen.dart';
import 'package:enam_app/features/auth/presentation/verify_email_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_map_screen.dart';
import 'package:enam_app/features/duelo/presentation/elegir_oponente_screen.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:enam_app/features/stats/presentation/ranking_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_node_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '_comun.dart';

/// Banco de capturas de todas las pantallas, a los tres tamaños de referencia.
///
/// Por qué esto y no un simulador: recorrer las pantallas a mano en un
/// emulador cuesta minutos, RAM y calor, y no deja nada que revisar después.
/// Esto corre en segundos, sin dispositivo, y deja PNG que se pueden mirar y
/// comparar entre cambios.
///
/// Para **regenerar** las imágenes tras un cambio de diseño:
///
/// ```sh
/// flutter test --update-goldens test/golden
/// ```
///
/// Para **comprobar** que nada se movió sin querer:
///
/// ```sh
/// flutter test test/golden
/// ```
///
/// La tipografía es la real: Nunito va empaquetada como asset, así que estas
/// capturas se ven igual que la app.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await cargarFuentes();

    // El reloj, quieto. La tarjeta de racha pinta las iniciales de los últimos
    // siete días, así que sin esto una captura hecha un lunes deja de coincidir
    // el martes y el banco entero amanece en rojo sin que nadie haya tocado
    // nada. Un banco que siempre falla es un banco que nadie mira.
    congelarReloj(DateTime.utc(2026, 7, 30, 17));
  });

  tearDownAll(soltarReloj);

  const pantallas = <({String nombre, Widget widget})>[
    (nombre: '1.1-splash', widget: SplashScreen()),
    (nombre: '1.2-onboarding', widget: OnboardingScreen()),
    (nombre: '1.3-registro', widget: RegisterScreen()),
    // Con correo de muestra: sin él la pantalla se captura con el hueco vacío
    // y no se ve si el texto entra.
    (
      nombre: '1.4-verificacion',
      widget: VerifyEmailScreen(email: 'valeria.rojas@unmsm.edu.pe'),
    ),
    (nombre: '1.5-login', widget: LoginScreen()),
    (nombre: '1.6-recuperar', widget: ForgotPasswordScreen()),
    (nombre: '1.7-perfil', widget: CompleteProfileScreen()),
    (nombre: '1.8-nueva-contrasena', widget: ResetPasswordScreen(email: 'valeria.rojas@unmsm.edu.pe')),
    // El inicio es la pantalla con más piezas y donde antes se rompió el ancho:
    // las tarjetas de Temario y Marcadas quedaban en dos columnas de ~160 px y
    // los títulos salían como «Tem…» y «Marc…».
    (nombre: '2.1-inicio', widget: HomeScreen()),
    // El ranking: el podio arriba y la barra de posición propia abajo, que es
    // lo único que ve quien está fuera del top.
    (nombre: '6.2-ranking', widget: RankingScreen()),
    (nombre: '3.1-temario', widget: TemarioMapScreen()),
    (nombre: '3.2-area-medicina', widget: TemarioNodeScreen(nodeId: 'medicina')),
    (
      nombre: '3.3-area-gineco',
      widget: TemarioNodeScreen(nodeId: 'gineco-obstetricia'),
    ),
    // Modo duelo (M11). Se retrata «elegir oponente» porque es la única de las
    // suyas que se puede pintar sin un socket detrás — la partida y el
    // resultado dependen de lo que mande el servidor, y fingirlo aquí
    // retrataría un montaje, no la pantalla.
    (nombre: '7.1-duelo-oponente', widget: ElegirOponenteScreen()),
  ];

  for (final dispositivo in dispositivos) {
    group(dispositivo.nombre, () {
      for (final pantalla in pantallas) {
        for (final oscuro in [false, true]) {
          final tema = oscuro ? 'oscuro' : 'claro';

          testWidgets('${pantalla.nombre} · $tema', (tester) async {
            // El lienzo se fija aquí, no solo con MediaQuery: el `MediaQuery`
            // dice qué tamaño *cree* tener la app, pero la superficie donde se
            // pinta la sale de `view`. Sin esto todas las capturas salían del
            // tamaño por defecto del test, apaisadas y sin parecido con un
            // teléfono.
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = dispositivo.tamano * 2;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              Marco(
                tamano: dispositivo.tamano,
                oscuro: oscuro,
                child: pantalla.widget,
              ),
            );

            // Las animaciones en bucle nunca se asientan, así que se avanza un
            // tiempo fijo y se captura ahí. `pumpAndSettle` colgaría.
            //
            // Hacen falta tres, y cada uno resuelve una etapa distinta:
            //   1. vence la latencia simulada del repositorio y llegan datos,
            //   2. vencen los temporizadores del escalonado de entrada,
            //   3. se pinta el resultado ya asentado.
            // Con menos, las tarjetas a partir de la segunda salían en blanco:
            // ocupaban su sitio pero con opacidad 0.
            for (var i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 600));
            }

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '_imagenes/${dispositivo.nombre}/${pantalla.nombre}-$tema.png',
              ),
            );
          });
        }
      }
    });
  }
}

