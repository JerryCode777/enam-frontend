/// La hora de Perú, que es la que manda en la racha.
///
/// El servidor cuenta los días de la racha en calendario **peruano**: recorta
/// cada respuesta a su día con `AT TIME ZONE 'America/Lima'` antes de agrupar,
/// porque contarlo en UTC movería la frontera del día a las 7 de la tarde de
/// Lima y partiría en dos una noche de estudio que nadie interrumpió.
///
/// El cliente tiene que etiquetar esa semana con el mismo reloj. Si las
/// iniciales salieran de `DateTime.now()` —la zona del dispositivo—, bastaría
/// abrir la app fuera de Perú, o tener mal puesta la zona del sistema, para que
/// las letras se desplazaran un día respecto a los círculos: el último círculo
/// sería «hoy en Lima» y la última letra diría otro día. Se leería como una
/// racha rota sin estarlo.
library;

/// Perú es UTC-5 todo el año: no tiene horario de verano.
///
/// Por eso basta un desfase fijo y se pueden restar días de 24 h exactas sin
/// caer en las dos madrugadas al año en que eso no valdría. Si algún día
/// cambiara, esto deja de ser una resta y pasa a necesitar una biblioteca de
/// zonas horarias.
const Duration desfasePeru = Duration(hours: 5);

/// El instante actual leído con el reloj de Lima.
///
/// Devuelve un `DateTime` en UTC cuyos campos —`year`, `weekday`, `day`— son
/// los que se verían en un reloj peruano. No es «la hora UTC»: es la hora de
/// Lima expresada de forma que `.weekday` responda lo correcto.
DateTime ahoraEnPeru([DateTime? ahora]) =>
    (ahora ?? DateTime.now()).toUtc().subtract(desfasePeru);

/// El día de la semana de hace [diasAtras] días en Perú. 1 = lunes, 7 = domingo.
int diaDeLaSemanaEnPeru(int diasAtras, [DateTime? ahora]) =>
    ahoraEnPeru(ahora).subtract(Duration(days: diasAtras)).weekday;
