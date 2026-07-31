import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/providers.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../auth/domain/auth_models.dart';

/// Cabecera del inicio, en degradado.
///
/// Reúne saludo, avatar, cuenta regresiva y la tarjeta para retomar la sesión.
/// La cuenta regresiva es línea de apoyo del saludo: informa, pero no compite
/// con las acciones que vienen debajo.
///
/// Los tamaños salen del diseño (`enam-01-auth-home.dc.html`, pantalla 2.1) y
/// son mínimos: si algo no cabe, se recorta contenido, nunca la tipografía.
class HomeHero extends StatelessWidget {
  const HomeHero({required this.user, this.sesion, super.key});

  final User? user;
  final ResumableSession? sesion;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dias = user?.diasParaExamen;
    final fecha = user?.fechaObjetivo;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? DesignTokens.headerGradientLight
              : DesignTokens.headerGradientDark,
          stops: DesignTokens.headerGradientStops,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl + 2),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl + 2),
        ),
        child: Stack(
          children: [
            // Círculos decorativos, recortados por las esquinas del hero.
            const Positioned(top: -70, right: -70, child: _Circulo(200, 0.10)),
            const Positioned(bottom: -60, left: -50, child: _Circulo(150, 0.07)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2 - 2,
                  DesignTokens.space5,
                  DesignTokens.space4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SaludoYCuenta(user: user, dias: dias, fecha: fecha),
                    // Sin sesión previa la tarjeta no se renderiza: el hero
                    // queda solo con saludo y cuenta regresiva.
                    if (sesion != null) ...[
                      const SizedBox(height: DesignTokens.space3 + 2),
                      _TarjetaRetomar(sesion: sesion!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo(this.tamano, this.opacidad);

  final double tamano;
  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacidad),
      ),
    );
  }
}

/// Saludo, cuenta regresiva y avatar.
///
/// El avatar se alinea arriba, junto al saludo: la cuenta regresiva es la que
/// tiene que dominar el bloque, y centrar el avatar le quitaría peso.
class _SaludoYCuenta extends StatelessWidget {
  const _SaludoYCuenta({this.user, this.dias, this.fecha});

  final User? user;
  final int? dias;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final nombre = user?.nombre.split(' ').first ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                style: context.texts.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: DesignTokens.space1 + 2),
              Text(
                switch (dias) {
                  null => 'Tu preparación',
                  <= 0 => 'Hoy es el día',
                  1 => '1 día',
                  _ => '$dias días',
                },
                style: context.texts.displaySmall?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              if (fecha != null) ...[
                const SizedBox(height: 3),
                Text(
                  'para el ENAM · ${DateFormat('d MMM yyyy', 'es').format(fecha!)}',
                  style: context.texts.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        _Avatar(user: user),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Perfil y ajustes',
      button: true,
      child: InkWell(
        onTap: () => context.push(Routes.settings),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: Container(
          // 44 es el mínimo táctil que pide el diseño de esta pantalla.
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            _iniciales(user?.nombre),
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  static String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '·';
    return nombre
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }
}

/// Retomar la sesión interrumpida (RF-15), dentro del hero.
class _TarjetaRetomar extends StatelessWidget {
  const _TarjetaRetomar({required this.sesion});

  final ResumableSession sesion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3 + 2,
        vertical: DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
      ),
      child: Row(
        children: [
          const Icon(Symbols.play_circle, size: 26, fill: 1, color: Colors.white),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sesion.titulo,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sesion.detalle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.25,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          // Botón blanco sobre el degradado: es la acción principal de la
          // pantalla y tiene que ganar al fondo.
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
            child: InkWell(
              // Un simulacro a medias no se retoma en la pantalla de práctica:
              // tiene cronómetro, grilla de 180 y nada de retroalimentación.
              // Mandarlo a la de práctica enseñaba las claves de un examen en
              // curso.
              onTap: () => context.push(
                sesion.esSimulacro
                    ? Routes.simulacroSessionOf(sesion.sessionId)
                    : Routes.practiceSessionOf(sesion.sessionId),
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space4 + 2,
                ),
                child: Text(
                  'Seguir',
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DesignTokens.brandDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
