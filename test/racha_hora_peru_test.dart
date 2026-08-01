import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:flutter_test/flutter_test.dart';

/// La semana de la racha se etiqueta con el reloj de **Perú**, no con el del
/// dispositivo.
///
/// El servidor cuenta los días con `AT TIME ZONE 'America/Lima'`: recorta cada
/// respuesta a su día peruano antes de agrupar. Si el cliente calculara las
/// iniciales con la zona del sistema, bastaría abrir la app fuera de Perú —o
/// tenerla mal configurada— para que las letras se desplazaran un día respecto
/// a los círculos. El último círculo sería «hoy en Lima» y la última letra
/// diría otro día: se leería como una racha rota sin estarlo.
void main() {
  group('ahoraEnPeru', () {
    test('a medianoche UTC en Lima todavía es el día anterior', () {
      // 1 de agosto, 02:00 UTC = 31 de julio, 21:00 en Lima. Es la ventana
      // donde UTC y Perú discrepan de día, y la que rompe todo lo que cuente
      // en UTC.
      final enPeru = ahoraEnPeru(DateTime.utc(2026, 8, 1, 2));

      expect(enPeru.day, 31);
      expect(enPeru.month, 7);
    });

    test('el mismo instante da el mismo día mire quien lo mire', () {
      // Las tres son el MISMO instante, escrito desde tres husos distintos:
      // Lima (-5), Madrid (+2) y Tokio (+9). El resultado tiene que coincidir,
      // porque el día peruano no depende de dónde esté el teléfono.
      final instante = DateTime.utc(2026, 8, 1, 2);

      final desdeLima = ahoraEnPeru(instante.toLocal());
      final desdeUtc = ahoraEnPeru(instante);

      expect(desdeLima.day, desdeUtc.day);
      expect(desdeLima.weekday, desdeUtc.weekday);
    });
  });

  group('diaDeLaSemanaEnPeru', () {
    test('cero días atrás es hoy, en Perú', () {
      // 2026-08-01 02:00 UTC → en Lima es viernes 31 de julio.
      expect(diaDeLaSemanaEnPeru(0, DateTime.utc(2026, 8, 1, 2)), DateTime.friday);
    });

    test('retrocede un día de calendario por cada paso', () {
      final ahora = DateTime.utc(2026, 8, 1, 2); // viernes en Lima

      expect(diaDeLaSemanaEnPeru(1, ahora), DateTime.thursday);
      expect(diaDeLaSemanaEnPeru(2, ahora), DateTime.wednesday);
      expect(diaDeLaSemanaEnPeru(6, ahora), DateTime.saturday);
    });

    test('la semana de siete días no repite ningún día', () {
      final ahora = DateTime.utc(2026, 8, 1, 2);
      final semana = [for (var i = 6; i >= 0; i--) diaDeLaSemanaEnPeru(i, ahora)];

      expect(semana.toSet(), hasLength(7));
      // El último es hoy: es lo que fija el contrato del array `diasDeLaSemana`.
      expect(semana.last, diaDeLaSemanaEnPeru(0, ahora));
    });

    test('contarlo en UTC daría otro día, y por eso no se hace', () {
      final ahora = DateTime.utc(2026, 8, 1, 2);

      // En UTC ya es sábado; en Lima todavía es viernes. Si el widget usara el
      // reloj del sistema en un dispositivo puesto en UTC, pintaría toda la
      // fila corrida un día.
      expect(ahora.weekday, DateTime.saturday);
      expect(diaDeLaSemanaEnPeru(0, ahora), DateTime.friday);
    });
  });
}
