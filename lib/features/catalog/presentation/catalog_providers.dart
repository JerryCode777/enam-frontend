import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/taxonomy.dart';
import '../../../core/providers.dart';
import '../../stats/domain/stats_models.dart';
import '../domain/catalog_models.dart';

/// Un nodo con su ruta desde el área, para las migas de pan.
typedef NodoConRuta = ({CatalogNode nodo, List<CatalogNode> ruta});

/// Busca un nodo por id en todo el árbol y devuelve su ruta.
///
/// La ruta importa: sin ella, alguien que llega a "Glaucoma" por búsqueda no
/// tiene forma de saber que vive dentro de Cirugía.
final nodoProvider = Provider.family<NodoConRuta?, String>((ref, id) {
  final arbol = ref.watch(catalogProvider).value;
  if (arbol == null) return null;

  for (final area in arbol) {
    final ruta = _rutaHasta(area, id);
    if (ruta != null) return (nodo: ruta.last, ruta: ruta);
  }
  return null;
});

List<CatalogNode>? _rutaHasta(CatalogNode nodo, String id) {
  if (nodo.id == id) return [nodo];
  for (final hijo in nodo.hijos) {
    final sub = _rutaHasta(hijo, id);
    if (sub != null) return [nodo, ...sub];
  }
  return null;
}

/// Las áreas agrupadas por grupo del blueprint, en el orden oficial.
final areasPorGrupoProvider = Provider<Map<AreaGroup, List<CatalogNode>>?>((
  ref,
) {
  final arbol = ref.watch(catalogProvider).value;
  if (arbol == null) return null;

  final porGrupo = <AreaGroup, List<CatalogNode>>{
    for (final g in AreaGroup.values) g: [],
  };

  for (final area in arbol) {
    // El grupo llega como etiqueta desde el servidor; se resuelve contra el
    // enum local para no depender del texto exacto en la UI.
    final grupo = AreaGroup.values.firstWhere(
      (g) => g.label == area.grupo,
      orElse: () => AreaGroup.transversales,
    );
    porGrupo[grupo]!.add(area);
  }
  return porGrupo;
});

/// Cuántas preguntas aporta cada grupo, **sumadas desde el árbol del servidor**.
///
/// No sale del enum local aunque ahí estén los valores oficiales: si ASPEFAM
/// cambia un peso y la base de datos se actualiza, la cabecera del grupo tiene
/// que cambiar con ella. Un total fijo en el código se contradiría en silencio
/// con las tarjetas que tiene debajo.
final totalesPorGrupoProvider =
    Provider<Map<AreaGroup, ({int preguntas, double porcentaje})>?>((ref) {
      final porGrupo = ref.watch(areasPorGrupoProvider);
      if (porGrupo == null) return null;

      final total = porGrupo.values
          .expand((areas) => areas)
          .fold(0, (suma, a) => suma + (a.peso ?? 0));

      return {
        for (final entrada in porGrupo.entries)
          entrada.key: (
            preguntas: entrada.value.fold(0, (s, a) => s + (a.peso ?? 0)),
            porcentaje: total == 0
                ? 0.0
                : entrada.value.fold(0, (s, a) => s + (a.peso ?? 0)) / total,
          ),
      };
    });

/// Texto de búsqueda del temario.
class CatalogSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final catalogSearchProvider = NotifierProvider<CatalogSearchNotifier, String>(
  CatalogSearchNotifier.new,
);

/// Resultados de búsqueda en los tres niveles (RF-41).
///
/// Devuelve cada coincidencia con su ruta completa, porque el caso que importa
/// es alguien buscando "glaucoma" y necesitando entender que está en Cirugía.
final catalogSearchResultsProvider = Provider<List<NodoConRuta>>((ref) {
  final query = ref.watch(catalogSearchProvider).trim().toLowerCase();
  final arbol = ref.watch(catalogProvider).value;

  if (query.length < 2 || arbol == null) return const [];

  final resultados = <NodoConRuta>[];

  void recorrer(CatalogNode nodo, List<CatalogNode> ruta) {
    final actual = [...ruta, nodo];
    if (_normalizar(nodo.nombre).contains(_normalizar(query))) {
      resultados.add((nodo: nodo, ruta: actual));
    }
    for (final hijo in nodo.hijos) {
      recorrer(hijo, actual);
    }
  }

  for (final area in arbol) {
    recorrer(area, const []);
  }

  // Los temas primero: quien busca "glaucoma" quiere el tema, no el área que lo
  // contiene. Después por nombre, para que el orden sea estable.
  resultados.sort((a, b) {
    final peso = _pesoNivel(a.nodo.nivel) - _pesoNivel(b.nodo.nivel);
    if (peso != 0) return peso;
    return a.nodo.nombre.compareTo(b.nodo.nombre);
  });

  return resultados;
});

int _pesoNivel(String nivel) => switch (nivel) {
  'tema' => 0,
  'sub_area' => 1,
  'bloque' => 2,
  _ => 3,
};

/// Quita acentos y pasa a minúsculas, para que "pediatria" encuentre
/// "Pediatría". Sin esto la búsqueda falla en casi todos los términos médicos.
String _normalizar(String s) {
  const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';

  final buffer = StringBuffer();
  for (final char in s.toLowerCase().split('')) {
    final i = conAcento.indexOf(char);
    buffer.write(i == -1 ? char : sinAcento[i]);
  }
  return buffer.toString();
}

/// Áreas ordenadas por dónde conviene invertir el tiempo.
///
/// Cruza tres cosas: cuánto pesa el área en el examen, cuánto le falta al
/// usuario para dominarla, y cuánto temario hay que cubrir por pregunta. Un área
/// grande donde va mal pesa más que una chica donde va peor.
final prioridadEstudioProvider =
    Provider<List<({CatalogNode area, double score, double? acierto})>>((ref) {
      final arbol = ref.watch(catalogProvider).value;
      if (arbol == null) return const [];

      // El progreso por área sale del dashboard y no del árbol.
      //
      // `GET /catalog/areas` responde hoy con el progreso en cero para todas
      // las áreas, aunque el usuario haya respondido: `GET /stats/dashboard`
      // devuelve 40 respondidas en Medicina y el catálogo, 0. Hasta que el
      // servidor lo pueble, tomar el acierto de ahí dejaba la lista entera en
      // "sin datos" y el orden salía del peso a secas.
      final porArea = {
        for (final a
            in ref.watch(dashboardProvider).value?.porArea ??
                const <AreaPerformance>[])
          a.areaId: a,
      };

      final lista = <({CatalogNode area, double score, double? acierto})>[];

      for (final area in arbol) {
        final peso = (area.peso ?? 0) / 180;
        final acierto =
            porArea[area.id]?.porcentajeAcierto ?? area.porcentajeAcierto;

        // Sin datos se asume medio: no se puede afirmar que va mal, pero tampoco
        // conviene mandarla al final de la lista.
        final brecha = 1 - (acierto ?? 0.5);

        // La densidad modula: si un área rinde muchas preguntas por tema, el
        // esfuerzo se paga mejor. Se acota para que no domine el resultado.
        final densidad = area.temasPorPregunta ?? 2.0;
        final rendimiento = (2.0 / densidad).clamp(0.5, 2.0);

        lista.add((
          area: area,
          score: peso * brecha * rendimiento,
          acierto: acierto,
        ));
      }

      lista.sort((a, b) => b.score.compareTo(a.score));
      return lista;
    });

/// Nombre y peso de un área, resueltos contra el árbol que mandó el servidor.
///
/// Existe para que ninguna pantalla tenga que consultar la tabla local: la
/// taxonomía y los pesos son dato de base de datos, y una copia en el código
/// se desactualiza en silencio el día que ASPEFAM cambie algo.
///
/// Devuelve `null` mientras el catálogo no ha cargado, y para ids que el
/// servidor no conoce.
final areaInfoProvider = Provider.family<({String nombre, int peso})?, String>((
  ref,
  areaId,
) {
  final arbol = ref.watch(catalogProvider).value;
  if (arbol == null) return null;

  for (final area in arbol) {
    if (area.id == areaId) {
      return (nombre: area.nombre, peso: area.peso ?? 0);
    }
  }
  return null;
});
