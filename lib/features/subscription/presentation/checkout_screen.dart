import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/subscription_models.dart';
import 'plans_screen.dart';

enum MedioPago { tarjeta, yape }

/// Pantalla 7.2 — checkout con Culqi (RF-26) y Yape (RF-28).
///
/// Los dos medios tienen consecuencias distintas y la pantalla lo dice: tarjeta
/// activa al instante por webhook; Yape queda **pendiente de verificación
/// manual**. Prometer activación inmediata en Yape sería mentir.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({this.planId, super.key});

  final String? planId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  MedioPago _medio = MedioPago.tarjeta;

  final _numero = TextEditingController();
  final _vence = TextEditingController();
  final _cvv = TextEditingController();

  String? _errorNumero;
  String? _errorVence;
  String? _errorCvv;
  bool _procesando = false;

  @override
  void dispose() {
    _numero.dispose();
    _vence.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Plan get _plan {
    final planes = ref.read(plansProvider);
    return planes.firstWhere(
      (p) => p.id == widget.planId,
      orElse: () => planes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Pago seguro'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space4,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                FadeUp(child: _Resumen(plan: _plan)),
                const SizedBox(height: DesignTokens.space4),
                FadeUp(
                  index: 1,
                  child: SegmentedButton<MedioPago>(
                    segments: const [
                      ButtonSegment(
                        value: MedioPago.tarjeta,
                        icon: Icon(Symbols.credit_card),
                        label: Text('Tarjeta'),
                      ),
                      ButtonSegment(
                        value: MedioPago.yape,
                        icon: Icon(Symbols.qr_code_2),
                        label: Text('Yape / Plin'),
                      ),
                    ],
                    selected: {_medio},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _medio = s.first),
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                if (_medio == MedioPago.tarjeta)
                  _FormularioTarjeta(
                    numero: _numero,
                    vence: _vence,
                    cvv: _cvv,
                    errorNumero: _errorNumero,
                    errorVence: _errorVence,
                    errorCvv: _errorCvv,
                    habilitado: !_procesando,
                    onCambio: _limpiarErrores,
                  )
                else
                  _Yape(plan: _plan),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: context.scheme.surface,
              border: Border(
                top: BorderSide(color: context.scheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                EnamButton(
                  label: _medio == MedioPago.tarjeta
                      ? 'Pagar S/ ${_plan.precio.toStringAsFixed(0)}'
                      : 'Ya pagué',
                  loading: _procesando,
                  onPressed: _pagar,
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  _medio == MedioPago.tarjeta && _plan.duracionDias <= 31
                      // Obligatorio decirlo antes de cobrar.
                      ? 'Al pagar aceptas la renovación automática mensual'
                      : 'Pago único, no se renueva solo',
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _limpiarErrores() {
    if (_errorNumero != null || _errorVence != null || _errorCvv != null) {
      setState(() {
        _errorNumero = null;
        _errorVence = null;
        _errorCvv = null;
      });
    }
  }

  bool _validarTarjeta() {
    final numero = _numero.text.replaceAll(RegExp(r'\s'), '');
    setState(() {
      _errorNumero = switch (numero.length) {
        0 => 'Ingresa el número de tu tarjeta.',
        < 13 => 'El número está incompleto.',
        _ => null,
      };
      _errorVence = _vence.text.length < 5 ? 'MM/AA' : null;
      _errorCvv = _cvv.text.length < 3 ? '3 dígitos' : null;
    });
    return _errorNumero == null && _errorVence == null && _errorCvv == null;
  }

  Future<void> _pagar() async {
    if (_procesando) return;

    if (_medio == MedioPago.tarjeta && !_validarTarjeta()) return;

    setState(() => _procesando = true);
    // La tokenización real la hace el SDK de Culqi; aquí solo se simula el viaje.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _procesando = false);

    context.pushReplacement(
      '${Routes.paymentResult}?estado='
      '${_medio == MedioPago.tarjeta ? "exito" : "pendiente"}'
      '&plan=${_plan.id}',
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.nombre,
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    plan.duracionDias <= 31
                        ? 'Se renueva cada mes · cancela cuando quieras'
                        : 'Pago único por ${plan.duracionDias ~/ 30} meses',
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              'S/ ${plan.precio.toStringAsFixed(0)}',
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioTarjeta extends StatelessWidget {
  const _FormularioTarjeta({
    required this.numero,
    required this.vence,
    required this.cvv,
    required this.errorNumero,
    required this.errorVence,
    required this.errorCvv,
    required this.habilitado,
    required this.onCambio,
  });

  final TextEditingController numero;
  final TextEditingController vence;
  final TextEditingController cvv;
  final String? errorNumero;
  final String? errorVence;
  final String? errorCvv;
  final bool habilitado;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      index: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnamTextField(
            label: 'Número de tarjeta',
            controller: numero,
            error: errorNumero,
            hint: '4111 1111 1111 1111',
            keyboardType: TextInputType.number,
            enabled: habilitado,
            onChanged: (_) => onCambio(),
          ),
          const SizedBox(height: DesignTokens.space4),
          Row(
            children: [
              Expanded(
                child: EnamTextField(
                  label: 'Vence',
                  controller: vence,
                  error: errorVence,
                  hint: 'MM/AA',
                  keyboardType: TextInputType.number,
                  enabled: habilitado,
                  onChanged: (_) => onCambio(),
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: EnamTextField(
                  label: 'CVV',
                  controller: cvv,
                  error: errorCvv,
                  hint: '123',
                  obscure: true,
                  keyboardType: TextInputType.number,
                  enabled: habilitado,
                  onChanged: (_) => onCambio(),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          const StateBanner(
            icon: Symbols.lock,
            message:
                'Procesado por Culqi. No guardamos los datos de tu tarjeta.',
          ),
        ],
      ),
    );
  }
}

/// Yape: QR, monto exacto y la advertencia de que la activación es manual.
class _Yape extends StatelessWidget {
  const _Yape({required this.plan});

  final Plan plan;

  /// Número al que se yapea. Configurable desde el admin.
  static const _numero = '987 654 321';

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return FadeUp(
      index: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 180,
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Icon(
                Symbols.qr_code_2,
                size: 96,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          _Copiable(
            etiqueta: 'Monto exacto',
            valor: 'S/ ${plan.precio.toStringAsFixed(2)}',
          ),
          const SizedBox(height: DesignTokens.space2 + 2),
          const _Copiable(etiqueta: 'Número', valor: _numero),
          const SizedBox(height: DesignTokens.space4),
          const StateBanner(
            kind: BannerKind.warning,
            icon: Symbols.schedule,
            message:
                'La verificación de Yape es manual. Después de yapear, toca "Ya '
                'pagué" y te avisamos cuando se active — normalmente en menos '
                'de 2 horas.',
          ),
        ],
      ),
    );
  }
}

/// Un dato que se puede copiar. El monto exacto tiene que ser exacto: un
/// céntimo de diferencia obliga a verificación manual extra.
class _Copiable extends StatelessWidget {
  const _Copiable({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: valor));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$etiqueta copiado')),
            );
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiqueta, style: context.texts.bodySmall),
                    Text(
                      valor,
                      style: context.texts.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.content_copy,
                size: 20,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
