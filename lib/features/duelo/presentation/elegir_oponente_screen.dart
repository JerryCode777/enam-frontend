import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../domain/duelo_models.dart';

/// Las tres puertas al mismo duelo.
///
/// # Por qué tres y no una
///
///   - **Aleatorio** — la que llena la cola y la única que no depende de tener
///     a alguien a mano.
///   - **Retar por enlace** — para mandarlo por WhatsApp.
///   - **Tengo un código** — la que salva a las otras dos. WhatsApp e Instagram
///     abren los enlaces en su propio navegador, **que no comparte la sesión**:
///     quien toca el enlace ahí aterriza sin cuenta y pierde el reto. Con un
///     PIN que se dicta en voz alta, eso deja de importar — y además es lo que
///     hacen dos personas sentadas al lado.
///
/// **No hay lista de amigos.** Un duelo se juega ahora, no se agenda, así que
/// una lista de contactos sería una pantalla más entre querer jugar y jugar.
class ElegirOponenteScreen extends ConsumerStatefulWidget {
  const ElegirOponenteScreen({super.key});

  @override
  ConsumerState<ElegirOponenteScreen> createState() =>
      _ElegirOponenteScreenState();
}

class _ElegirOponenteScreenState extends ConsumerState<ElegirOponenteScreen> {
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Modo duelo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            Text(
              'Diez preguntas, dos personas, el mismo reloj.',
              style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              // Es cierto y quita el miedo a jugar: RN-13 dice que el duelo no
              // entra en el ranking, ni en la nota proyectada, ni en las
              // estadísticas.
              'No toca tu nota ni tus estadísticas. Es para entrenar decidir '
              'rápido, que es lo que se mide el día del examen.',
              style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: DesignTokens.space6),

            _Puerta(
              icono: Symbols.shuffle,
              titulo: 'Rival al azar',
              detalle: 'Te emparejamos con alguien que esté buscando ahora.',
              destacada: true,
              habilitada: !_ocupado,
              onTap: () => unawaited(_buscarAleatorio()),
            ),
            const SizedBox(height: DesignTokens.space3),
            _Puerta(
              icono: Symbols.link,
              titulo: 'Retar a alguien',
              detalle: 'Te damos un código para compartir. Caduca en 10 min.',
              habilitada: !_ocupado,
              onTap: () => unawaited(_crearPorEnlace()),
            ),
            const SizedBox(height: DesignTokens.space3),
            _Puerta(
              icono: Symbols.dialpad,
              titulo: 'Tengo un código',
              detalle: 'Escribe el PIN que te dieron y entras a ese duelo.',
              habilitada: !_ocupado,
              onTap: () => context.irA(Routes.dueloCodigoManual),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarAleatorio() => _abrir(
    () => ref.read(dueloRepositoryProvider).buscarAleatorio(),
  );

  Future<void> _crearPorEnlace() =>
      _abrir(() => ref.read(dueloRepositoryProvider).crearPorEnlace());

  Future<void> _abrir(Future<DueloDTO> Function() pedir) async {
    setState(() => _ocupado = true);
    try {
      final duelo = await pedir();
      if (!mounted) return;
      context.irA(Routes.dueloPartidaOf(duelo.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
}

class _Puerta extends StatelessWidget {
  const _Puerta({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.habilitada,
    required this.onTap,
    this.destacada = false,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final bool destacada;
  final bool habilitada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: habilitada ? 1 : 0.6,
      child: Material(
        color: destacada ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: InkWell(
          onTap: habilitada ? onTap : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(
                color: destacada ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(icono, color: scheme.primary),
                const SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: texto.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: texto.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Symbols.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
