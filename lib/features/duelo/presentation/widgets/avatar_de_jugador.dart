import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';


/// La cara de un jugador: su foto, o su inicial mientras no la haya.
///
/// Existe para que las tres pantallas del duelo —el marcador de la partida, el
/// VS y el resultado— enseñen a la persona igual. Sin esto, cada una dibujaba
/// su propio círculo y añadir la foto significaría acordarse de las tres.
///
/// **No hay color por persona**, y no es por falta de ganas: en estas pantallas
/// el verde, el rojo y el ámbar SIGNIFICAN algo —acierto, fallo, sin tiempo—.
/// Un avatar verde al lado de un marcador se leería como que esa persona va
/// bien, que es justo lo que no queremos decir con un color de relleno.
class AvatarDeJugador extends StatelessWidget {
  const AvatarDeJugador({
    required this.nombre,
    this.esBot = false,
    this.fotoUrl,
    this.tamano = 56,
    this.fondo,
    this.tinta,
    this.borde,
    super.key,
  });

  final String nombre;
  final bool esBot;

  /// La foto de perfil, cuando exista.
  ///
  /// Hoy **no existe**: ni el contrato ni la tabla `users` tienen ese campo. El
  /// hueco queda hecho a propósito para que añadirla sea pasar una URL y no
  /// tocar tres pantallas.
  final String? fotoUrl;

  final double tamano;
  final Color? fondo;
  final Color? tinta;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colorFondo = fondo ?? scheme.surfaceContainerHighest;
    final colorTinta = tinta ?? scheme.onSurfaceVariant;
    final inicial = nombre.trim().isEmpty
        ? '?'
        : nombre.trim().characters.first.toUpperCase();

    return Semantics(
      // Decorativo: el nombre está escrito al lado siempre. Anunciarlo otra vez
      // haría que el lector de pantalla dijera «Ana, Ana».
      excludeSemantics: true,
      child: Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorFondo,
          shape: BoxShape.circle,
          border: borde == null ? null : Border.all(color: borde!, width: 2),
          image: fotoUrl == null || fotoUrl!.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(fotoUrl!),
                  fit: BoxFit.cover,
                ),
        ),
        child: fotoUrl != null && fotoUrl!.isNotEmpty
            ? null
            : esBot
            ? Icon(Symbols.smart_toy, size: tamano * 0.45, color: colorTinta)
            : Text(
                inicial,
                style: TextStyle(
                  fontSize: tamano * 0.4,
                  fontWeight: FontWeight.w800,
                  color: colorTinta,
                ),
              ),
      ),
    );
  }
}
