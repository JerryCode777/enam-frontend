import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analitica/analitica.dart';
import '../../../core/error/failure.dart';

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
/// persona vio fallar. Solo `metodo` y `motivo`: en el contrato, `pantalla`,
/// `navegador` y `dispositivo` son de la web, y con ellos el servidor rechaza
/// el evento entero.
void registrarFallo(
  WidgetRef ref, {
  required String metodo,
  required String motivo,
}) => ref
    .read(analiticaProvider)
    .registrar(
      Evento.registroFallido,
      propiedades: {'metodo': metodo, 'motivo': motivo},
    );
