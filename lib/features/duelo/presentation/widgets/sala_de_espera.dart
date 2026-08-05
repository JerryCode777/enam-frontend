import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../domain/duelo_models.dart';
import 'mensajes_de_espera_card.dart';

/// Lo que se ve mientras no hay rival.
///
/// Tiene tres caras porque son tres situaciones distintas, y confundirlas deja
/// al usuario sin saber qué hace ahí:
///
///   - **buscando** — cola aleatoria, con el contador corriendo;
///   - **con enlace** — el PIN a la vista para compartirlo;
///   - **revancha** — no se busca a nadie: se espera a una persona concreta.
///
/// Cuando se agota la búsqueda **no se enseña un error**: se ofrece el bot. Y la
/// búsqueda NO se detiene — si entra alguien mientras ese botón está en
/// pantalla, se juega contra esa persona.
class SalaDeEspera extends StatelessWidget {
  const SalaDeEspera({
    required this.duelo,
    required this.sinRival,
    required this.onAceptarBot,
    required this.aceptandoBot,
    this.espera,
    this.botBloqueado = false,
    super.key,
  });

  final DueloDTO duelo;
  final EsperaDeDuelo? espera;
  final bool sinRival;

  /// El bot es de pago para quien está aquí (RF-65).
  ///
  /// La oferta se enseña igual, apagada. Lo decide el servidor, no esta
  /// pantalla: la llamada existe en la API y esconder el botón no protege nada.
  final bool botBloqueado;

  final VoidCallback onAceptarBot;
  final bool aceptandoBot;

  bool get _esRevancha =>
      duelo.revanchaDe != null && duelo.revanchaDe!.isNotEmpty;

  bool get _esEnlace => duelo.origen == OrigenDuelo.enlace && !_esRevancha;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        if (_esRevancha)
          _EsperandoRevancha(nombre: duelo.rival)
        else if (_esEnlace)
          _TarjetaDelPin(duelo: duelo)
        else
          _BuscandoRival(espera: espera),

        const SizedBox(height: DesignTokens.space6),
        const TarjetaDeMensajes(),

        if (sinRival) ...[
          const SizedBox(height: DesignTokens.space6),
          _OfertaDelBot(
            bloqueada: botBloqueado,
            cargando: aceptandoBot,
            onAceptar: onAceptarBot,
          ),
        ],
      ],
    );
  }
}

class _BuscandoRival extends StatelessWidget {
  const _BuscandoRival({this.espera});

  final EsperaDeDuelo? espera;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final segundos = espera?.esperandoSegundos ?? 0;

    return Column(
      children: [
        const SizedBox(height: DesignTokens.space6),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 3, color: scheme.primary),
        ),
        const SizedBox(height: DesignTokens.space5),
        Text(
          'Buscando rival…',
          style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          // El contador corre en el cliente y no espera al servidor: llegaba
          // una sola vez y se quedaba clavado en 0, que se lee como colgado.
          segundos > 0
              ? 'Llevas $segundos ${segundos == 1 ? "segundo" : "segundos"} en la cola'
              : 'Te avisamos en cuanto entre alguien',
          style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// La espera de una revancha.
///
/// Se distingue de «buscando rival» a propósito: aquí no se busca a nadie, se
/// espera a una persona concreta que está mirando su pantalla de resultado.
/// Decir «buscando rival» sería mentir sobre lo que pasa.
class _EsperandoRevancha extends StatelessWidget {
  const _EsperandoRevancha({this.nombre});

  final String? nombre;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rival = (nombre == null || nombre!.isEmpty) ? 'Tu rival' : nombre!;

    return Column(
      children: [
        const SizedBox(height: DesignTokens.space6),
        Icon(Symbols.swords, size: 48, color: scheme.primary),
        const SizedBox(height: DesignTokens.space4),
        Text(
          'Esperando a $rival',
          style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Le pediste la revancha. Empieza en cuanto acepte.',
          style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// El PIN, para dictarlo o compartirlo.
///
/// El código existe porque WhatsApp e Instagram abren los enlaces en su propio
/// navegador, **que no comparte la sesión**: quien toca el enlace ahí aterriza
/// sin cuenta y pierde el reto. Un PIN de seis dígitos se dicta en voz alta y
/// se escribe en la otra app, que además es lo que hacen dos personas sentadas
/// al lado.
class _TarjetaDelPin extends StatelessWidget {
  const _TarjetaDelPin({required this.duelo});

  final DueloDTO duelo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final codigo = duelo.codigo ?? '';

    return Column(
      children: [
        const SizedBox(height: DesignTokens.space4),
        Text(
          'Tu reto está listo',
          style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Dile este código a quien quieras retar. Caduca en 10 minutos.',
          style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.space5),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space4,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          child: Text(
            codigo,
            style: texto.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: codigo));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              },
              icon: const Icon(Symbols.content_copy, size: 18),
              label: const Text('Copiar el código'),
            ),
          ],
        ),
      ],
    );
  }
}

/// La oferta del bot al agotarse la búsqueda.
///
/// Con el duelo diario gratuito (RF-65) llega igual pero **apagada**. Es el
/// mejor momento de conversión que tiene el duelo —esperó, quiere jugar, y hay
/// algo concreto que no puede— y convierte mucho mejor que una lista de
/// precios.
///
/// Lo que NO se bloquea es seguir esperando. Que pueda quedarse es lo que
/// mantiene la cola llena, que era el punto de regalar el duelo; y si no
/// aparece nadie, no gasta su pase.
class _OfertaDelBot extends StatelessWidget {
  const _OfertaDelBot({
    required this.bloqueada,
    required this.cargando,
    required this.onAceptar,
  });

  final bool bloqueada;
  final bool cargando;
  final VoidCallback onAceptar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: bloqueada ? scheme.surfaceContainerHighest : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: bloqueada ? scheme.outlineVariant : scheme.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // No dice «no encontramos rival», que suena a fracaso y no lo es:
            // la búsqueda NO se ha detenido. Si entra alguien mientras este
            // botón está en pantalla, se juega contra esa persona.
            bloqueada ? 'Jugar contra el bot' : '¿Juegas contra el bot mientras?',
            style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            bloqueada
                ? 'Con un plan puedes jugar sin esperar a que haya alguien. '
                      'Mientras, seguimos buscándote rival.'
                : 'Seguimos buscando rival. El bot ronda el aprobado: unas '
                      'veces gana y otras pierde.',
            style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DesignTokens.space4),
          EnamButton(
            label: bloqueada ? 'Solo con plan' : 'Jugar contra el bot',
            icon: bloqueada ? Symbols.lock : Symbols.smart_toy,
            loading: cargando,
            onPressed: bloqueada ? null : onAceptar,
          ),
        ],
      ),
    );
  }
}
