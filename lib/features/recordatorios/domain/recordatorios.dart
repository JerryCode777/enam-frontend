/// Recordatorios locales (fase 1 de notificaciones): todo en el teléfono, sin
/// servidor ni llaves.
///
/// Lo que decide qué avisar y cuándo es una función pura, [planDeAvisos]: así
/// se prueba sin plugin, sin reloj y sin teléfono. El resto (pedir permiso,
/// programar en el sistema) solo ejecuta el plan.
///
/// Reglas (pedido de Jerry vía enamprep-3f, 28/10/2026):
/// - **Nada de ofertas ni precios** en un aviso local, y en Android nada de
///   pagar en la web.
/// - El permiso se pide **en contexto**, tras la primera sesión terminada y con
///   una pantalla propia antes; nunca al abrir la app, y nunca dos veces.
library;

/// Qué clase de aviso es. El código viaja en `notif_programada` y
/// `notif_abierta`.
enum TipoDeAviso {
  diario('diario'),

  /// «Tu cupo gratis se renovó», la mañana siguiente a topar el límite.
  cupo('cupo');

  const TipoDeAviso(this.codigo);

  final String codigo;
}

/// Qué texto llevó. Rota de un día a otro para que el aviso no sea ruido.
enum VarianteDeAviso {
  preguntas('preguntas'),
  racha('racha'),
  examen('examen'),
  cupo('cupo');

  const VarianteDeAviso(this.codigo);

  final String codigo;
}

/// Lo que la persona eligió.
class AjustesDeRecordatorio {
  const AjustesDeRecordatorio({
    this.activo = false,
    this.hora = horaPorDefecto,
    this.minuto = 0,
  });

  /// Las 8 de la noche: después de clases o del turno, antes de dormir.
  static const horaPorDefecto = 20;

  final bool activo;
  final int hora;
  final int minuto;

  AjustesDeRecordatorio copyWith({bool? activo, int? hora, int? minuto}) =>
      AjustesDeRecordatorio(
        activo: activo ?? this.activo,
        hora: hora ?? this.hora,
        minuto: minuto ?? this.minuto,
      );
}

/// Un aviso listo para programar.
class AvisoProgramado {
  const AvisoProgramado({
    required this.id,
    required this.cuando,
    required this.tipo,
    required this.variante,
    required this.titulo,
    required this.cuerpo,
  });

  /// Fijo por día ([idDiario] + 0…6) o por tipo ([idCupo]): reprogramar
  /// reemplaza en vez de duplicar.
  final int id;

  /// En la hora local del teléfono.
  final DateTime cuando;
  final TipoDeAviso tipo;
  final VarianteDeAviso variante;
  final String titulo;
  final String cuerpo;

  /// Lo que vuelve al tocarlo: `diario:preguntas`, `cupo:cupo`…
  String get payload => '${tipo.codigo}:${variante.codigo}';
}

const idDiario = 100;
const idCupo = 200;

/// Cuántos días por delante se programan. Se vuelve a calcular cada vez que se
/// abre la app o se termina una sesión, así que una semana basta y deja que el
/// texto rote con datos frescos (la racha, los días al examen).
const diasProgramados = 7;

/// Todos los ids que este módulo puede haber dejado programados.
final idsPropios = [
  for (var d = 0; d < diasProgramados; d++) idDiario + d,
  idCupo,
];

/// La hora a la que llega «tu cupo gratis se renovó»: por la mañana. El cupo
/// se renueva a medianoche de Lima, y las 9 locales caen después en los 13
/// países de la app.
const horaDelCupo = 9;

/// Qué avisos programar desde [ahora].
///
/// - Sin [AjustesDeRecordatorio.activo], ninguno: el de cupo también es un
///   recordatorio, y la persona dijo que no.
/// - Si ya practicó hoy ([ultimaPractica] es de hoy), hoy no se le recuerda.
/// - El día que llega el de cupo, no llega también el diario: uno al día.
List<AvisoProgramado> planDeAvisos({
  required DateTime ahora,
  required AjustesDeRecordatorio ajustes,
  DateTime? ultimaPractica,
  DateTime? cupoAgotadoEl,
  int? racha,
  DateTime? fechaExamen,
  int? preguntasGratis,
}) {
  if (!ajustes.activo) return const [];

  final hoy = _dia(ahora);
  final avisos = <AvisoProgramado>[];

  // El cupo: la mañana siguiente al día en que se topó, si ese día es hoy.
  DateTime? diaDelCupo;
  if (cupoAgotadoEl != null &&
      _dia(cupoAgotadoEl) == hoy &&
      preguntasGratis != null) {
    final manana = hoy.add(const Duration(days: 1));
    diaDelCupo = manana;
    avisos.add(
      AvisoProgramado(
        id: idCupo,
        cuando: manana.add(const Duration(hours: horaDelCupo)),
        tipo: TipoDeAviso.cupo,
        variante: VarianteDeAviso.cupo,
        titulo: 'Tu cupo gratis se renovó',
        cuerpo:
            'Ya tienes tus $preguntasGratis preguntas de hoy, con su '
            'explicación.',
      ),
    );
  }

  for (var d = 0; d < diasProgramados; d++) {
    final dia = hoy.add(Duration(days: d));
    final cuando = dia.add(
      Duration(hours: ajustes.hora, minutes: ajustes.minuto),
    );
    if (!cuando.isAfter(ahora)) continue;
    if (d == 0 && ultimaPractica != null && _dia(ultimaPractica) == hoy) {
      continue;
    }
    if (dia == diaDelCupo) continue;

    final (variante, titulo, cuerpo) = _texto(
      dia: dia,
      diasDesdeHoy: d,
      racha: racha,
      fechaExamen: fechaExamen,
      preguntasGratis: preguntasGratis,
    );
    avisos.add(
      AvisoProgramado(
        id: idDiario + d,
        cuando: cuando,
        tipo: TipoDeAviso.diario,
        variante: variante,
        titulo: titulo,
        cuerpo: cuerpo,
      ),
    );
  }
  return avisos;
}

/// El texto del día. Rota entre los que tienen sentido con lo que se sabe:
/// sin racha no se habla de racha, sin fecha de examen no hay cuenta atrás.
(VarianteDeAviso, String, String) _texto({
  required DateTime dia,
  required int diasDesdeHoy,
  int? racha,
  DateTime? fechaExamen,
  int? preguntasGratis,
}) {
  final faltan = fechaExamen == null
      ? null
      : _dia(fechaExamen).difference(dia).inDays;

  final opciones = <(VarianteDeAviso, String, String)>[
    (
      VarianteDeAviso.preguntas,
      preguntasGratis == null
          ? 'Tu práctica de hoy ya está lista'
          : 'Tus $preguntasGratis preguntas de hoy ya están listas',
      'Cada una con su explicación. Unos minutos y listo.',
    ),
    // La racha solo hoy y mañana: los días siguientes solo llegan si la app
    // no se abrió, y para entonces la racha ya se cortó. Mañana sin número,
    // que depende de si practica hoy.
    if (racha != null && racha >= 2 && diasDesdeHoy <= 1)
      (
        VarianteDeAviso.racha,
        'No pierdas tu racha',
        diasDesdeHoy == 0
            ? 'Llevas $racha días seguidos. Una práctica hoy la mantiene.'
            : 'Una práctica hoy mantiene tu racha.',
      ),
    if (faltan != null && faltan >= 1 && faltan <= 365)
      (
        VarianteDeAviso.examen,
        faltan == 1 ? 'Mañana es tu ENAM' : 'Faltan $faltan días para tu ENAM',
        faltan == 1
            ? 'Un repaso corto hoy, y a descansar.'
            : 'Unas preguntas hoy te acercan a tu meta.',
      ),
  ];

  // Por número de día: estable entre reprogramaciones del mismo día.
  final indice = dia.difference(DateTime(2026)).inDays.abs();
  return opciones[indice % opciones.length];
}

DateTime _dia(DateTime t) => DateTime(t.year, t.month, t.day);
