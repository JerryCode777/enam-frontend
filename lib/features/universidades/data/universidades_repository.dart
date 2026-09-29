import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/universidad.dart';

abstract interface class UniversidadesRepository {
  /// El catálogo completo, Medicina primero. Vacío si no hay red ni copia:
  /// entonces solo se puede elegir «Otra».
  Future<List<Universidad>> catalogo();
}

/// El catálogo del servidor, con copia en el teléfono.
///
/// Cambia poco (el servidor lo sirve con `max-age` de un día), así que se
/// guarda y se reutiliza un día. Sin red se usa la copia aunque sea más
/// vieja: una lista de ayer sirve igual para elegir universidad.
class ApiUniversidadesRepository implements UniversidadesRepository {
  ApiUniversidadesRepository(
    this._client, {
    CacheDeUniversidades? cache,
    DateTime Function()? reloj,
  }) : _cache = cache ?? CacheDeUniversidades(),
       _reloj = reloj ?? DateTime.now;

  final ApiClient _client;
  final CacheDeUniversidades _cache;
  final DateTime Function() _reloj;

  static const vigencia = Duration(days: 1);

  @override
  Future<List<Universidad>> catalogo() async {
    final copia = await _cache.leer();
    if (copia != null && _reloj().difference(copia.guardadoEn) < vigencia) {
      return copia.universidades;
    }

    try {
      final data = await _client.get<List<dynamic>>(ApiEndpoints.universidades);
      final lista = [
        for (final e in data.cast<Map<String, dynamic>>())
          Universidad.fromJson(e),
      ];
      await _cache.guardar(lista, _reloj());
      return lista;
    } catch (_) {
      // Sin red: la copia, por vieja que sea; y si no hay, solo «Otra».
      return copia?.universidades ?? const [];
    }
  }
}

/// La copia del catálogo en `shared_preferences`. No tiene datos de nadie.
class CacheDeUniversidades {
  static const _clave = 'catalogo.universidades.v1';

  Future<({List<Universidad> universidades, DateTime guardadoEn})?>
  leer() async {
    try {
      final crudo = (await SharedPreferences.getInstance()).getString(_clave);
      if (crudo == null) return null;
      final json = jsonDecode(crudo) as Map<String, dynamic>;
      return (
        universidades: [
          for (final e
              in (json['universidades'] as List).cast<Map<String, dynamic>>())
            Universidad.fromJson(e),
        ],
        guardadoEn: DateTime.parse(json['guardadoEn'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(List<Universidad> lista, DateTime cuando) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _clave,
        jsonEncode({
          'guardadoEn': cuando.toIso8601String(),
          'universidades': [for (final u in lista) u.toJson()],
        }),
      );
    } catch (_) {}
  }
}

/// Un catálogo corto para los datos de ejemplo, con los mismos ids que el
/// servidor.
class MockUniversidadesRepository implements UniversidadesRepository {
  static const catalogoDeEjemplo = [
    Universidad(
      id: 'unmsm',
      nombre: 'Universidad Nacional Mayor de San Marcos',
      siglas: 'UNMSM',
      region: 'Lima',
      gestion: 'publica',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'unsa',
      nombre: 'Universidad Nacional de San Agustín de Arequipa',
      siglas: 'UNSA',
      region: 'Arequipa',
      gestion: 'publica',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'upch',
      nombre: 'Universidad Peruana Cayetano Heredia',
      siglas: 'UPCH',
      region: 'Lima',
      gestion: 'privada',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'unt',
      nombre: 'Universidad Nacional de Trujillo',
      siglas: 'UNT',
      region: 'La Libertad',
      gestion: 'publica',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'usmp',
      nombre: 'Universidad de San Martín de Porres',
      siglas: 'USMP',
      region: 'Lima',
      gestion: 'privada',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'una',
      nombre: 'Universidad Nacional del Altiplano',
      siglas: 'UNA',
      region: 'Puno',
      gestion: 'publica',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'upao',
      nombre: 'Universidad Privada Antenor Orrego',
      siglas: 'UPAO',
      region: 'La Libertad',
      gestion: 'privada',
      medicina: true,
      licenciada: true,
    ),
    Universidad(
      id: 'pucp',
      nombre: 'Pontificia Universidad Católica del Perú',
      siglas: 'PUCP',
      region: 'Lima',
      gestion: 'privada',
      licenciada: true,
    ),
  ];

  @override
  Future<List<Universidad>> catalogo() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return catalogoDeEjemplo;
  }
}
