import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/storage/base_local.dart';
import 'package:enam_app/features/catalog/data/catalog_repository.dart';
import 'package:enam_app/features/catalog/data/catalog_repository_offline.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/offline/data/almacen_offline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/offline.dart';

/// Sin el temario no se puede ni elegir qué practicar, así que su copia local
/// es lo que sostiene todo lo demás del modo sin conexión.
class _CatalogoFalso implements CatalogRepository {
  _CatalogoFalso();

  bool hayRed = true;
  int consultas = 0;

  List<CatalogNode> arbol = const [
    CatalogNode(
      id: 'medicina',
      nombre: 'Medicina',
      nivel: 'area',
      preguntasDisponibles: 120,
    ),
    CatalogNode(
      id: 'cirugia',
      nombre: 'Cirugía',
      nivel: 'area',
      preguntasDisponibles: 80,
    ),
  ];

  @override
  Future<List<CatalogNode>> tree() async {
    consultas++;
    if (!hayRed) throw const NetworkFailure();
    return arbol;
  }
}

void main() {
  late _CatalogoFalso servidor;
  late AlmacenOffline almacen;
  late BaseLocal base;
  late CatalogRepository repo;

  setUp(() {
    servidor = _CatalogoFalso();
    final piezas = almacenEnMemoria();
    almacen = piezas.almacen;
    base = piezas.base;

    repo = CatalogRepositoryConRespaldo(
      remoto: servidor,
      almacen: almacen,
      usuarioId: 'usuario-1',
    );
  });

  tearDown(() => base.cerrar());

  test('con red se pide al servidor y se guarda copia', () async {
    final arbol = await repo.tree();

    expect(arbol, hasLength(2));
    expect(await almacen.catalogo('usuario-1'), isNotNull);
  });

  test('sin red devuelve la copia guardada', () async {
    await repo.tree();
    servidor.hayRed = false;

    final arbol = await repo.tree();
    expect(arbol.map((a) => a.nombre), ['Medicina', 'Cirugía']);
    expect(
      arbol.first.preguntasDisponibles,
      120,
      reason: 'la copia guarda el árbol entero, no solo los nombres',
    );
  });

  test('sin red y sin copia, el error se propaga', () async {
    servidor.hayRed = false;

    // Es lo correcto: sin temario guardado no hay nada que enseñar, y fingir
    // una lista vacía haría creer que el temario está vacío.
    await expectLater(repo.tree(), throwsA(isA<NetworkFailure>()));
  });

  test('la copia se refresca en cada consulta con éxito', () async {
    await repo.tree();

    servidor.arbol = [
      ...servidor.arbol,
      const CatalogNode(
        id: 'pediatria',
        nombre: 'Pediatría',
        nivel: 'area',
        preguntasDisponibles: 60,
      ),
    ];
    await repo.tree();
    servidor.hayRed = false;

    expect(await repo.tree(), hasLength(3));
  });

  test('un error que no es de red no se tapa con la copia', () async {
    await repo.tree();

    // Si el servidor dice 403, enseñar la copia escondería que el plan venció.
    final conError = CatalogRepositoryConRespaldo(
      remoto: _CatalogoQueRechaza(),
      almacen: almacen,
      usuarioId: 'usuario-1',
    );

    await expectLater(conError.tree(), throwsA(isA<ForbiddenFailure>()));
  });

  test('la copia es de cada cuenta', () async {
    await repo.tree();

    final deOtro = CatalogRepositoryConRespaldo(
      remoto: servidor,
      almacen: almacen,
      usuarioId: 'usuario-2',
    );
    servidor.hayRed = false;

    await expectLater(deOtro.tree(), throwsA(isA<NetworkFailure>()));
  });
}

class _CatalogoQueRechaza implements CatalogRepository {
  @override
  Future<List<CatalogNode>> tree() async =>
      throw const ForbiddenFailure('Tu plan venció.');
}
