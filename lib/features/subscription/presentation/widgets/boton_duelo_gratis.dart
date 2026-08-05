import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/providers.dart';
import '../../../../core/router/navegar.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';

/// El duelo diario gratuito, ofrecido desde la pantalla de cobro (RF-65).
///
/// # Por qué está aquí y no en el inicio
///
/// Porque a esta pantalla llega quien **no tiene plan**, que es exactamente a
/// quien va dirigido. Y porque el emparejamiento necesita gente: si la cola
/// está vacía, quien paga espera treinta segundos y acaba jugando contra el
/// bot. Dejar entrar a los que no pagan llena la cola, y el beneficiado es EL
/// QUE SÍ PAGA — juega contra una persona en vez de contra una máquina.
///
/// # Tres estados, y los tres importan
///
///   - **Apagado** (`activo: false`) — el pase no existe para esta persona: no
///     se pinta nada, y la pantalla se ve como antes de que esto existiera.
///   - **Disponible** — botón vivo, que lleva directo a la partida.
///   - **Gastado** — botón a la vista pero apagado, con «vuelve mañana».
///     Desaparecer después de jugar dejaba a quien lo usó sin saber que
///     existe.
///
/// El tercero va contra la letra de RP-01, que dice no anunciar los límites del
/// plan. Se hace igual porque aquí el límite **ya se topó**: no se avisa de un
/// techo que no ha tocado, se explica algo que acaba de pasarle.
///
/// # Quién decide
///
/// El servidor, siempre. Si `DUELO_GRATIS_POR_DIA` está en 0, responde que no
/// hay nada y aquí no se pinta nada — así apagarlo en el servidor apaga el
/// botón sin publicar una versión nueva de la app.
class BotonDueloGratis extends ConsumerStatefulWidget {
  const BotonDueloGratis({super.key});

  @override
  ConsumerState<BotonDueloGratis> createState() => _BotonDueloGratisState();
}

class _BotonDueloGratisState extends ConsumerState<BotonDueloGratis> {
  bool _buscando = false;

  @override
  Widget build(BuildContext context) {
    final pase = ref.watch(paseDeDueloProvider).value;
    if (pase == null || !pase.activo) return const SizedBox.shrink();

    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final estados = context.states;
    final disponible = pase.disponible;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space5),
      child: Material(
        color: disponible ? estados.info.tint : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: InkWell(
          onTap: disponible && !_buscando ? () => unawaited(_jugar()) : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(
                color: disponible ? estados.info.base : scheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  disponible ? Symbols.swords : Symbols.schedule,
                  color: disponible
                      ? estados.info.base
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !disponible
                            ? 'Ya jugaste tu duelo de hoy'
                            : _buscando
                            ? 'Buscando rival…'
                            : 'Juega un duelo gratis',
                        style: texto.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: disponible
                              ? estados.info.onTint
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disponible
                            ? 'Diez preguntas contra otra persona, ahora mismo'
                            : 'Vuelve mañana, o activa tu plan y juega sin '
                                  'límite',
                        style: texto.bodySmall?.copyWith(
                          color: disponible
                              ? estados.info.onTint
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_buscando)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Va directo a la partida, sin pasar por «elegir oponente».
  ///
  /// Esa pantalla ofrece el enlace de retador y el PIN, y el pase no abre
  /// ninguno de los dos: solo la cola aleatoria, que es la única cuyo problema
  /// es la falta de gente. Enseñárselos sería ofrecerle dos botones que el
  /// servidor va a rechazar.
  Future<void> _jugar() async {
    setState(() => _buscando = true);
    try {
      final duelo = await ref.read(dueloRepositoryProvider).buscarAleatorio();
      if (!mounted) return;
      context.irA(Routes.dueloPartidaOf(duelo.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _buscando = false);
      // Se vuelve a preguntar: lo más probable es que se le acabara el pase
      // mientras la pantalla estaba abierta, y entonces el botón tiene que
      // pasar a «vuelve mañana» en vez de quedarse invitando.
      ref.invalidate(paseDeDueloProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted && _buscando) setState(() => _buscando = false);
    }
  }
}
