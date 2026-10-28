import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/analitica/analitica.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../domain/acceso.dart';
import 'access_ended_screen.dart';
import 'widgets/opciones_de_pago.dart';

/// El muro de venta del gratis limitado.
///
/// Sale **en el momento de intención**, nunca al entrar: cuando se acaban las
/// preguntas gratis del día o cuando se toca una función de pago. A diferencia
/// de «Acceso terminado», no encierra a nadie: se cierra y la app sigue
/// abierta, con lo gratis.
///
/// - **Primero qué hay detrás**, luego el botón. Quien toca un candado quiere
///   saber qué es antes de que le hablen de pagar (RP-02).
/// - **Sin ofertas.** El descuento es solo de la web, por las normas de las
///   tiendas; aquí no se muestra ni se menciona.
/// - **Compacto**: el encabezado, lo que incluye y los planes caben en una
///   pantalla de teléfono, con el botón de comprar a la vista sin desplazarse
///   (pedido de Jerry, 25/10/2026).
/// - El cobro, según la tienda, en [OpcionesDePago]: App Store en iPhone. En
///   Android la app no vende (política de pagos de Google Play): solo dice que
///   Premium va con la cuenta.
class MuroDeVentaScreen extends ConsumerStatefulWidget {
  const MuroDeVentaScreen({required this.motivo, super.key});

  final MotivoDeMuro motivo;

  @override
  ConsumerState<MuroDeVentaScreen> createState() => _MuroDeVentaScreenState();
}

class _MuroDeVentaScreenState extends ConsumerState<MuroDeVentaScreen> {
  @override
  void initState() {
    super.initState();
    // El muro es la pantalla de planes del gratis: reemplaza a «Acceso
    // terminado», y cuenta como ella hasta que el contrato tenga `muro_visto`.
    final analitica = ref.read(analiticaProvider)
      ..registrar(
        Evento.plansViewed,
        propiedades: {'pantalla': 'acceso_terminado'},
      );
    // El evento propio del muro (catálogo 6). `plans_viewed` sigue al lado
    // para no cortar la serie que BI ya tiene.
    analitica.registrar(
      Evento.muroVisto,
      propiedades: propiedadesDelMuro(widget.motivo),
    );
  }

  void _cerrar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quien compra aquí (App Store) no tiene por qué seguir mirando el muro.
    // Solo al pasar de gratis, o del día gratis, a un plan pagado: no en la
    // primera carga. El día gratis ya es `AccesoPremium`, así que lo que se
    // mira es que ahora haya un plan pagado.
    ref.listen(subscriptionProvider, (antes, s) {
      final antesSinPlan =
          antes?.value?.gratis != null || (antes?.value?.enPrueba ?? false);
      final ahora = s.value;
      if (antesSinPlan &&
          ahora?.acceso is AccesoPremium &&
          ahora!.planPagadoVigente) {
        _cerrar();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Listo: ya tienes Premium.')),
        );
      }
    });

    final sub = ref.watch(subscriptionProvider).value;
    final diaGratis = sub?.enPrueba ?? false;
    // El cupo, solo si lo manda el servidor: no se fija ningún número aquí.
    final porDia = sub?.gratis?.preguntasPorDia;

    final (icono, titular, bajada) = switch (widget.motivo) {
      CupoAgotado() => (
        Symbols.hourglass_bottom,
        porDia == null
            ? 'Se acabaron tus preguntas de hoy'
            : 'Se acabaron tus $porDia preguntas de hoy',
        '${porDia == null ? 'Mañana tienes más' : 'Mañana tienes $porDia más'}'
            '. Si no quieres esperar, con Premium sigues ahora, sin límite.',
      ),
      FuncionDePago(:final funcion) => (
        Symbols.lock,
        funcion.titulo,
        funcion.vistaPrevia,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Symbols.close),
          onPressed: _cerrar,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space5,
            0,
            DesignTokens.space5,
            DesignTokens.space5,
          ),
          children: [
            _Encabezado(icono: icono, titular: titular, bajada: bajada),
            const SizedBox(height: DesignTokens.space4),
            const _QueIncluye(),
            const SizedBox(height: DesignTokens.space3),
            _GratisSigue(porDia: porDia, diaGratis: diaGratis),
            const SizedBox(height: DesignTokens.space4),
            const OpcionesDePago(),
            const SizedBox(height: DesignTokens.space2),
            Center(
              child: TextButton(
                onPressed: _cerrar,
                child: Text(
                  'Ahora no',
                  style: TextStyle(color: context.scheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.icono,
    required this.titular,
    required this.bajada,
  });

  final IconData icono;
  final String titular;
  final String bajada;

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space2),
              decoration: BoxDecoration(
                color: info.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(icono, size: 22, fill: 1, color: info.onTint),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Text(
                titular,
                style: context.texts.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: DesignTokens.lineHeightTight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(bajada, style: context.texts.bodyMedium?.copyWith(height: 1.45)),
      ],
    );
  }
}

/// Lo que trae Premium, en cinco líneas. Las mismas en las dos tiendas: son
/// funciones, no precios.
class _QueIncluye extends StatelessWidget {
  const _QueIncluye();

  static const _lineas = [
    (Symbols.all_inclusive, 'Práctica sin límite, por área o por tema'),
    (Symbols.timer, 'Simulacros de 180 y exámenes pasados'),
    (Symbols.query_stats, 'Tu nota proyectada y tu acierto por área'),
    (Symbols.cloud_off, 'Estudiar sin conexión'),
    (Symbols.play_circle, 'Todos los cursos, con la práctica de cada clase'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CON PREMIUM',
            style: context.texts.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          for (final (icono, texto) in _lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space1 + 2),
              child: Row(
                children: [
                  Icon(icono, size: 18, color: scheme.primary),
                  const SizedBox(width: DesignTokens.space2 + 2),
                  Expanded(
                    child: Text(
                      texto,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Lo gratis no se pierde: dicho antes del botón, para que el muro no se lea
/// como un cierre.
///
/// En el día gratis se dice lo que ya tiene: todo menos los cursos completos.
/// Decirle «tu cuenta gratis sigue» y venderle lo que ya usa sería falso.
class _GratisSigue extends StatelessWidget {
  const _GratisSigue({required this.porDia, required this.diaGratis});

  /// El cupo que manda el servidor; `null` si no lo manda.
  final int? porDia;
  final bool diaGratis;

  @override
  Widget build(BuildContext context) {
    final success = context.states.success;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: success.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.check_circle, size: 18, fill: 1, color: success.onTint),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: Text(
              switch ((diaGratis, porDia)) {
                (true, _) =>
                  'Tu día gratis incluye práctica sin límite, simulacros y '
                      'estadísticas; los cursos completos son de Premium.',
                (false, final porDia?) =>
                  'Tu cuenta gratis sigue: $porDia preguntas al día con su '
                      'explicación, y tu avance guardado.',
                (false, null) =>
                  'Tu cuenta gratis sigue: preguntas cada día con su '
                      'explicación, y tu avance guardado.',
              },
              style: context.texts.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: success.onTint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Las propiedades de `muro_visto` para [motivo]. Sin oferta: la app no
/// muestra descuentos. Una función que el contrato no conoce (sin conexión,
/// otra) va sin `funcion`, y como ahí es obligatoria, el evento no se encola.
Map<String, String> propiedadesDelMuro(MotivoDeMuro motivo) => switch (motivo) {
  CupoAgotado() => {
    'motivo': 'limite',
    'recurso': 'preguntas',
    'con_oferta': 'false',
  },
  FuncionDePago(:final funcion) => {
    'motivo': 'funcion',
    'funcion': funcion.codigo,
    'con_oferta': 'false',
  },
};

/// La ruta del muro para [motivo].
String rutaDelMuro(MotivoDeMuro motivo) =>
    Uri(path: Routes.premium, queryParameters: motivo.consulta).toString();

/// Abre el muro.
///
/// Se invalida la suscripción antes: si llegó un `LIMITE_DIARIO`, el contador
/// del inicio tiene que bajar a lo que diga el servidor al volver.
void abrirMuro(BuildContext context, WidgetRef ref, MotivoDeMuro motivo) {
  ref.invalidate(subscriptionProvider);
  context.irA(rutaDelMuro(motivo));
}

/// Atiende un error de acceso del servidor, si lo es: los dos 403 del gratis
/// limitado van al muro, y el bloqueo del modelo anterior a «Acceso
/// terminado». Devuelve `true` si lo atendió; si no, el error es de otra cosa
/// y lo muestra quien llama.
bool atenderFaltaDeAcceso(BuildContext context, WidgetRef ref, Object error) {
  // Una versión que el servidor considera vieja (`ACTUALIZA_LA_APP`, hoy solo
  // las de antes de la 1.1.3): a la pantalla que la actualiza.
  if (error is ForbiddenFailure && error.code == 'ACTUALIZA_LA_APP') {
    context.irA(Routes.updateRequired);
    return true;
  }
  if (motivoDelMuro(error) case final motivo?) {
    abrirMuro(context, ref, motivo);
    return true;
  }
  if (error is ForbiddenFailure && error.requiereSuscripcion) {
    irAlPago(ref, context);
    return true;
  }
  return false;
}
