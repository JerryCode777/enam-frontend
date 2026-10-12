import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/domain/hora_peru.dart';
import '../../../../core/providers.dart';
import '../../../../shared/widgets/state_banner.dart';
import '../../domain/subscription_models.dart';

/// Lo que trae el día gratis, igual que en la web (`DIA_GRATIS_TRAE`).
const diaGratisTrae = 'práctica sin límite, simulacros y estadísticas';

/// Los cursos no vienen enteros con el día gratis (`DIA_GRATIS_CURSOS`).
const diaGratisCursos = 'En los cursos ves sus clases gratis.';

/// El texto del aviso para [sub] en el instante [ahora], o `null` si no está
/// en su día gratis o el día ya terminó. Los textos son los de
/// `AvisoDelDiaGratis.tsx` de la web.
String? textoDelDiaGratis(Subscription sub, DateTime ahora) {
  if (!sub.enPrueba) return null;
  final fin = sub.expira;
  // Sin fecha, el reloj aún no arrancó: arranca con la primera práctica.
  if (sub.pruebaSinEmpezar || fin == null) {
    return 'Tu día gratis empieza con tu primera práctica: 24 h de '
        '$diaGratisTrae. $diaGratisCursos';
  }
  final falta = fin.difference(ahora);
  if (falta <= Duration.zero) return null;
  return 'Tu día gratis: $diaGratisTrae. Te quedan ${restanteEnTexto(falta)}. '
      '$diaGratisCursos';
}

/// «23 h», o «45 min» en la última hora. Hacia arriba: nunca dice 0 mientras
/// quede. Como `restanteEnTexto` de la web.
String restanteEnTexto(Duration falta) {
  final minutos = (falta.inSeconds / 60).ceil();
  return minutos >= 60
      ? '${(minutos / 60).ceil()} h'
      : '${minutos < 1 ? 1 : minutos} min';
}

/// El día gratis de 24 h de una cuenta nueva (11/10/2026), en el inicio y en
/// el resultado de la práctica.
///
/// Dice lo que trae y lo que no, sin precios ni «Premium»: los cursos no se
/// abren enteros. El «Te quedan» se rehace cada minuto; al terminar se vuelve
/// a pedir la suscripción, que ya viene en gratis, y el aviso se va solo.
class AvisoDelDiaGratis extends ConsumerStatefulWidget {
  const AvisoDelDiaGratis({this.espacioArriba = 0, super.key});

  /// El espacio que lo separa de lo de arriba, solo cuando se muestra.
  final double espacioArriba;

  @override
  ConsumerState<AvisoDelDiaGratis> createState() => _AvisoDelDiaGratisState();
}

class _AvisoDelDiaGratisState extends ConsumerState<AvisoDelDiaGratis> {
  Timer? _reloj;

  /// El `expira` por el que ya se volvió a pedir la suscripción: si el
  /// servidor tardara en cerrarla, preguntar en cada vuelta sería un bucle.
  DateTime? _preguntadaPara;

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  /// Al minuto siguiente o justo al vencer, lo que llegue antes.
  void _programar(Duration falta) {
    _reloj?.cancel();
    const minuto = Duration(minutes: 1);
    _reloj = Timer(falta < minuto ? falta : minuto, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider).value;
    if (sub == null || !sub.enPrueba) return const SizedBox.shrink();

    final instante = ahora();
    final fin = sub.expira;
    final texto = textoDelDiaGratis(sub, instante);

    if (texto == null) {
      // Terminó: la suscripción ya viene en gratis.
      if (fin != null && _preguntadaPara != fin) {
        _preguntadaPara = fin;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.invalidate(subscriptionProvider);
        });
      }
      return const SizedBox.shrink();
    }
    if (fin != null && !sub.pruebaSinEmpezar) {
      _programar(fin.difference(instante));
    }

    return Padding(
      padding: EdgeInsets.only(top: widget.espacioArriba),
      child: StateBanner(
        kind: BannerKind.success,
        icon: Symbols.redeem,
        message: texto,
      ),
    );
  }
}
