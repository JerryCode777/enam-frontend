import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analitica/analitica.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../../../shared/widgets/state_banner.dart';
import '../../data/compras_apple_controller.dart'
    show EstadoCompra, ResultadoCompra;
import '../../data/compras_google_play_controller.dart';
import '../../data/fallo_de_tienda.dart';
import '../../data/google_play_iap_service.dart' show planIdDeGooglePlay;
import '../../domain/acceso.dart';
import '../../domain/subscription_models.dart';

/// Los planes, comprables con Google Play Billing. Solo en Android.
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

  /// Cuál se está comprando, para que el spinner salga en su botón.
  String? _comprando;

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
      if (productos.isEmpty) _avisarNoDisponibles();
    } catch (e) {
      if (!mounted) return;
      setState(() => _fallo = true);
      _avisarNoDisponibles(e);
    }
  }

  void _avisarNoDisponibles([Object? error]) {
    if (_avisado) return;
    _avisado = true;
    registrarPlanesNoDisponibles(
      ref.read(analiticaProvider),
      medio: 'google_play',
      error: error,
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
        _comprando = null;
      }
    });

    if (r.estado == EstadoCompra.listo) {
      // La suscripción cambió en el servidor: sin esto la guarda seguiría
      // creyendo que no hay acceso.
      ref.invalidate(subscriptionProvider);
    }
  }

  bool get _ocupado =>
      _estado == EstadoCompra.comprando || _estado == EstadoCompra.registrando;

  void _comprar(ProductDetails p, String cuentaId) {
    setState(() => _comprando = p.id);
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
      return StateBanner(
        kind: BannerKind.info,
        message: 'No pudimos cargar los planes. Inténtalo más tarde.',
        action: TextButton(
          onPressed: _reintentar,
          child: const Text('Reintentar'),
        ),
      );
    }
    if (productos == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.space6),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final cuentaId = ref.watch(currentUserProvider)?.id;

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
          _Plan(
            producto: p,
            cargando: _comprando == p.id,
            onComprar: _ocupado || cuentaId == null
                ? null
                : () => _comprar(p, cuentaId),
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

bool _yaTienePremium(Subscription sub) =>
    sub.acceso is AccesoPremium &&
    (sub.estado == SubscriptionStatus.activa ||
        sub.estado == SubscriptionStatus.enGracia);

class _Plan extends StatelessWidget {
  const _Plan({
    required this.producto,
    required this.cargando,
    required this.onComprar,
  });

  final ProductDetails producto;
  final bool cargando;
  final VoidCallback? onComprar;

  /// Play añade el nombre de la app entre paréntesis: «Premium mensual (ENAM
  /// Prep)». En nuestra propia pantalla sobra.
  String get _titulo =>
      producto.title.replaceFirst(RegExp(r'\s*\([^()]*\)\s*$'), '');

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _titulo,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              // El precio, tal cual lo formatea Play para el país de la cuenta.
              Text(
                producto.price,
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            producto.description,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          EnamButton(
            label: 'Suscribirme',
            loading: cargando,
            onPressed: onComprar,
          ),
        ],
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
