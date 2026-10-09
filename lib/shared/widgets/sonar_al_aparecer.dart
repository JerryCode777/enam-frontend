import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sonido/proveedor_sonidos.dart';
import '../../core/sonido/sonidos.dart';

/// Hace sonar [sonido] **una vez**, cuando aparece.
///
/// Para las pantallas de resultado: el sonido acompaña la primera vez que se
/// ve la nota, no cada vez que la pantalla se reconstruye.
class SonarAlAparecer extends ConsumerStatefulWidget {
  const SonarAlAparecer({required this.sonido, required this.child, super.key});

  final Sonido sonido;
  final Widget child;

  @override
  ConsumerState<SonarAlAparecer> createState() => _SonarAlAparecerState();
}

class _SonarAlAparecerState extends ConsumerState<SonarAlAparecer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.sonar(widget.sonido);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
