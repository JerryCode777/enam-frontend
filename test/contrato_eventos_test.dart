import 'dart:convert';
import 'dart:io';

import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/features/subscription/data/google_play_iap_service.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:enam_app/features/recordatorios/presentation/recordatorios_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cada evento que la app puede mandar, contra el contrato que valida el
/// servidor (20/10/2026).
///
/// El servidor rechaza el evento **entero** si trae una propiedad que no
/// declara, una que es de otra plataforma (`solo_en`), un valor fuera de su
/// tipo, o si falta una obligatoria (también las de `obligatoria_si`). La 1.1.2
/// estuvo a punto de salir mandando `dispositivo` y `pantalla` en el registro,
/// que en el contrato son solo de la web: se habrían perdido todos.
///
/// La copia del contrato es la del backend, que es la que manda en producción:
/// `test/fixtures/contrato_eventos_backend.json`. Para ponerla al día:
///
/// ```sh
/// git -C ../enam-backend fetch && git -C ../enam-backend show \
///   origin/main:internal/analitica/contrato/eventos.json \
///   > test/fixtures/contrato_eventos_backend.json
/// ```
void main() {
  final contrato =
      jsonDecode(
            File(
              'test/fixtures/contrato_eventos_backend.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final eventos = contrato['eventos'] as Map<String, dynamic>;
  final enumeraciones = contrato['enumeraciones'] as Map<String, dynamic>;
  final maxPropiedades =
      (contrato['limites'] as Map<String, dynamic>)['propiedades_por_evento']
          as int;

  Map<String, dynamic> defDe(Evento e) =>
      eventos[e.nombre] as Map<String, dynamic>;

  Map<String, dynamic> propsDe(Evento e) =>
      (defDe(e)['propiedades'] as Map<String, dynamic>? ?? const {});

  bool aplica(Map<String, dynamic> p, String plataforma) {
    final soloEn = p['solo_en'] as List<dynamic>?;
    return soloEn == null || soloEn.contains(plataforma);
  }

  Set<String> valoresDe(Map<String, dynamic> p) => {
    ...(p['valores'] as List<dynamic>? ??
            (enumeraciones[p['enumeracion']] as Map<String, dynamic>)['valores']
                as List<dynamic>)
        .cast<String>(),
  };

  bool seCumple(Map<String, dynamic>? regla, Map<String, dynamic> props) =>
      regla != null &&
      regla.isNotEmpty &&
      regla.entries.every(
        (r) => props.containsKey(r.key) && props[r.key] == r.value,
      );

  /// El validador del servidor (`validarPropiedades` de
  /// internal/analitica/validar.go): `null` si lo acepta, o el motivo.
  String? rechazo(Evento e, String plataforma, Map<String, dynamic> props) {
    final def = propsDe(e);
    if (props.length > maxPropiedades) return 'demasiadas';
    for (final k in props.keys) {
      if (!def.containsKey(k)) return 'desconocida: $k';
    }
    for (final MapEntry(key: nombre, value: valor) in def.entries) {
      final p = valor as Map<String, dynamic>;
      if (props.containsKey(nombre) || !aplica(p, plataforma)) continue;
      if (p['obligatoria'] == true ||
          seCumple(p['obligatoria_si'] as Map<String, dynamic>?, props)) {
        return 'falta: $nombre';
      }
    }
    for (final MapEntry(:key, :value) in props.entries) {
      final p = def[key] as Map<String, dynamic>;
      if (!aplica(p, plataforma)) return 'de otra plataforma: $key';
      if (seCumple(p['ausente_si'] as Map<String, dynamic>?, props)) {
        return 'debía faltar: $key';
      }
      final valido = switch (p['tipo']) {
        'enum' => value is String && valoresDe(p).contains(value),
        'booleano' => value is bool,
        'entero' =>
          value is int &&
              value >= (p['min'] as int) &&
              value <= (p['max'] as int),
        'codigo' =>
          value is String && RegExp(p['patron'] as String).hasMatch(value),
        _ => false,
      };
      if (!valido) return 'valor inválido: $key=$value';
    }
    return null;
  }

  group('Lo que declara la app está en el contrato', () {
    for (final e in Evento.values) {
      test(e.nombre, () {
        expect(eventos, contains(e.nombre), reason: 'no existe en el contrato');
        final def = defDe(e);
        expect(def['origen'], 'cliente');
        expect(
          (def['plataformas'] as List<dynamic>).toSet(),
          containsAll(plataformasDe[e]!),
        );

        final contratoProps = propsDe(e);
        final enviables = {
          ...propiedadesDe[e]!.keys,
          ...?booleanasDe[e],
          ...?codigosDe[e]?.keys,
          ...?enterasDe[e]?.keys,
        };
        for (final k in enviables) {
          expect(contratoProps, contains(k), reason: '$k no está declarada');
          final p = contratoProps[k] as Map<String, dynamic>;
          for (final plataforma in plataformasDe[e]!) {
            expect(
              aplica(p, plataforma),
              isTrue,
              reason: '$k es solo de ${p['solo_en']}, no de $plataforma',
            );
          }
          if (propiedadesDe[e]!.containsKey(k)) {
            expect(p['tipo'], 'enum', reason: k);
            expect(valoresDe(p), containsAll(propiedadesDe[e]![k]!));
          }
          if (booleanasDe[e]?.contains(k) ?? false) {
            expect(p['tipo'], 'booleano', reason: k);
          }
          if (enterasDe[e]?[k] case (final min, final max)) {
            expect(p['tipo'], 'entero', reason: k);
            expect((p['min'], p['max']), (min, max), reason: k);
          }
          if (codigosDe[e]?[k] case final patron?) {
            expect(p['tipo'], 'codigo', reason: k);
            expect(patron.pattern, p['patron'], reason: k);
          }
        }

        // Lo obligatorio en iOS y Android, la app lo exige antes de encolar.
        for (final MapEntry(:key, :value) in contratoProps.entries) {
          final p = value as Map<String, dynamic>;
          final enApp = plataformasDe[e]!.any((pl) => aplica(p, pl));
          if (p['obligatoria'] == true && enApp) {
            expect(obligatoriasDe[e], contains(key), reason: key);
          }
          if (enviables.contains(key)) {
            for (final (regla, enApp) in [
              ('obligatoria_si', obligatoriasSiDe[e]?[key]),
              ('ausente_si', ausentesSiDe[e]?[key]),
            ]) {
              final enContrato = p[regla] as Map<String, dynamic>?;
              expect(
                enApp == null ? null : {enApp.$1: enApp.$2},
                enContrato,
                reason: '$regla de $key',
              );
            }
          }
        }
      });
    }
  });

  group('Lo que la app produce lo acepta el servidor', () {
    /// Cada evento con las propiedades que de verdad salen de las pantallas.
    final casos = <(Evento, Map<String, String>)>[
      (Evento.signupStarted, {'metodo': 'correo'}),
      for (final pantalla in propiedadesDe[Evento.plansViewed]!['pantalla']!)
        (Evento.plansViewed, {'pantalla': pantalla}),
      for (final plan in propiedadesDe[Evento.checkoutStarted]!['plan_id']!)
        for (final medio in const ['apple', 'google_play'])
          (Evento.checkoutStarted, {'plan_id': plan, 'medio': medio}),
      for (final medio in const ['apple', 'google_play']) ...[
        (Evento.planesNoDisponibles, {'medio': medio, 'motivo': 'vacio'}),
        (
          Evento.planesNoDisponibles,
          {'medio': medio, 'motivo': 'error', 'codigo': 'billing_unavailable'},
        ),
        // Catálogo 37: con el diagnóstico de Play.
        (
          Evento.planesNoDisponibles,
          {
            'medio': medio,
            'motivo': 'vacio',
            ...const DiagnosticoDePlay(
              pais: 'pe',
              productosTienda: 0,
              noEncontrados: 3,
              instalador: 'play',
            ).propiedades,
          },
        ),
      ],
      for (final lugar in const ['aviso', 'fin_dia_gratis']) ...[
        (Evento.consentimientoVisto, {'lugar': lugar}),
        for (final r in const ['si', 'no', 'cerro'])
          (Evento.consentimientoRespuesta, {'lugar': lugar, 'respuesta': r}),
      ],
      (Evento.muroVisto, propiedadesDelMuro(const CupoAgotado())),
      for (final f in FuncionPremium.values)
        (Evento.muroVisto, propiedadesDelMuro(FuncionDePago(f))),
      for (final desde in const ['catalogo', 'enlace'])
        for (final curso in const ['medicina', 'gineco-obstetricia'])
          (Evento.cursoVisto, {'curso_id': curso, 'desde': desde}),
      (Evento.registroVisto, const {}),
      for (final metodo in const ['correo', 'google', 'apple'])
        for (final motivo in propiedadesDe[Evento.registroFallido]!['motivo']!)
          (Evento.registroFallido, {'metodo': metodo, 'motivo': motivo}),
      // Catálogo 38: las notificaciones locales, como las arma la app.
      for (final (respuesta, origen) in const [
        ('concedido', 'pre_pantalla'),
        ('denegado', 'pre_pantalla'),
        ('ahora_no', 'pre_pantalla'),
        ('concedido', 'ajustes'),
        ('denegado', 'ajustes'),
      ])
        (Evento.notifPermiso, {'respuesta': respuesta, 'origen': origen}),
      (Evento.notifProgramada, {'tipo': 'diario', 'hora': '20'}),
      (Evento.notifProgramada, {'tipo': 'cupo'}),
      for (final payload in const [
        'diario:preguntas',
        'diario:racha',
        'diario:examen',
        'cupo:cupo',
      ])
        (Evento.notifAbierta, propiedadesDeAbierta(payload)!),
    ];

    /// Funciones que el contrato no conoce: el muro no puede mandar
    /// `funcion`, que ahí es obligatoria, así que el evento no se encola.
    final sinEvento = {
      for (final f in FuncionPremium.values)
        if (!valoresDe(
          propsDe(Evento.muroVisto)['funcion'] as Map<String, dynamic>,
        ).contains(f.codigo))
          f.codigo,
    };

    for (final (evento, props) in casos) {
      for (final plataforma in plataformasDe[evento]!) {
        // La tienda de la otra plataforma no se prueba ahí: no se encola.
        final soloEn = soloEnPlataformaDe[evento]?['medio']?[props['medio']];
        if (soloEn != null && soloEn != plataforma) continue;
        test('${evento.nombre} $props en $plataforma', () {
          final limpias = propiedadesValidas(
            evento,
            props,
            plataforma: plataforma,
          );
          if (sinEvento.contains(props['funcion'])) {
            expect(limpias, isNull);
            return;
          }
          expect(limpias, isNotNull, reason: 'la app no lo encola');
          // Como viaja: JSON, con los booleanos como booleanos.
          final enviado =
              jsonDecode(jsonEncode(limpias)) as Map<String, dynamic>;
          expect(rechazo(evento, plataforma, enviado), isNull);
        });
      }
    }

    test('lo que antes se mandaba en el registro, el servidor lo rechaza', () {
      // La regresión: si vuelve, este test lo dice.
      expect(
        rechazo(Evento.registroVisto, 'android', {'dispositivo': 'celular'}),
        isNotNull,
      );
      expect(
        rechazo(Evento.registroFallido, 'ios', {
          'metodo': 'correo',
          'motivo': 'red',
          'pantalla': 'registro',
        }),
        isNotNull,
      );
    });
  });
}
