import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/version_de_la_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La versión instalada, antes de la primera petición: viaja en
  // `X-Version-App` y decide si hay que actualizar (ver `actualizacion.dart`).
  await VersionDeLaApp.cargar();

  // Sin esto, cualquier `DateFormat(..., 'es')` lanza LocaleDataException en
  // tiempo de ejecución: intl solo trae 'en_US' cargado por defecto. La app
  // formatea fechas en español en el inicio y en el calendario del examen.
  unawaited(initializeDateFormatting('es'));

  // La app se estudia en vertical. El simulacro en horizontal no aporta y
  // complicaría la grilla de 180 casillas (RF-17).
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );

  runApp(const ProviderScope(child: EnamApp()));
}
