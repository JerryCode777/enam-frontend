/// Lo que se dice mientras se busca rival.
///
/// # Qué se está haciendo aquí, dicho sin adornos
///
/// Es la idea de Apple: no venden una cámara, venden ser fotógrafo. Aquí no se
/// vende un banco de preguntas: se vende **el médico que quiere ser** quien
/// está esperando, y ENAM Prep como la herramienta que lo lleva ahí.
///
/// Y funciona por una razón que conviene no perder de vista: la cámara del
/// iPhone **de verdad** es tan buena. La aspiración se sostiene porque hay algo
/// real debajo. Si prometes ser fotógrafo con una cámara mediocre, el usuario
/// lo descubre a la primera foto y ya no te cree nunca más.
///
/// Por eso **todos los mensajes de aquí abajo son verificables**. Ninguno dice
/// «serás el mejor médico del Perú»: dicen qué hay dentro de la app y qué
/// significa para quien estudia. Son hechos, contados desde su consecuencia.
///
/// La regla al añadir uno: **si no puedes señalar dónde está eso en el código o
/// en el temario, no va aquí.**
///
/// # Por qué hablan de TODA la app y no solo del duelo
///
/// Porque la sala de espera es de los pocos momentos en que el usuario está
/// mirando la pantalla sin nada que hacer, y casi nadie conoce la mitad de lo
/// que ha pagado. Es donde se puede contar que hay exámenes reales de años
/// anteriores, o que el simulacro reparte las 180 preguntas como las reparte
/// ASPEFAM, sin interrumpir a nadie para decírselo.
///
/// # Por qué se dicen justo aquí
///
/// La sala de espera es el punto donde más gente se va: todavía no ha invertido
/// nada en la partida, así que irse no cuesta nada. Treinta segundos mirando un
/// contador son largos; treinta segundos leyendo por qué lo que estás haciendo
/// importa, no.
library;

import 'dart:math';

class MensajeDeEspera {
  const MensajeDeEspera({required this.texto, required this.apoyo});

  /// La frase. Corta: se lee de un vistazo, no se estudia.
  final String texto;

  /// El dato que la sostiene. Es lo que la separa de un eslogan.
  final String apoyo;
}

/// Cuánto se queda cada mensaje en pantalla.
///
/// Cinco segundos, no dos. Un mensaje que se va antes de terminar de leerlo
/// genera lo contrario de lo que busca: la sensación de que te están pasando
/// cosas por delante mientras esperas.
const duracionDelMensaje = Duration(seconds: 5);

const mensajesDeEspera = <MensajeDeEspera>[
  // ---------- Lo que la app es ----------
  MensajeDeEspera(
    texto: 'El médico que quieres ser se decide ahora.',
    apoyo: 'No en el examen: en las horas de antes que nadie ve.',
  ),
  MensajeDeEspera(
    texto: 'Ya vas un paso adelante.',
    apoyo:
        'La mayoría estudia leyendo. Tú estás practicando con preguntas y con '
        'el reloj encima.',
  ),
  MensajeDeEspera(
    texto: 'No estudias a ciegas.',
    apoyo:
        'ENAM Prep te dice por dónde vas, qué área te falta y cuánto te queda.',
  ),

  // ---------- El temario y el banco ----------
  MensajeDeEspera(
    texto: 'El temario oficial, entero.',
    apoyo:
        'Las 10 áreas de ASPEFAM con sus 58 sub áreas, y el peso que cada una '
        'tiene en el examen.',
  ),
  MensajeDeEspera(
    texto: 'Las preguntas no son de relleno.',
    apoyo:
        'Un banco revisado una por una, y cada explicación escrita para '
        'entender el porqué.',
  ),

  // ---------- Simulacros y exámenes reales ----------
  MensajeDeEspera(
    texto: 'Puedes rendir el ENAM antes del ENAM.',
    apoyo:
        'Simulacro completo: 180 preguntas, 3 horas, y las áreas repartidas '
        'como las reparte ASPEFAM.',
  ),
  MensajeDeEspera(
    texto: 'Los exámenes reales de años anteriores.',
    apoyo:
        'Los ENAM que ya se rindieron, tal como fueron. Se pueden repetir las '
        'veces que quieras.',
  ),
  MensajeDeEspera(
    texto: 'Y compitiendo contra todo el país.',
    apoyo:
        'Los simulacros nacionales se rinden a la misma hora, con el mismo '
        'examen, y hay ranking.',
  ),

  // ---------- Cómo se estudia con ella ----------
  MensajeDeEspera(
    texto: 'Repasa justo lo que fallaste.',
    apoyo:
        'La práctica se arma con lo que aún no has visto, o solo con lo que te '
        'salió mal.',
  ),
  MensajeDeEspera(
    texto: 'Tu nota proyectada, al día.',
    apoyo:
        'Sale de lo que respondes, no de lo que crees. Y te dice qué área '
        'mover primero.',
  ),
  MensajeDeEspera(
    texto: 'Sin señal también.',
    apoyo:
        'Puedes practicar sin conexión, y lo que respondas se sincroniza al '
        'volver.',
  ),

  // ---------- El duelo, que es donde está el usuario ahora mismo ----------
  MensajeDeEspera(
    texto: 'El reloj no se detiene.',
    apoyo: 'En el ENAM tampoco. Aquí es donde te acostumbras a decidir rápido.',
  ),
  MensajeDeEspera(
    texto: 'Tiempo real de verdad.',
    apoyo:
        'Los dos reciben la misma pregunta en el mismo instante, y el '
        'cronómetro lo lleva el servidor.',
  ),
  MensajeDeEspera(
    texto: 'Saber no es lo mismo que responder.',
    apoyo:
        'Lo segundo se entrena bajo presión, y es lo que se mide el día del '
        'examen.',
  ),
  MensajeDeEspera(
    texto: 'Este duelo no te cuesta nada.',
    apoyo:
        'No toca tu nota ni tus estadísticas. Es para entrenar sin miedo a '
        'equivocarte.',
  ),
];

/// Los mensajes barajados, sin repetir dentro de una misma espera.
///
/// Repetir en treinta segundos se nota, y lo que se nota es que hay pocos: el
/// mensaje deja de leerse como algo que te dicen y pasa a leerse como relleno
/// girando.
List<MensajeDeEspera> barajarMensajes([Random? azar]) {
  final copia = [...mensajesDeEspera];
  copia.shuffle(azar ?? Random());
  return copia;
}
