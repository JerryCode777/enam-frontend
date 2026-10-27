import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analitica/analitica.dart';
import '../../../../core/config/contacto.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../../../shared/widgets/state_banner.dart';
import '../../../consentimiento/data/consentimiento_repository.dart';
import '../../data/compras_apple_controller.dart'
    show EstadoCompra, ResultadoCompra;
import '../../data/compras_google_play_controller.dart';
import '../../data/fallo_de_tienda.dart';
import '../../data/google_play_iap_service.dart'
    show DiagnosticoDePlay, planIdDeGooglePlay;
import '../../domain/acceso.dart';
import '../../domain/subscription_models.dart';

/// Los planes, comprables con Google Play Billing. Solo en Android.
///
/// Compactos a propósito (pedido de Jerry, 25/10/2026): los tres planes en
/// filas que se eligen y **un solo** botón, para que quepan en una pantalla de
/// teléfono sin desplazarse. Con una tarjeta y un botón por plan había que
/// bajar mucho para ver el semestral.
///
/// El gemelo de `PlanesDeApple`: el precio sale de Play y nunca de un valor
/// nuestro, y la compra solo se da por terminada cuando el servidor la
/// registra (`ComprasGooglePlayController`).
///
/// Si Play no devuelve ningún plan —productos sin crear en Play Console, Play
/// Billing caído—, se dice que no se pudieron cargar y se mide
/// (`planes_no_disponibles`). **Nunca** se manda a pagar fuera de Play: la
/// política de pagos de Google Play lo prohíbe para contenido digital.
class PlanesDeGooglePlay extends ConsumerStatefulWidget {
  const PlanesDeGooglePlay({super.key});

  @override
  ConsumerState<PlanesDeGooglePlay> createState() => _PlanesDeGooglePlayState();
}

class _PlanesDeGooglePlayState extends ConsumerState<PlanesDeGooglePlay> {
  late final ComprasGooglePlayController _compras;
  StreamSubscription<ResultadoCompra>? _escucha;

  List<ProductDetails>? _productos;
  bool _fallo = false;

  /// `planes_no_disponibles` sale una vez por apertura: un reintento que
  /// vuelve a fallar no lo repite.
  bool _avisado = false;

  EstadoCompra _estado = EstadoCompra.quieto;
  String? _mensaje;

  /// El plan elegido. Arranca en el primero de Play (el mensual).
  String? _elegido;

  /// Si hay una compra en marcha, para el spinner del botón.
  bool _comprando = false;

  /// Si en esta apertura va la casilla de novedades: solo a quien no las
  /// aceptó. Se decide una vez, con los planes y la cuenta ya cargados, y no
  /// cambia al marcarla. `null`: todavía no se sabe.
  bool? _conNovedades;
  bool _novedades = false;
  bool _guardandoNovedades = false;

  @override
  void initState() {
    super.initState();
    _compras = ref.read(comprasGooglePlayControllerProvider);
    _compras.escuchar();
    _escucha = _compras.resultados.listen(_alCambiar);
    unawaited(_cargar());
  }

  @override
  void dispose() {
    unawaited(_escucha?.cancel());
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final productos = await _compras.productos();
      if (!mounted) return;
      setState(() => _productos = productos);
      if (productos.isEmpty) unawaited(_avisarNoDisponibles());
    } catch (e) {
      if (!mounted) return;
      setState(() => _fallo = true);
      unawaited(_avisarNoDisponibles(e));
    }
  }

  Future<void> _avisarNoDisponibles([Object? error]) async {
    if (_avisado) return;
    _avisado = true;
    // Con el diagnóstico: el país de Play, lo que devolvió y quién instaló la
    // app. Nunca lanza, y el evento sale aunque no se sepa nada.
    final analitica = ref.read(analiticaProvider);
    final diagnostico = await _compras.diagnostico().timeout(
      const Duration(seconds: 5),
      onTimeout: () => const DiagnosticoDePlay(),
    );
    registrarPlanesNoDisponibles(
      analitica,
      medio: 'google_play',
      error: error,
      diagnostico: diagnostico.propiedades,
    );
  }

  void _reintentar() {
    setState(() {
      _fallo = false;
      _productos = null;
    });
    unawaited(_cargar());
  }

  void _alCambiar(ResultadoCompra r) {
    if (!mounted) return;
    setState(() {
      _estado = r.estado;
      _mensaje = r.mensaje;
      if (r.estado != EstadoCompra.comprando &&
          r.estado != EstadoCompra.registrando) {
        _comprando = false;
      }
    });

    if (r.estado == EstadoCompra.listo) {
      // La suscripción cambió en el servidor: sin esto la guarda seguiría
      // creyendo que no hay acceso.
      ref.invalidate(subscriptionProvider);
    }
  }

  void _registrarNovedades(Evento evento, [String? respuesta]) => ref
      .read(analiticaProvider)
      .registrar(
        evento,
        propiedades: {'lugar': 'planes', 'respuesta': ?respuesta},
      );

  Future<void> _cambiarNovedades(bool acepta) async {
    // Al tocar, antes del PATCH: «si» al marcar, «no» al desmarcar.
    _registrarNovedades(Evento.consentimientoRespuesta, acepta ? 'si' : 'no');
    final mensajero = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _novedades = acepta;
      _guardandoNovedades = true;
    });
    try {
      final actualizado = await ref
          .read(consentimientoRepositoryProvider)
          .decidir(acepta: acepta, origen: OrigenConsentimiento.planes);
      ref.read(authControllerProvider.notifier).setUser(actualizado);
    } on Object {
      // La casilla vuelve a lo guardado: marcada sin guardar engañaría.
      if (mounted) setState(() => _novedades = !acepta);
      mensajero?.showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos guardar tu preferencia. Revisa tu conexión e '
            'inténtalo otra vez.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardandoNovedades = false);
    }
  }

  bool get _ocupado =>
      _estado == EstadoCompra.comprando || _estado == EstadoCompra.registrando;

  void _comprar(ProductDetails p, String cuentaId) {
    setState(() => _comprando = true);
    if (planIdDeGooglePlay(p.id) case final plan?) {
      ref
          .read(analiticaProvider)
          .registrar(
            Evento.checkoutStarted,
            propiedades: {'plan_id': plan, 'medio': 'google_play'},
          );
    }
    unawaited(_compras.comprar(p, cuentaId: cuentaId));
  }

  @override
  Widget build(BuildContext context) {
    // Quien ya pagó no tiene por qué ver precios: pagaría dos veces. La prueba
    // en curso sí puede comprar (la compra la reemplaza).
    final sub = ref.watch(subscriptionProvider).value;
    if (sub != null && _yaTienePremium(sub)) {
      return const StateBanner(
        kind: BannerKind.success,
        message: 'Ya tienes Premium.',
      );
    }

    final productos = _productos;
    if (_fallo || (productos != null && productos.isEmpty)) {
      return _SinPlanes(vacio: !_fallo, onReintentar: _reintentar);
    }
    if (productos == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.space6),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final elegido = productos.firstWhere(
      (p) => p.id == _elegido,
      orElse: () => productos.first,
    );

    final user = ref.watch(currentUserProvider);
    final cuentaId = user?.id;
    if (_conNovedades == null && user != null) {
      _conNovedades = user.aceptaComerciales != true;
      // Uno por apertura en la que se ve la casilla (catálogo 34).
      if (_conNovedades!) _registrarNovedades(Evento.consentimientoVisto);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mensaje case final m?) ...[
          StateBanner(
            // Cuando el dinero ya salió, el aviso NO es un error rojo.
            kind: _estado == EstadoCompra.error
                ? BannerKind.warning
                : BannerKind.info,
            message: m,
          ),
          const SizedBox(height: DesignTokens.space3),
        ],

        for (final p in productos) ...[
          _FilaPlan(
            producto: p,
            elegido: p.id == elegido.id,
            onTap: _ocupado ? null : () => setState(() => _elegido = p.id),
          ),
          const SizedBox(height: DesignTokens.space2),
        ],
        const SizedBox(height: DesignTokens.space1),
        EnamButton(
          label: 'Suscribirme',
          loading: _comprando,
          onPressed: _ocupado || cuentaId == null
              ? null
              : () => _comprar(elegido, cuentaId),
        ),
        const SizedBox(height: DesignTokens.space2),

        if (_conNovedades ?? false) ...[
          _CasillaDeNovedades(
            value: _novedades,
            onChanged: _guardandoNovedades
                ? null
                : (v) => unawaited(_cambiarNovedades(v)),
          ),
          const SizedBox(height: DesignTokens.space3),
        ],

        const _LetraPequena(),

        TextButton(
          onPressed: _ocupado ? null : () => unawaited(_compras.restaurar()),
          child: const Text('Restaurar compras'),
        ),
      ],
    );
  }
}

/// Play no dio ningún plan. No es un callejón sin salida: se puede reintentar
/// y escribirnos, y una persona ayuda.
///
/// **Nada de la web** (política de pagos de Google Play): ni enlaces ni
/// «paga en otro sitio».
class _SinPlanes extends StatelessWidget {
  const _SinPlanes({required this.vacio, required this.onReintentar});

  /// Play respondió sin planes. Si no, la consulta falló.
  final bool vacio;
  final VoidCallback onReintentar;

  /// Lo que se le dice a quien ayuda, ya escrito.
  static const mensajeDeAyuda =
      'Hola, en la app de ENAM Prep (Android) no me aparecen los planes de '
      'Google Play.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StateBanner(
          kind: BannerKind.info,
          message: vacio
              ? 'Los planes no están disponibles en tu cuenta de Google Play '
                    'en este momento. Escríbenos y te ayudamos.'
              : 'No pudimos cargar los planes. Inténtalo de nuevo o '
                    'escríbenos y te ayudamos.',
        ),
        const SizedBox(height: DesignTokens.space3),
        EnamButton(
          label: 'Escríbenos por WhatsApp',
          icon: Symbols.chat,
          onPressed: () => unawaited(
            Contacto.abrir(Contacto.soporte(mensaje: mensajeDeAyuda)),
          ),
        ),
        TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
      ],
    );
  }
}

bool _yaTienePremium(Subscription sub) =>
    sub.acceso is AccesoPremium &&
    (sub.estado == SubscriptionStatus.activa ||
        sub.estado == SubscriptionStatus.enGracia);

/// Un plan en una fila: se elige tocándolo, y se compra con el botón de abajo.
class _FilaPlan extends StatelessWidget {
  const _FilaPlan({
    required this.producto,
    required this.elegido,
    required this.onTap,
  });

  final ProductDetails producto;
  final bool elegido;
  final VoidCallback? onTap;

  /// Play añade el nombre de la app entre paréntesis: «Premium mensual (ENAM
  /// Prep)». En nuestra propia pantalla sobra.
  String get _titulo =>
      producto.title.replaceFirst(RegExp(r'\s*\([^()]*\)\s*$'), '');

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radio = BorderRadius.circular(DesignTokens.radiusMd);

    return Semantics(
      button: true,
      selected: elegido,
      child: Material(
        color: elegido ? context.states.info.tint : scheme.surfaceContainer,
        borderRadius: radio,
        child: InkWell(
          onTap: onTap,
          borderRadius: radio,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space3,
            ),
            decoration: BoxDecoration(
              borderRadius: radio,
              border: Border.all(
                color: elegido ? scheme.primary : scheme.outlineVariant,
                width: elegido ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  elegido
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  size: 20,
                  fill: elegido ? 1 : 0,
                  color: elegido ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(
                  child: Text(
                    _titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                // El precio, tal cual lo formatea Play para el país de la
                // cuenta.
                Text(
                  producto.price,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Textos de la casilla de novedades. Neutros a propósito: la política de
/// Google Play no deja mencionar la web, pagos fuera de Play ni descuentos que
/// solo estén allí. Eso, si acaso, va después en el correo.
const tituloNovedadesEnPlanes = 'Quiero recibir novedades y promociones';
const detalleNovedadesEnPlanes =
    'Te enviaremos novedades, simulacros y promociones a tu correo. Puedes '
    'darte de baja cuando quieras.';

/// El consentimiento comercial debajo de los planes (catálogo 34): desmarcado
/// por defecto (Ley 29733) y sin condicionar la compra.
class _CasillaDeNovedades extends StatelessWidget {
  const _CasillaDeNovedades({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final alCambiar = onChanged;
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        onTap: alCambiar == null ? null : () => alCambiar(!value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              visualDensity: VisualDensity.compact,
              onChanged: alCambiar == null
                  ? null
                  : (v) => alCambiar(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space2 + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloNovedadesEnPlanes,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalleNovedadesEnPlanes,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 11.5,
                        height: 1.35,
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cómo se cobra, se renueva y se cancela, junto al botón.
class _LetraPequena extends StatelessWidget {
  const _LetraPequena();

  static const _terminos = 'https://enamprep.com/terminos';

  @override
  Widget build(BuildContext context) {
    final estilo = context.texts.bodySmall?.copyWith(
      fontSize: 11.5,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: context.scheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El pago se carga a tu cuenta de Google Play al confirmar. Las '
            'suscripciones se renuevan solas por el mismo periodo y al mismo '
            'precio hasta que las canceles, cuando quieras, en Play Store → '
            'Pagos y suscripciones → Suscripciones.',
            style: estilo,
          ),
          const SizedBox(height: DesignTokens.space2),
          const Wrap(
            spacing: DesignTokens.space3,
            children: [
              _Enlace(texto: 'Términos', url: _terminos),
              _Enlace(texto: 'Privacidad', url: _terminos),
            ],
          ),
        ],
      ),
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace({required this.texto, required this.url});

  final String texto;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => unawaited(
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              color: context.scheme.primary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Symbols.open_in_new, size: 12, color: context.scheme.primary),
        ],
      ),
    );
  }
}
