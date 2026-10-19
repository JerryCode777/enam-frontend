import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/analitica/analitica.dart';
import '../../../core/domain/hora_peru.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../auth/domain/auth_models.dart';
import '../../subscription/domain/subscription_models.dart';
import '../data/consentimiento_repository.dart';

// El texto de marketing (marketing-3d, enam-marketing 4dcb4ef), igual que la
// web salvo el final del cuerpo: en la app se cambia en Ajustes.
const tituloComerciales = '¿Te avisamos de descuentos y novedades?';
const cuerpoComerciales =
    'Si aceptas, te escribiremos por correo cuando haya descuentos o '
    'novedades en ENAM Prep. Es opcional y puedes cambiarlo cuando quieras en '
    'Ajustes.';
const siComerciales = 'Sí, avísenme';
const noComerciales = 'No, gracias';
const politicaComerciales = 'Política de privacidad';

/// Tras el sí. Sin anunciar ningún descuento.
const listoComerciales = 'Listo. Puedes cambiarlo cuando quieras.';

/// Si a la cuenta le toca la pregunta: no decidió todavía y su día gratis ya
/// terminó (19/10/2026, igual que la web).
///
/// No se mira `estado`: al vencer sigue en «prueba» hasta que la tarea horaria
/// del servidor la pasa a «expirada». Lo que manda es la fecha. `expira >
/// inicia` deja fuera a las cuentas que nunca tuvieron un día gratis: a esas se
/// les guardó el plan de prueba ya vencido en el alta.
bool tocaPreguntarComerciales(User user, Subscription sub, DateTime ahora) {
  if (user.aceptaComerciales != null) return false;
  if (sub.plan.id != 'trial' || sub.gratis == null) return false;
  final fin = sub.expira;
  return fin != null && fin.isAfter(sub.inicia) && !fin.isAfter(ahora);
}

/// Una sola vez por cuenta en este teléfono: se anota al mostrarse. Dentro de
/// la misma visita (mientras la app siga abierta) la tarjeta sigue en el
/// inicio si se navega y se vuelve; en la siguiente ya no sale, la haya
/// contestado o no. Las cuentas cuya tarjeta sigue en pie en esta visita.
final comercialesEnEstaVisitaProvider =
    NotifierProvider<_EnEstaVisita, Set<String>>(_EnEstaVisita.new);

class _EnEstaVisita extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void abrir(String id) => state = {...state, id};

  void cerrar(String id) => state = {...state}..remove(id);
}

/// El permiso de correos comerciales al terminar el día gratis, arriba del
/// inicio. Dos botones del mismo tamaño, nada premarcado, y la política a un
/// toque. Si se cierra sin elegir, queda sin decidir y se cambia en Ajustes.
class TarjetaDeComerciales extends ConsumerStatefulWidget {
  const TarjetaDeComerciales({this.espacioArriba = 0, super.key});

  /// El espacio que la separa de lo de arriba, solo cuando se muestra.
  final double espacioArriba;

  @override
  ConsumerState<TarjetaDeComerciales> createState() =>
      _TarjetaDeComercialesState();
}

class _TarjetaDeComercialesState extends ConsumerState<TarjetaDeComerciales> {
  /// La cuenta cuya marca en el teléfono ya se revisó en este montaje.
  String? _revisada;
  bool _enviando = false;
  String? _error;

  Future<void> _revisar(String id) async {
    final prefs = ref.read(appPrefsProvider);
    if (await prefs.comercialesPreguntado(id)) return;
    await prefs.marcarComercialesPreguntado(id);
    if (!mounted) return;
    ref.read(comercialesEnEstaVisitaProvider.notifier).abrir(id);
    // Una vez: esta pregunta sale una sola vez por cuenta, aunque la tarjeta
    // siga en el inicio al volver en la misma visita.
    _registrar(Evento.consentimientoVisto, const {});
  }

  void _registrar(Evento evento, Map<String, String> propiedades) => ref
      .read(analiticaProvider)
      .registrar(
        evento,
        propiedades: {'lugar': 'fin_dia_gratis', ...propiedades},
      );

  /// Si ya salió `consentimiento_respuesta`: es uno por aparición, aunque
  /// haya que reintentar el guardado.
  bool _respondio = false;

  void _responder(String respuesta) {
    if (_respondio) return;
    _respondio = true;
    _registrar(Evento.consentimientoRespuesta, {'respuesta': respuesta});
  }

  Future<void> _decidir(User user, bool acepta) async {
    // Al tocar, antes del PATCH.
    _responder(acepta ? 'si' : 'no');
    final mensajero = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final actualizado = await ref
          .read(consentimientoRepositoryProvider)
          .decidir(acepta: acepta, origen: OrigenConsentimiento.finDiaGratis);
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).setUser(actualizado);
      ref.read(comercialesEnEstaVisitaProvider.notifier).cerrar(user.id);
      if (acepta) {
        mensajero?.showSnackBar(
          const SnackBar(content: Text(listoComerciales)),
        );
      }
    } on Failure {
      // Queda abierta con el error: cerrarla en silencio haría creer que se
      // guardó. No se reintenta sola.
      if (mounted) {
        setState(() {
          _enviando = false;
          _error =
              'No pudimos guardar tu respuesta. Revisa tu conexión e '
              'inténtalo otra vez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final sub = ref.watch(subscriptionProvider).value;
    final abiertas = ref.watch(comercialesEnEstaVisitaProvider);
    if (user == null) return const SizedBox.shrink();

    if (!abiertas.contains(user.id)) {
      if (sub != null &&
          _revisada != user.id &&
          tocaPreguntarComerciales(user, sub, ahora())) {
        _revisada = user.id;
        _revisar(user.id);
      }
      return const SizedBox.shrink();
    }

    final texts = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: widget.espacioArriba),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space4,
            DesignTokens.space2,
            DesignTokens.space2,
            DesignTokens.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tituloComerciales,
                      style: texts.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Symbols.close),
                    onPressed: _enviando
                        ? null
                        : () {
                            // Cerrar nunca cuenta como «sí»: no hay PATCH.
                            _responder('cerro');
                            ref
                                .read(comercialesEnEstaVisitaProvider.notifier)
                                .cerrar(user.id);
                          },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: DesignTokens.space2),
                child: Text(
                  cuerpoComerciales,
                  style: texts.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: DesignTokens.space3),
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.space2),
                  child: StateBanner(kind: BannerKind.error, message: error),
                ),
              ],
              const SizedBox(height: DesignTokens.space4),
              // Del mismo tamaño y el mismo estilo: ninguna respuesta se
              // empuja más que la otra.
              Padding(
                padding: const EdgeInsets.only(right: DesignTokens.space2),
                child: Row(
                  children: [
                    Expanded(
                      child: EnamOutlinedButton(
                        label: siComerciales,
                        height: 48,
                        onPressed: _enviando
                            ? null
                            : () => _decidir(user, true),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: EnamOutlinedButton(
                        label: noComerciales,
                        height: 48,
                        onPressed: _enviando
                            ? null
                            : () => _decidir(user, false),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                child: TextButton(
                  onPressed: () => context.irA(Routes.terms),
                  child: const Text(politicaComerciales),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
