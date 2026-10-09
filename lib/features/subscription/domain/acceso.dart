import '../../../core/error/failure.dart';

/// Lo que la cuenta puede hacer hoy (gratis limitado, fase 1).
///
/// Llega dentro de `GET /subscription` como `acceso`. Es lo que manda en la
/// app: el `estado` de la suscripción sigue diciendo `expirada` cuando se
/// acaba la prueba, pero la app ya no se bloquea, queda en [AccesoGratis].
///
/// El contrato (`PLAN-GRATIS-LIMITADO.md`) todavía es una propuesta: si el
/// servidor no manda `acceso`, la suscripción queda con `acceso` nulo y la app
/// se comporta como antes (bloqueo al vencer la prueba, D-01).
sealed class Acceso {
  const Acceso();

  /// `null` si no viene o no se entiende: el servidor es anterior al gratis
  /// limitado.
  static Acceso? fromJson(Object? json) {
    if (json is! Map) return null;
    return switch (json['nivel']) {
      'premium' => const AccesoPremium(),
      'gratis' => AccesoGratis.fromJson(json['gratis']),
      _ => null,
    };
  }

  static Map<String, Object?>? toJson(Acceso? acceso) => switch (acceso) {
    null => null,
    AccesoPremium() => {'nivel': 'premium', 'gratis': null},
    final AccesoGratis g => {
      'nivel': 'gratis',
      'gratis': {
        'preguntasPorDia': g.preguntasPorDia,
        'restantesHoy': g.restantesHoy,
        'renuevaEn': g.renuevaEn?.toUtc().toIso8601String(),
      },
    },
  };
}

/// Todo abierto: la prueba en curso o un plan pagado.
final class AccesoPremium extends Acceso {
  const AccesoPremium();

  @override
  bool operator ==(Object other) => other is AccesoPremium;

  @override
  int get hashCode => (AccesoPremium).hashCode;
}

/// Gratis, para siempre: la app sigue abierta con un cupo de preguntas al día
/// (día de Lima) y sin las funciones de pago.
final class AccesoGratis extends Acceso {
  const AccesoGratis({
    required this.preguntasPorDia,
    required this.restantesHoy,
    this.renuevaEn,
  });

  /// Sin números se asume el cupo del plan y entero: el límite lo aplica el
  /// servidor, y un contador inventado a cero sería peor que uno optimista.
  factory AccesoGratis.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    final porDia = (m['preguntasPorDia'] as num?)?.toInt() ?? cupoPorDefecto;
    final restantes = (m['restantesHoy'] as num?)?.toInt() ?? porDia;
    return AccesoGratis(
      preguntasPorDia: porDia,
      restantesHoy: restantes.clamp(0, porDia),
      renuevaEn: DateTime.tryParse(m['renuevaEn'] as String? ?? ''),
    );
  }

  static const cupoPorDefecto = 10;

  final int preguntasPorDia;
  final int restantesHoy;

  /// La medianoche de Lima siguiente, cuando vuelve el cupo entero.
  final DateTime? renuevaEn;

  bool get agotado => restantesHoy <= 0;

  int get usadasHoy => preguntasPorDia - restantesHoy;

  @override
  bool operator ==(Object other) =>
      other is AccesoGratis &&
      other.preguntasPorDia == preguntasPorDia &&
      other.restantesHoy == restantesHoy &&
      other.renuevaEn == renuevaEn;

  @override
  int get hashCode => Object.hash(preguntasPorDia, restantesHoy, renuevaEn);
}

/// Una función que en gratis no está. El [codigo] es el `details.funcion` del
/// 403 `FUNCION_PREMIUM` (contrato confirmado el 05/10/2026), salvo
/// [estadisticas], que el servidor no restringe en la fase 1: el candado es
/// solo de la app.
enum FuncionPremium {
  simulacro(
    'simulacro',
    titulo: 'Los simulacros son Premium',
    vistaPrevia:
        '180 preguntas con cronómetro, como el día del examen, y al final tu '
        'nota por área.',
  ),
  examenPasado(
    'examen_pasado',
    titulo: 'Los exámenes pasados son Premium',
    vistaPrevia:
        'Los ENAM de años anteriores completos, en modo examen o en modo '
        'estudio con la explicación de cada pregunta.',
  ),
  simulacroNacional(
    'simulacro_nacional',
    titulo: 'El simulacro nacional es Premium',
    vistaPrevia:
        'Rinde el mismo simulacro que todo el país, a la misma hora, y mira '
        'tu puesto en el ranking.',
  ),
  practicaAMedida(
    'practica_a_medida',
    titulo: 'Elegir qué practicar es Premium',
    vistaPrevia:
        'Practica por área o por tema, elige cuántas preguntas y repasa solo '
        'las que no viste o las que fallaste.',
  ),
  estadisticas(
    'estadisticas',
    titulo: 'Tu nota y tus estadísticas son Premium',
    vistaPrevia:
        'Tu nota proyectada para el ENAM y tu acierto en cada área, para saber '
        'qué estudiar primero.',
  ),
  sinConexion(
    'sin_conexion',
    titulo: 'Estudiar sin conexión es Premium',
    vistaPrevia:
        'Descarga áreas completas y practica sin señal. Tus respuestas se '
        'envían al volver la conexión.',
  ),
  cursos(
    'cursos',
    titulo: 'Los cursos completos son de Premium',
    vistaPrevia:
        'Todas las clases de todo el temario, cada una con su práctica. Las '
        'clases gratis siguen abiertas.',
  ),
  otra(
    'otra',
    titulo: 'Esto es Premium',
    vistaPrevia: 'Con Premium tienes todo el banco y todas las funciones.',
  );

  const FuncionPremium(
    this.codigo, {
    required this.titulo,
    required this.vistaPrevia,
  });

  final String codigo;
  final String titulo;

  /// Qué hace, en una frase. Se enseña antes del botón: quien toca un candado
  /// quiere saber qué hay detrás antes de que le hablen de pagar.
  final String vistaPrevia;

  static FuncionPremium desdeCodigo(String? codigo) =>
      values.firstWhere((f) => f.codigo == codigo, orElse: () => otra);
}

/// Por qué se muestra el muro de venta.
sealed class MotivoDeMuro {
  const MotivoDeMuro();

  /// La parte de la ruta que lo describe: `motivo=limite` o
  /// `funcion=simulacro`.
  Map<String, String> get consulta;

  /// Lo contrario de [consulta]. `null` si no dice nada reconocible.
  static MotivoDeMuro? desdeConsulta(Map<String, String> q) {
    if (q['motivo'] == 'limite') return const CupoAgotado();
    if (q['funcion'] case final f?) {
      return FuncionDePago(FuncionPremium.desdeCodigo(f));
    }
    return null;
  }
}

/// Se acabaron las preguntas gratis de hoy.
final class CupoAgotado extends MotivoDeMuro {
  const CupoAgotado();

  @override
  Map<String, String> get consulta => const {'motivo': 'limite'};

  @override
  bool operator ==(Object other) => other is CupoAgotado;

  @override
  int get hashCode => (CupoAgotado).hashCode;
}

/// Se tocó una función de pago.
final class FuncionDePago extends MotivoDeMuro {
  const FuncionDePago(this.funcion);

  final FuncionPremium funcion;

  @override
  Map<String, String> get consulta => {'funcion': funcion.codigo};

  @override
  bool operator ==(Object other) =>
      other is FuncionDePago && other.funcion == funcion;

  @override
  int get hashCode => funcion.hashCode;
}

/// El muro que corresponde a un error del servidor, o `null` si no es uno de
/// los 403 del gratis limitado.
///
/// `LIMITE_DIARIO` y `FUNCION_PREMIUM` no son errores para quien los recibe:
/// son el momento de venderle, y se muestran como muro, nunca como error.
MotivoDeMuro? motivoDelMuro(Object error) {
  if (error is! ForbiddenFailure) return null;
  return switch (error.code) {
    'LIMITE_DIARIO' => const CupoAgotado(),
    'FUNCION_PREMIUM' => FuncionDePago(
      FuncionPremium.desdeCodigo(switch (error.details) {
        {'funcion': final String f} => f,
        _ => null,
      }),
    ),
    _ => null,
  };
}
