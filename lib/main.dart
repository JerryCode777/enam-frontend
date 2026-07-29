import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Sin esto, cualquier `DateFormat(..., 'es')` lanza LocaleDataException en
  // tiempo de ejecución: intl solo trae 'en_US' cargado por defecto. La app
  // formatea fechas en español en el inicio y en el calendario del examen.
  initializeDateFormatting('es');

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
