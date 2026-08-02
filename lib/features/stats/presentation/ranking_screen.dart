import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/stats_models.dart';
import 'widgets/podio_ranking.dart';

/// Cuántas filas se muestran. Igual que `TopDelRanking` en el servidor.
const _top = 10;

final rankingProvider = FutureProvider<List<RankingEntry>>((ref) {
  return ref.watch(statsRepositoryProvider).rankingGeneral();
});

/// Pantalla 6.2 — ranking general (RF-22, RN-05).
///
/// Solo cuenta simulacros completos de 180. La fila del usuario queda **fijada
/// abajo** cuando está fuera de la vista: en un ranking de miles, lo que la
/// persona busca es su propia posición, no el top.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingProvider);
    final usuario = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Ranking general',
            subtitulo: 'Por promedio de simulacros completos',
          ),
          Expanded(
            child: ranking.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(DesignTokens.space4),
                children: [
                  for (var i = 0; i < 8; i++)
                    const Padding(
                      padding: EdgeInsets.only(bottom: DesignTokens.space2),
                      child: SkeletonBox(height: 56),
                    ),
                ],
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: StateBanner(
                    kind: BannerKind.error,
                    message: 'No pudimos cargar el ranking.',
                    action: TextButton(
                      onPressed: () => ref.invalidate(rankingProvider),
                      child: const Text('Reintentar'),
                    ),
                  ),
                ),
              ),
              data: (filas) => _Contenido(
                filas: filas,
                oculto: usuario?.ocultoEnRanking ?? false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.filas, required this.oculto});

  final List<RankingEntry> filas;
  final bool oculto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La fila propia sale de la respuesta ENTERA, no del top: quien va 340º la
    // recibe aparte y es lo único que lo ancla en esta pantalla.
    final propia = filas.where((f) => f.esUsuarioActual).firstOrNull;

    // Diez y ni una más, se mande lo que se mande.
    //
    // El servidor ya recorta, pero el recorte se comprueba también aquí: es lo
    // que se ve, y depender de que el otro lado lo haga bien significa que el
    // día que cambie —o que una app vieja hable con un servidor nuevo— la
    // pantalla crece sin que nadie se entere.
    final top = filas.where((f) => f.posicion <= _top).take(_top).toList();

    // El podio quiere exactamente tres. Con menos no se pinta: tres escalones
    // con dos llenos y uno vacío se leen como un fallo de carga, no como
    // «todavía no hay tercero».
    final hayPodio = top.length >= 3;
    final resto = hayPodio ? top.skip(3).toList() : top;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space3,
              DesignTokens.space4,
              DesignTokens.space4,
            ),
            children: [
              if (hayPodio) ...[
                PodioRanking(filas: top.take(3).toList()),
                const SizedBox(height: DesignTokens.space4),
              ],
              if (resto.isNotEmpty)
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < resto.length; i++)
                        _Fila(
                          entrada: resto[i],
                          index: i,
                          esUltima: i == resto.length - 1,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Solo cuentan simulacros terminados de '
                '${Blueprint.totalQuestions} preguntas. En los nacionales '
                'desempata el menor tiempo total.',
                style: context.texts.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: DesignTokens.space4),
              _Visibilidad(oculto: oculto),
            ],
          ),
        ),
        // Fijada abajo: es el dato que la persona vino a buscar, y el único
        // sitio donde se ve si está fuera del top.
        if (propia != null) _MiPosicion(entrada: propia),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.entrada,
    required this.index,
    required this.esUltima,
  });

  final RankingEntry entrada;
  final int index;
  final bool esUltima;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final propia = entrada.esUsuarioActual;

    return FadeUp(
      index: index,
      child: Container(
        decoration: BoxDecoration(
          color: propia ? states.info.tint : null,
          border: esUltima
              ? null
              : Border(
                  bottom: BorderSide(color: context.scheme.outlineVariant),
                ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
        child: Row(
          children: [
            // Sin medalla: los tres primeros van al podio, y aquí ya solo
            // hay números. Una lista sobria debajo deja que el brillo esté
            // arriba, donde importa.
            SizedBox(
              width: 30,
              child: Text(
                '${entrada.posicion}',
                style: context.texts.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: propia
                      ? states.info.onTint
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propia ? 'Tú' : entrada.usuarioNombre,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: propia ? FontWeight.w800 : FontWeight.w700,
                      color: propia ? states.info.onTint : null,
                    ),
                  ),
                  if (entrada.universidad != null)
                    Text(
                      entrada.universidad!,
                      style: context.texts.bodySmall?.copyWith(fontSize: 13),
                    ),
                ],
              ),
            ),
            Text(
              // Siempre 2 decimales (RN-01).
              entrada.promedio.toStringAsFixed(2),
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: propia ? states.info.onTint : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dónde va el usuario. Posición y promedio, nada más.
///
/// Es lo único que la persona vino a buscar. Su nombre y su universidad ya los
/// sabe, y ocuparían el sitio de las dos cifras que sí importan.
///
/// Va **siempre visible**, esté o no dentro del top: quien está fuera de los
/// diez ya no tiene fila en la lista, y el servidor le manda la suya aparte
/// justamente para esto.
class _MiPosicion extends StatelessWidget {
  const _MiPosicion({required this.entrada});

  final RankingEntry entrada;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3 + 2,
        DesignTokens.space4,
        DesignTokens.space3 + 2 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.headerGradientLight.first,
        border: Border(top: BorderSide(color: context.scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tu posición',
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            '#',
            style: context.texts.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Text(
            '${entrada.posicion}',
            style: context.texts.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          // La línea separa dos cifras que se leen distinto: una es un puesto y
          // la otra una nota sobre 20. Pegadas se leen como un marcador.
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Text(
            entrada.promedio.toStringAsFixed(2),
            style: context.texts.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DesignTokens.headerGradientLight.last,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opción de ocultarse del ranking público (RF-22).
class _Visibilidad extends ConsumerWidget {
  const _Visibilidad({required this.oculto});

  final bool oculto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: SwitchListTile(
        value: !oculto,
        onChanged: (visible) async {
          final user = await ref
              .read(authRepositoryProvider)
              .updateProfile(ocultoEnRanking: !visible);
          ref.read(authControllerProvider.notifier).setUser(user);
        },
        secondary: const Icon(Symbols.visibility),
        title: const Text('Aparecer en el ranking público'),
        subtitle: Text(
          // Se aclara qué se conserva: nadie debería temer perder su progreso
          // por ocultarse.
          'Si lo apagas, tus notas siguen contando para ti pero nadie más ve '
          'tu nombre.',
          style: context.texts.bodySmall?.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}
