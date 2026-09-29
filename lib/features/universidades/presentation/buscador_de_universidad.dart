import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import '../domain/universidad.dart';
import 'universidades_providers.dart';

/// Abre el buscador y devuelve lo elegido, o `null` si se cerró sin elegir.
///
/// Sustituye a la lista fija de diez siglas: guardaba «UNMSM» donde la web
/// guardaba el nombre completo, y las estadísticas por universidad contaban
/// dos universidades donde había una. Ahora se elige del catálogo y se guarda
/// su id.
Future<EleccionDeUniversidad?> elegirUniversidad(
  BuildContext context, {
  String? idActual,
  String? nombreActual,
}) {
  return showModalBottomSheet<EleccionDeUniversidad>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.88,
      child: BuscadorDeUniversidad(
        idActual: idActual,
        nombreActual: nombreActual,
      ),
    ),
  );
}

class BuscadorDeUniversidad extends ConsumerStatefulWidget {
  const BuscadorDeUniversidad({this.idActual, this.nombreActual, super.key});

  final String? idActual;
  final String? nombreActual;

  @override
  ConsumerState<BuscadorDeUniversidad> createState() =>
      _BuscadorDeUniversidadState();
}

class _BuscadorDeUniversidadState extends ConsumerState<BuscadorDeUniversidad> {
  final _busqueda = TextEditingController();
  late final _otra = TextEditingController(
    text: widget.idActual == idOtraUniversidad ? widget.nombreActual : null,
  );

  /// Escribiendo el nombre de una que no está en la lista.
  late bool _escribiendoOtra = widget.idActual == idOtraUniversidad;

  @override
  void dispose() {
    _busqueda.dispose();
    _otra.dispose();
    super.dispose();
  }

  void _pasarAOtra() => setState(() {
    _escribiendoOtra = true;
    if (_otra.text.trim().isEmpty) _otra.text = _busqueda.text.trim();
  });

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(universidadesProvider);
    final abajo = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        abajo + DesignTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Tu universidad', style: context.texts.titleMedium),
          ),
          const SizedBox(height: DesignTokens.space3),
          Expanded(
            child: catalogo.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              // El repositorio no lanza: sin red devuelve la copia o nada.
              error: (_, _) => _otraConAviso(),
              data: (lista) => lista.isEmpty || _escribiendoOtra
                  ? _otraConAviso(sinLista: lista.isEmpty)
                  : _lista(lista),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lista(List<Universidad> catalogo) {
    final visibles = buscarUniversidades(catalogo, _busqueda.text);
    final conMedicina = visibles.where((u) => u.medicina).toList();
    final otras = visibles.where((u) => !u.medicina).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _busqueda,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Nombre o siglas',
            prefixIcon: Icon(Symbols.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DesignTokens.space2),
        Expanded(
          child: ListView(
            children: [
              if (conMedicina.isNotEmpty) ...[
                const _Encabezado('Con Medicina'),
                for (final u in conMedicina) _fila(u),
              ],
              if (otras.isNotEmpty) ...[
                const _Encabezado('Otras universidades'),
                for (final u in otras) _fila(u),
              ],
              if (visibles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: Text(
                    'No encontramos «${_busqueda.text.trim()}» en la lista.',
                    style: context.texts.bodyMedium,
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Symbols.edit),
                title: const Text('Mi universidad no está en la lista'),
                subtitle: const Text('Escribe su nombre'),
                onTap: _pasarAOtra,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fila(Universidad u) {
    final elegida = widget.idActual == u.id;
    return ListTile(
      title: Text(u.nombre),
      subtitle: Text(
        [?u.siglas, if (u.region.isNotEmpty) u.region].join(' · '),
      ),
      selected: elegida,
      trailing: elegida ? const Icon(Symbols.check) : null,
      onTap: () => Navigator.of(context).pop((id: u.id, nombre: u.nombre)),
    );
  }

  /// «Otra»: el nombre escrito. También lo único que queda sin red y sin copia
  /// del catálogo, para que nadie se quede sin poder completar su perfil.
  Widget _otraConAviso({bool sinLista = false}) {
    final texto = _otra.text.trim();
    final valido = texto.isNotEmpty && texto.length <= 120;

    return ListView(
      children: [
        if (sinLista) ...[
          Text(
            'No pudimos cargar la lista de universidades. Escribe el nombre '
            'de la tuya y lo ordenamos después.',
            style: context.texts.bodyMedium,
          ),
          TextButton.icon(
            onPressed: () => ref.invalidate(universidadesProvider),
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
          const SizedBox(height: DesignTokens.space2),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _escribiendoOtra = false),
              icon: const Icon(Symbols.arrow_back, size: 18),
              label: const Text('Volver a la lista'),
            ),
          ),
        TextField(
          controller: _otra,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de tu universidad',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DesignTokens.space3),
        EnamButton(
          label: 'Usar este nombre',
          onPressed: valido
              ? () => Navigator.of(
                  context,
                ).pop((id: idOtraUniversidad, nombre: texto))
              : null,
        ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space1,
      ),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          style: context.texts.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
