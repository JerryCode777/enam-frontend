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
/// - El cobro, según la tienda, en [OpcionesDePago]: App Store en iPhone y la
///   web en Android.
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
    ref
        .read(analiticaProvider)
        .registrar(
          Evento.plansViewed,
          propiedades: {'pantalla': 'acceso_terminado'},
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
    // Solo al pasar de gratis a premium: no en la primera carga.
    ref.listen(subscriptionProvider, (antes, s) {
      if (antes?.value?.gratis != null && s.value?.acceso is AccesoPremium) {
        _cerrar();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Listo: ya tienes Premium.')),
        );
      }
    });

    final gratis = ref.watch(subscriptionProvider).value?.gratis;
    final porDia = gratis?.preguntasPorDia ?? AccesoGratis.cupoPorDefecto;

    final (icono, titular, bajada) = switch (widget.motivo) {
      CupoAgotado() => (
        Symbols.hourglass_bottom,
        'Se acabaron tus $porDia preguntas de hoy',
        'Mañana tienes $porDia más. Si no quieres esperar, con Premium sigues '
            'ahora, sin límite.',
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
            DesignTokens.space6,
            0,
            DesignTokens.space6,
            DesignTokens.space6,
          ),
          children: [
            _Encabezado(icono: icono, titular: titular, bajada: bajada),
            const SizedBox(height: DesignTokens.space5),
            const _QueIncluye(),
            const SizedBox(height: DesignTokens.space4),
            _GratisSigue(porDia: porDia),
            const SizedBox(height: DesignTokens.space5),
            const OpcionesDePago(),
            const SizedBox(height: DesignTokens.space3),
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
        Container(
          padding: const EdgeInsets.all(DesignTokens.space3),
          decoration: BoxDecoration(
            color: info.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          child: Icon(icono, size: 28, fill: 1, color: info.onTint),
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

/// Lo que trae Premium, en cuatro líneas. Las mismas en las dos tiendas: son
/// funciones, no precios.
class _QueIncluye extends StatelessWidget {
  const _QueIncluye();

  static const _lineas = [
    (Symbols.all_inclusive, 'Práctica sin límite, por área o por tema'),
    (Symbols.timer, 'Simulacros de 180 y exámenes pasados'),
    (Symbols.query_stats, 'Tu nota proyectada y tu acierto por área'),
    (Symbols.cloud_off, 'Estudiar sin conexión'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
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
          const SizedBox(height: DesignTokens.space3),
          for (final (icono, texto) in _lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space2),
              child: Row(
                children: [
                  Icon(icono, size: 20, color: scheme.primary),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: Text(
                      texto,
                      style: context.texts.bodyMedium?.copyWith(
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
class _GratisSigue extends StatelessWidget {
  const _GratisSigue({required this.porDia});

  final int porDia;

  @override
  Widget build(BuildContext context) {
    final success = context.states.success;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: success.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.check_circle, size: 21, fill: 1, color: success.onTint),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Text(
              'Tu cuenta gratis sigue: $porDia preguntas al día con su '
              'explicación, y tu avance guardado.',
              style: context.texts.bodyMedium?.copyWith(
                height: 1.5,
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
