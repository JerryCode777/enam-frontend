import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../subscription/domain/acceso.dart';
import '../../subscription/presentation/muro_de_venta_screen.dart';

/// Si [error] es el 403 de una clase de pago (`FUNCION_PREMIUM`, con
/// `funcion: "cursos"`). Los endpoints del aula no dan otra función.
bool esClaseDePago(Object? error) =>
    error is ForbiddenFailure && error.code == 'FUNCION_PREMIUM';

/// El muro de los cursos: se abre al tocar una clase con candado, o cuando el
/// servidor responde que la clase es de pago.
///
/// Es el muro de venta de la app con la función `cursos`, el mismo que el de
/// las demás funciones de pago: en iPhone la compra con App Store y en Android
/// ninguna (ver `OpcionesDePago`).
Future<void> abrirMuroDeCursos(BuildContext context, WidgetRef ref) async =>
    abrirMuro(context, ref, const FuncionDePago(FuncionPremium.cursos));
