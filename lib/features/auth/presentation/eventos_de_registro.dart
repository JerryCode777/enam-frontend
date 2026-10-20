import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analitica/analitica.dart';
import '../../../core/error/failure.dart';

/// `celular` o `tableta`, como lo pide el contrato. Nunca el modelo del
/// teléfono: solo el tamaño de la pantalla.
String dispositivoDe(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600 ? 'tableta' : 'celular';

/// El `motivo` de `registro_fallido` para [error] (catálogo 19).
///
/// Lo que no es un [Failure] viene de Google o Apple antes de llegar al
/// servidor: es un error del proveedor.
String motivoDeFallo(Object error) => switch (error) {
  ValidationFailure(code: 'EMAIL_TAKEN') => 'correo_en_uso',
  ValidationFailure(code: 'CONSENT_REQUIRED') => 'terminos_sin_marcar',
  ValidationFailure() => 'validacion',
  UnauthorizedFailure() => 'datos_invalidos',
  NetworkFailure() || TimeoutFailure() => 'red',
  Failure() => 'otro',
  _ => 'proveedor_error',
};

/// Registra `registro_fallido`: un intento de registro o de entrar que la
/// persona vio fallar.
void registrarFallo(
  WidgetRef ref,
  BuildContext context, {
  required String metodo,
  required String pantalla,
  required String motivo,
}) => ref
    .read(analiticaProvider)
    .registrar(
      Evento.registroFallido,
      propiedades: {
        'metodo': metodo,
        'motivo': motivo,
        'pantalla': pantalla,
        'dispositivo': dispositivoDe(context),
      },
    );
