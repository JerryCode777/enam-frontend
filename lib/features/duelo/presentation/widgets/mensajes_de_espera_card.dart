import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../mensajes_de_espera.dart';

/// La tarjeta que va rotando consejos mientras se busca rival.
///
/// # Por qué es una tarjeta y no un texto suelto
///
/// Suelto no se entendía. Probándolo, la frase parecía **parte de la pantalla
/// de carga** —como esos mensajes que se ponen para entretener mientras algo
/// tarda— y no algo que la app quisiera contarte. Con un marco, una etiqueta
/// que dice qué es, y una barrita que avanza, se lee como lo que es.
///
/// # La barrita no es una barra de carga
///
/// Es lo que dice que **esto rota**. Sin ella, un texto quieto en una pantalla
/// de espera se lee como que la app se colgó; con ella se entiende que va a
/// venir otro. No mide la espera —esa no se sabe cuánto dura— sino lo que le
/// queda a este mensaje.
class TarjetaDeMensajes extends StatefulWidget {
  const TarjetaDeMensajes({super.key});

  @override
  State<TarjetaDeMensajes> createState() => _TarjetaDeMensajesState();
}

class _TarjetaDeMensajesState extends State<TarjetaDeMensajes> {
  late final List<MensajeDeEspera> _mensajes = barajarMensajes();
  int _indice = 0;
  Timer? _rotacion;

  @override
  void initState() {
    super.initState();
    _rotacion = Timer.periodic(duracionDelMensaje, (_) {
      if (!mounted) return;
      setState(() => _indice = (_indice + 1) % _mensajes.length);
    });
  }

  @override
  void dispose() {
    _rotacion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final mensaje = _mensajes[_indice];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.lightbulb, size: 16, color: scheme.primary),
              const SizedBox(width: DesignTokens.space1 + 2),
              Text(
                'MIENTRAS ESPERAS',
                style: texto.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),

          // La transición es un fundido y no un desplazamiento: a 360 px, algo
          // que entra por un lado se lee como que la pantalla cambió de sitio.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: Column(
              key: ValueKey(_indice),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje.texto,
                  style: texto.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  mensaje.apoyo,
                  style: texto.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.space4),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: TweenAnimationBuilder<double>(
              // La clave reinicia la animación con cada mensaje: sin ella, la
              // barra se quedaría llena desde el primero.
              key: ValueKey(_indice),
              tween: Tween(begin: 0, end: 1),
              duration: duracionDelMensaje,
              builder: (context, valor, _) => LinearProgressIndicator(
                value: valor,
                minHeight: 3,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
