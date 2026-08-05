import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import 'widgets/boton_duelo_gratis.dart';
import 'widgets/opciones_de_pago.dart';

/// Pantalla de bloqueo — se acabó el acceso (RN-03 v2, D-01).
///
/// **Reemplaza a la hoja inferior de la 4.6.** Aquella era "topaste el límite
/// de hoy": una interrupción sobre una pantalla que seguía siendo tuya. Esto es
/// otra cosa. Al vencer la prueba el usuario pierde la app entera, así que no
/// puede ser una hoja que se cierra: es a dónde lo manda el router hasta que
/// pague.
///
/// Reglas de tono, que son la parte que importa:
/// - **Se explica antes de ofrecer** (RP-02). Quien llega aquí estaba en medio
///   de otra cosa: si lo primero que ve es una lista de precios, se lee como un
///   cobro y no como una explicación.
/// - **Se promete que los datos siguen ahí** (RN-07). Con el modelo anterior
///   perder el acceso era perder un límite; ahora es perder la app. Que el
///   avance siga intacto es lo único que hace que valga la pena volver.
/// - **Nunca se acusa.** No se pierde nada por no haber pagado a tiempo.
class AccessEndedScreen extends ConsumerStatefulWidget {
  const AccessEndedScreen({super.key});

  @override
  ConsumerState<AccessEndedScreen> createState() => _AccessEndedScreenState();
}

class _AccessEndedScreenState extends ConsumerState<AccessEndedScreen> {
  /// La oferta llega después de la explicación (RP-02).
  bool _mostrarOferta = false;

  static const _esperaAntesDeOfrecer = Duration(milliseconds: 2200);

  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mostrarOferta || _timer != null) return;

    // Con el movimiento reducido no se hace esperar a nadie: se muestra todo de
    // una vez. La pausa es un recurso de ritmo, no información.
    if (Motion.reduced(context)) {
      _mostrarOferta = true;
      return;
    }
    _timer = Timer(_esperaAntesDeOfrecer, _revelar);
  }

  void _revelar() {
    _timer?.cancel();
    _timer = null;
    if (mounted && !_mostrarOferta) setState(() => _mostrarOferta = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suscripcion = ref.watch(subscriptionProvider).value;

    // La prueba y un plan pagado se acaban por motivos distintos, y a quien
    // pagó no se le habla como si nunca lo hubiera hecho.
    final vieneDePrueba = suscripcion?.plan.esGratuito ?? true;

    // En iOS la app no puede ofrecer la acción, así que tampoco la nombra:
    // decir "activa tu plan" donde no hay botón que lo haga es peor que no
    // decir nada.
    final (titular, bajada) = switch ((vieneDePrueba, enTiendaApple)) {
      (true, true) => (
        'Se acabó tu día de prueba',
        'Viste la app completa. Tu cuenta sigue activa y te espera donde la '
            'dejaste.',
      ),
      (true, false) => (
        'Se acabó tu día de prueba',
        'Viste la app completa. Para seguir donde lo dejaste, activa tu plan.',
      ),
      (false, true) => (
        'Tu plan terminó',
        'Se acabó la vigencia. Tu cuenta y tu avance siguen intactos.',
      ),
      (false, false) => (
        'Tu plan terminó',
        'Se acabó la vigencia. Renuévalo y sigues donde lo dejaste.',
      ),
    };

    return Scaffold(
      // Sin `AppBar`: no hay atrás al que volver. La salida es pagar o cerrar
      // sesión, y las dos están abajo.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space6),
          children: [
            const SizedBox(height: DesignTokens.space6),
            _Encabezado(titular: titular, bajada: bajada),
            const SizedBox(height: DesignTokens.space5),
            const _AvisoDatosIntactos(),
            const SizedBox(height: DesignTokens.space5),

            // El duelo gratis va DESPUÉS de la explicación y ANTES de los
            // precios, que es el sitio que le corresponde: no es lo que se
            // viene a hacer aquí, pero tampoco algo que haya que ir a buscar.
            // Si el pase está apagado no pinta nada.
            const BotonDueloGratis(),

            AnimatedSize(
              duration: Motion.duration(context, Motion.slow),
              curve: Motion.enter,
              alignment: Alignment.topCenter,
              child: _mostrarOferta
                  ? const _Oferta()
                  : _Esperando(onSaltar: _revelar),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.titular, required this.bajada});

  final String titular;
  final String bajada;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: DesignTokens.buttonGradient),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          child: const Icon(
            Symbols.workspace_premium,
            size: 30,
            fill: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          titular,
          style: context.texts.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: DesignTokens.lineHeightTight,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(bajada, style: context.texts.bodyLarge?.copyWith(height: 1.5)),
      ],
    );
  }
}

/// RN-07, dicho donde importa: el historial no se borra.
///
/// Es la única razón por la que alguien que dejó de pagar vuelve tres meses
/// después. Va **antes** de la oferta, no en la letra chica.
class _AvisoDatosIntactos extends StatelessWidget {
  const _AvisoDatosIntactos();

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: states.success.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.history, size: 21, fill: 1, color: states.success.onTint),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Text(
              'Tu avance está guardado. Las preguntas que respondiste, tus '
              'simulacros y tus estadísticas te esperan intactos.',
              style: context.texts.bodyMedium?.copyWith(
                height: 1.5,
                color: states.success.onTint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fase 1: solo la explicación, con salida inmediata para quien no quiera
/// esperar los dos segundos.
class _Esperando extends StatelessWidget {
  const _Esperando({required this.onSaltar});

  final VoidCallback onSaltar;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: TextButton(
        onPressed: onSaltar,
        child: Text(enTiendaApple ? 'Continuar' : 'Ver los planes'),
      ),
    );
  }
}

/// Fase 2: cómo volver a entrar.
///
/// El reparto por tienda vive en [OpcionesDePago] y no aquí: estaba resuelto
/// solo en esta pantalla, y por eso desde Ajustes se llegaba igual a los
/// precios y al formulario de tarjeta, en iPhone incluido.
class _Oferta extends ConsumerWidget {
  const _Oferta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OpcionesDePago(),
          const SizedBox(height: DesignTokens.space5),
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: Text(
                'Cerrar sesión',
                style: TextStyle(color: context.scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dónde va la app cuando el servidor responde `SUBSCRIPTION_REQUIRED`.
///
/// Se invalida la suscripción antes de navegar: si el 403 llegó porque la
/// prueba venció mientras el usuario practicaba, el estado en memoria todavía
/// dice que tiene acceso y el router lo devolvería al inicio.
void irAlPago(WidgetRef ref, BuildContext context) {
  ref.invalidate(subscriptionProvider);
  context.go(Routes.accessEnded);
}
