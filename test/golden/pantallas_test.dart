@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/presentation/complete_profile_screen.dart';
import 'package:enam_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:enam_app/features/auth/presentation/login_screen.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/auth/presentation/reset_password_screen.dart';
import 'package:enam_app/features/auth/presentation/splash_screen.dart';
import 'package:enam_app/features/auth/presentation/verify_email_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_map_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_node_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    await _cargarFuentes();
  });

  /// Tamaños lógicos de los tres dispositivos de referencia.
  const dispositivos = <({String nombre, Size tamano})>[
    // El más estrecho y el más bajo: aquí es donde se desborda primero.
    (nombre: 'iphone-13-mini', tamano: Size(375, 812)),
    (nombre: 'iphone-14-pro', tamano: Size(393, 852)),
    (nombre: 'iphone-17-pro-max', tamano: Size(440, 956)),
  ];

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
    (nombre: '1.8-nueva-contrasena', widget: ResetPasswordScreen(token: 'x')),
    (nombre: '3.1-temario', widget: TemarioMapScreen()),
    (nombre: '3.2-area-medicina', widget: TemarioNodeScreen(nodeId: 'medicina')),
    (
      nombre: '3.3-area-gineco',
      widget: TemarioNodeScreen(nodeId: 'gineco-obstetricia'),
    ),
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
              _Marco(
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

/// Monta una pantalla al tamaño exacto de un dispositivo.
class _Marco extends StatelessWidget {
  const _Marco({
    required this.tamano,
    required this.oscuro,
    required this.child,
  });

  final Size tamano;
  final bool oscuro;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        // El onboarding escribe en preferencias al salir; sin esto, el test
        // tocaría el almacenamiento real de la máquina.
        appPrefsProvider.overrideWithValue(_PrefsEnMemoria()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: tamano,
          // La muesca y el indicador de inicio del iPhone. Sin esto, el
          // contenido se dibujaría donde el sistema lo taparía.
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: oscuro ? AppTheme.dark : AppTheme.light,
          home: child,
        ),
      ),
    );
  }
}

/// Carga las fuentes que usa la app.
///
/// `flutter_test` no lee las fuentes del pubspec: sin esto el texto sale como
/// rectángulos y los iconos como cuadrados vacíos, y las capturas no sirven
/// para revisar nada.
Future<void> _cargarFuentes() async {
  Future<void> cargar(String familia, List<String> rutas) async {
    final cargador = FontLoader(familia);
    for (final ruta in rutas) {
      cargador.addFont(
        File(ruta).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await cargador.load();
  }

  await cargar('Nunito', [
    for (final peso in [400, 600, 700, 800, 900])
      'assets/fonts/Nunito-$peso.ttf',
  ]);

  // Los iconos vienen de un paquete, así que están en el caché de pub y no en
  // `assets/`. Y el nombre lleva el prefijo `packages/<paquete>/`: es como
  // Flutter registra las fuentes que no son de la app. Sin el prefijo el
  // registro funciona pero nadie lo encuentra, y los iconos salen como
  // cuadrados vacíos.
  final iconos = await _rutaSimbolos();
  if (iconos != null) {
    await cargar(
      'packages/material_symbols_icons/MaterialSymbolsOutlined',
      [iconos],
    );
  }
}

/// Ruta del `.ttf` de Material Symbols dentro del caché de pub.
///
/// Se resuelve desde `package_config.json` en vez de escribirla a mano: el
/// número de versión cambia en cada actualización, y una ruta fija se rompería
/// en silencio dejando las capturas llenas de cuadrados.
Future<String?> _rutaSimbolos() async {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;

  final paquetes =
      (jsonDecode(await config.readAsString())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;

  for (final p in paquetes.cast<Map<String, dynamic>>()) {
    if (p['name'] != 'material_symbols_icons') continue;
    // La barra final es obligatoria: sin ella, `resolve` trata el último
    // segmento como un archivo y lo reemplaza, dejando una ruta al padre.
    var texto = p['rootUri'] as String;
    if (!texto.endsWith('/')) texto = '$texto/';

    final raiz = Uri.parse(texto);
    final base = raiz.isAbsolute ? raiz : config.parent.uri.resolveUri(raiz);
    return base.resolve('lib/fonts/MaterialSymbolsOutlined.ttf').toFilePath();
  }
  return null;
}

class _PrefsEnMemoria implements AppPrefs {
  bool _visto = false;

  @override
  Future<bool> onboardingVisto() async => _visto;

  @override
  Future<void> marcarOnboardingVisto() async => _visto = true;

  @override
  Future<Set<String>> nacionalesInscritos() async => _nacionales;

  @override
  Future<void> marcarInscritoEnNacional(String id) async =>
      _nacionales.add(id);

  final _nacionales = <String>{};
}
