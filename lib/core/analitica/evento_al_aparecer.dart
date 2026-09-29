import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analitica.dart';

/// Registra [evento] **una vez**, cuando la pantalla aparece.
///
/// Para las vistas: una pantalla se reconstruye muchas veces, y cada
/// reconstrucción no es una visita.
class EventoAlAparecer extends ConsumerStatefulWidget {
  const EventoAlAparecer({
    required this.evento,
    required this.child,
    this.propiedades = const {},
    super.key,
  });

  final Evento evento;
  final Map<String, String> propiedades;
  final Widget child;

  @override
  ConsumerState<EventoAlAparecer> createState() => _EventoAlAparecerState();
}

class _EventoAlAparecerState extends ConsumerState<EventoAlAparecer> {
  @override
  void initState() {
    super.initState();
    ref
        .read(analiticaProvider)
        .registrar(widget.evento, propiedades: widget.propiedades);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
