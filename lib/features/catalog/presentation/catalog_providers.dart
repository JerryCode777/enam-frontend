import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/taxonomy.dart';
import '../../../core/providers.dart';
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
final areasPorGrupoProvider =
    Provider<Map<AreaGroup, List<CatalogNode>>?>((ref) {
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

/// Texto de búsqueda del temario.
class CatalogSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final catalogSearchProvider =
    NotifierProvider<CatalogSearchNotifier, String>(CatalogSearchNotifier.new);

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
final prioridadEstudioProvider = Provider<List<({CatalogNode area, double score})>>(
  (ref) {
    final arbol = ref.watch(catalogProvider).value;
    if (arbol == null) return const [];

    final lista = <({CatalogNode area, double score})>[];

    for (final area in arbol) {
      final peso = (area.peso ?? 0) / 180;
      final acierto = area.porcentajeAcierto;

      // Sin datos se asume medio: no se puede afirmar que va mal, pero tampoco
      // conviene mandarla al final de la lista.
      final brecha = 1 - (acierto ?? 0.5);

      // La densidad modula: si un área rinde muchas preguntas por tema, el
      // esfuerzo se paga mejor. Se acota para que no domine el resultado.
      final densidad = area.temasPorPregunta ?? 2.0;
      final rendimiento = (2.0 / densidad).clamp(0.5, 2.0);

      lista.add((area: area, score: peso * brecha * rendimiento));
    }

    lista.sort((a, b) => b.score.compareTo(a.score));
    return lista;
  },
);
