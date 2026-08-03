import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../../../shared/widgets/state_banner.dart';
import '../../data/compras_apple_controller.dart';

/// Los planes, comprables con el sistema de pagos de Apple.
///
/// Solo se monta en iPhone. En Android el cobro sigue ocurriendo en la web: allí
/// no hace falta pagar comisión y el enlace por correo funciona mejor.
///
/// ---
///
/// **Buena parte de este archivo es texto legal, y no sobra.** App Store rechaza
/// las suscripciones cuyo botón de compra no lleve al lado —visible, sin
/// desplegar nada— la duración, el precio, que se renueva sola y cómo cancelar,
/// más los enlaces a términos y privacidad. Es el motivo de rechazo más común en
/// suscripciones, por delante de cualquier fallo técnico.
///
/// El precio se pinta con lo que devuelve StoreKit y nunca con un valor nuestro:
/// Apple lo exige, y además así quien compra desde México ve pesos sin que nadie
/// convierta nada.
class PlanesDeApple extends ConsumerStatefulWidget {
  const PlanesDeApple({super.key});

  @override
  ConsumerState<PlanesDeApple> createState() => _PlanesDeAppleState();
}

class _PlanesDeAppleState extends ConsumerState<PlanesDeApple> {
  late final ComprasAppleController _compras;
  StreamSubscription<ResultadoCompra>? _escucha;

  List<ProductDetails>? _productos;
  String? _errorAlCargar;

  EstadoCompra _estado = EstadoCompra.quieto;
  String? _mensaje;

  /// Cuál se está comprando, para que el spinner salga en su botón y no en los
  /// tres.
  String? _comprando;

  @override
  void initState() {
    super.initState();
    _compras = ref.read(comprasAppleControllerProvider);

    // Antes de cargar nada: al suscribirse, StoreKit entrega también las
    // compras que quedaron sin completar. Ahí se recupera solo quien pagó y se
    // quedó sin acceso porque falló la red.
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
      if (mounted) setState(() => _productos = productos);
    } catch (e) {
      if (mounted) setState(() => _errorAlCargar = '$e');
    }
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
      // La suscripción cambió en el servidor: sin esto, la guarda seguiría
      // creyendo que no hay acceso y dejaría al usuario en esta misma pantalla
      // después de haber pagado.
      ref.invalidate(subscriptionProvider);
    }
  }

  bool get _ocupado =>
      _estado == EstadoCompra.comprando || _estado == EstadoCompra.registrando;

  @override
  Widget build(BuildContext context) {
    if (_errorAlCargar != null) {
      return StateBanner(
        kind: BannerKind.error,
        message: 'No pudimos cargar los planes.',
        action: TextButton(
          onPressed: () {
            setState(() => _errorAlCargar = null);
            unawaited(_cargar());
          },
          child: const Text('Reintentar'),
        ),
      );
    }

    final productos = _productos;
    if (productos == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.space6),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (productos.isEmpty) {
      return const StateBanner(
        kind: BannerKind.info,
        message: 'Los planes no están disponibles ahora mismo. Inténtalo en un '
            'momento.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mensaje case final m?) ...[
          StateBanner(
            // Cuando el dinero ya salió, el aviso NO es un error rojo: es
            // información. Pintarlo como fallo hace que la gente vuelva a pagar.
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
            onComprar: _ocupado
                ? null
                : () {
                    setState(() => _comprando = p.id);
                    unawaited(_compras.comprar(p));
                  },
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

class _Plan extends StatelessWidget {
  const _Plan({
    required this.producto,
    required this.cargando,
    required this.onComprar,
  });

  final ProductDetails producto;
  final bool cargando;
  final VoidCallback? onComprar;

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
                  producto.title,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              // El precio, tal cual lo formatea Apple para el país de la cuenta.
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

/// Lo que App Store exige leer junto al botón, sin desplegar nada.
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
            'El pago se carga a tu cuenta de Apple al confirmar. La suscripción '
            'se renueva sola por el mismo periodo y al mismo precio, salvo que '
            'la canceles al menos 24 horas antes de que termine. Puedes '
            'cancelarla cuando quieras desde Ajustes de tu iPhone → tu nombre → '
            'Suscripciones.',
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
