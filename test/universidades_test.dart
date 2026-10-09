import 'dart:convert';
import 'dart:io';

import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:enam_app/features/universidades/data/universidades_repository.dart';
import 'package:enam_app/features/universidades/domain/universidad.dart';
import 'package:enam_app/features/universidades/presentation/universidades_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El catálogo de universidades y lo que se guarda en el perfil.
///
/// `test/fixtures/universidades.json` es la respuesta real de
/// `GET /api/v1/catalog/universidades` (143 universidades, 42 con Medicina).
void main() {
  final catalogo = [
    for (final e
        in (jsonDecode(
                  File('test/fixtures/universidades.json').readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>())
      Universidad.fromJson(e),
  ];

  List<String> ids(String busqueda) =>
      buscarUniversidades(catalogo, busqueda).map((u) => u.id).toList();

  group('Búsqueda', () {
    test('el catálogo real: 143, con Medicina primero', () {
      expect(catalogo, hasLength(143));
      final medicina = catalogo.takeWhile((u) => u.medicina).length;
      expect(medicina, 42);
      expect(catalogo.skip(42).any((u) => u.medicina), isFalse);
    });

    test('por siglas, sin importar mayúsculas', () {
      expect(ids('UNMSM'), contains('unmsm'));
      expect(ids('unmsm'), contains('unmsm'));
    });

    test('por nombre, sin tildes y en cualquier orden', () {
      expect(ids('san agustin'), contains('unsa'));
      expect(ids('SAN AGUSTÍN'), contains('unsa'));
      expect(ids('marcos san'), contains('unmsm'));
      expect(ids('cayetano'), ['upch']);
    });

    test('las que no tienen siglas se encuentran por nombre', () {
      final sinSiglas = catalogo.firstWhere((u) => u.siglas == null);
      expect(
        ids(sinSiglas.nombre.split(' ').take(3).join(' ')),
        contains(sinSiglas.id),
      );
    });

    test('la búsqueda conserva Medicina primero', () {
      final res = buscarUniversidades(catalogo, 'nacional');
      final primeraSin = res.indexWhere((u) => !u.medicina);
      expect(res.skip(primeraSin).any((u) => u.medicina), isFalse);
    });
  });

  group('Lo que se muestra', () {
    test('por id, con el nombre del catálogo', () {
      expect(
        nombreDeUniversidad(catalogo, id: 'unmsm', texto: 'UNMSM'),
        'Universidad Nacional Mayor de San Marcos',
      );
    });

    test('sin catálogo o con «otra», el texto guardado', () {
      expect(nombreDeUniversidad(null, id: 'unmsm', texto: 'UNMSM'), 'UNMSM');
      expect(
        nombreDeUniversidad(catalogo, id: 'otra', texto: 'U. de Oxford'),
        'U. de Oxford',
      );
    });

    test('el ranking: nombre largo o siglas viejas, la misma etiqueta', () {
      expect(
        etiquetaCortaDeUniversidad(
          catalogo,
          'Universidad Nacional Mayor de San Marcos',
        ),
        'UNMSM',
      );
      expect(etiquetaCortaDeUniversidad(catalogo, 'UNMSM'), 'UNMSM');
      expect(
        etiquetaCortaDeUniversidad(catalogo, 'Universidad de Oxford'),
        'Universidad de Oxford',
      );
    });
  });

  group('Caché del catálogo', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    var reloj = DateTime(2026, 9, 29, 10);
    DateTime ahora() => reloj;

    test('con red, lo trae y lo guarda', () async {
      final cliente = _Cliente(catalogo);
      final repo = ApiUniversidadesRepository(cliente, reloj: ahora);

      expect(await repo.catalogo(), hasLength(143));
      expect(cliente.llamadas, 1);
    });

    test('dentro del día, no vuelve a pedirlo', () async {
      final cliente = _Cliente(catalogo);
      final repo = ApiUniversidadesRepository(cliente, reloj: ahora);
      await repo.catalogo();

      reloj = reloj.add(const Duration(hours: 5));
      await repo.catalogo();
      expect(cliente.llamadas, 1);
    });

    test('sin red, la copia aunque sea vieja', () async {
      final cliente = _Cliente(catalogo);
      final repo = ApiUniversidadesRepository(cliente, reloj: ahora);
      await repo.catalogo();

      reloj = reloj.add(const Duration(days: 3));
      cliente.sinRed = true;
      expect(await repo.catalogo(), hasLength(143));
    });

    test('sin red ni copia, vacío: solo se podrá elegir «Otra»', () async {
      final repo = ApiUniversidadesRepository(
        _Cliente(catalogo)..sinRed = true,
        reloj: ahora,
      );
      expect(await repo.catalogo(), isEmpty);
    });
  });

  group('Guardar en el perfil', () {
    test('una del catálogo: solo el id, nunca siglas', () async {
      final cliente = _Cliente(catalogo);
      await ApiAuthRepository(
        client: cliente,
        tokens: TokenStorage(),
      ).updateProfile(universidadId: 'unmsm', universidad: 'UNMSM');

      expect(cliente.enviado, {'universidadId': 'unmsm'});
    });

    test('«Otra»: el id y el nombre escrito', () async {
      final cliente = _Cliente(catalogo);
      await ApiAuthRepository(
        client: cliente,
        tokens: TokenStorage(),
      ).updateProfile(universidadId: 'otra', universidad: 'U. de Oxford');

      expect(cliente.enviado, {
        'universidadId': 'otra',
        'universidad': 'U. de Oxford',
      });
    });

    test('sin tocar la universidad, no se manda', () async {
      final cliente = _Cliente(catalogo);
      await ApiAuthRepository(
        client: cliente,
        tokens: TokenStorage(),
      ).updateProfile(nombre: 'Ana');

      expect(cliente.enviado, {'nombre': 'Ana'});
    });
  });
}

class _Cliente implements ApiClient {
  _Cliente(this._catalogo);

  final List<Universidad> _catalogo;
  int llamadas = 0;
  bool sinRed = false;
  Map<String, dynamic>? enviado;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? cancelToken,
    Object? onReceiveProgress,
  }) async {
    llamadas++;
    if (sinRed) throw Exception('sin red');
    return [for (final u in _catalogo) u.toJson()] as T;
  }

  @override
  Future<T> patch<T>(String path, {Object? data, Object? cancelToken}) async {
    enviado = Map<String, dynamic>.from(data! as Map);
    return <String, dynamic>{
          'id': 'u1',
          'email': 'a@b.pe',
          'nombre': 'Ana',
          'emailVerificado': true,
        }
        as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
