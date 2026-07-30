import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/providers.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../auth/domain/auth_models.dart';

/// Cabecera del inicio, en degradado.
///
/// Reúne saludo, avatar, cuenta regresiva, la línea de ECG animada y la tarjeta
/// para retomar la sesión. Va todo junto a propósito: es lo primero que el
/// usuario mira al abrir la app y responde sus dos preguntas inmediatas —
/// cuánto falta y por dónde iba.
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
          bottom: Radius.circular(DesignTokens.radiusXl + 4),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl + 4),
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
                  DesignTokens.space2 + 2,
                  DesignTokens.space5,
                  DesignTokens.space4 + 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SaludoYAvatar(user: user),
                    const SizedBox(height: DesignTokens.space2),
                    _CuentaRegresiva(dias: dias, fecha: fecha),
                    const SizedBox(height: DesignTokens.space3),
                    _TarjetaRetomar(sesion: sesion),
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

class _SaludoYAvatar extends StatelessWidget {
  const _SaludoYAvatar({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final nombre = user?.nombre.split(' ').first ?? '';

    return Row(
      children: [
        Expanded(
          child: Text(
            nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
            style: context.texts.bodyMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
        Semantics(
          label: 'Perfil y ajustes',
          button: true,
          child: InkWell(
            onTap: () => context.push(Routes.settings),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: Container(
              // 42 de caja visible dentro de un área táctil de 48.
              width: DesignTokens.minTouchTarget,
              height: DesignTokens.minTouchTarget,
              alignment: Alignment.center,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _iniciales(user?.nombre),
                  style: context.texts.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

class _CuentaRegresiva extends StatelessWidget {
  const _CuentaRegresiva({this.dias, this.fecha});

  final int? dias;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (dias) {
                  null => 'Tu preparación',
                  <= 0 => 'Hoy es el día',
                  1 => '1 día',
                  _ => '$dias días',
                },
                style: context.texts.displaySmall?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              if (fecha != null) ...[
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'para el ENAM · ${DateFormat('d MMM yyyy', 'es').format(fecha!)}',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space2 + 2),
        const _EcgAnimado(),
      ],
    );
  }
}

/// Línea de electrocardiograma que recorre el trazo, como en el diseño.
///
/// Se detiene si el sistema pidió reducir el movimiento: es decorativa y no
/// aporta información, así que es la primera que sobra.
class _EcgAnimado extends StatefulWidget {
  const _EcgAnimado();

  @override
  State<_EcgAnimado> createState() => _EcgAnimadoState();
}

class _EcgAnimadoState extends State<_EcgAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 30,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _EcgPainter(
            avance: Motion.reduced(context) ? 1 : _c.value,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  const _EcgPainter({required this.avance, required this.color});

  /// De 0 a 1: dónde va el segmento que se ilumina.
  final double avance;
  final Color color;

  static const _puntos = <Offset>[
    Offset(0, 15),
    Offset(34, 15),
    Offset(39, 5),
    Offset(45, 25),
    Offset(50, 9),
    Offset(55, 15),
    Offset(84, 15),
    Offset(89, 6),
    Offset(95, 22),
    Offset(100, 15),
    Offset(120, 15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final ex = size.width / 120;
    final ey = size.height / 30;

    final trazo = Path();
    for (var i = 0; i < _puntos.length; i++) {
      final p = Offset(_puntos[i].dx * ex, _puntos[i].dy * ey);
      i == 0 ? trazo.moveTo(p.dx, p.dy) : trazo.lineTo(p.dx, p.dy);
    }

    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Base tenue, para que el trazo completo se intuya siempre.
    canvas.drawPath(trazo, Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Segmento que recorre: se extrae del path con PathMetrics en vez de
    // simular el dash, para que siga la curva exacta.
    for (final metrica in trazo.computeMetrics()) {
      final largo = metrica.length;
      const proporcion = 0.22;
      final inicio = (avance * (1 + proporcion) - proporcion) * largo;
      final fin = inicio + proporcion * largo;

      canvas.drawPath(
        metrica.extractPath(inicio.clamp(0, largo), fin.clamp(0, largo)),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.avance != avance;
}

/// Retomar la sesión interrumpida (RF-15), dentro del hero.
///
/// Si no hay ninguna, ocupa el mismo sitio con la sugerencia de por dónde
/// empezar: el hueco se vería raro y la sugerencia es útil de todos modos.
class _TarjetaRetomar extends StatelessWidget {
  const _TarjetaRetomar({this.sesion});

  final ResumableSession? sesion;

  @override
  Widget build(BuildContext context) {
    final hay = sesion != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3 + 2,
        vertical: DesignTokens.space2 + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            hay ? Symbols.play_circle : Symbols.lightbulb,
            size: 22,
            fill: 1,
            color: Colors.white,
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sesion?.titulo ?? 'Empieza por lo que más pesa',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  sesion?.detalle ?? 'Medicina son 40 de las 180 preguntas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          // Botón blanco sobre el degradado: es la acción principal de la
          // pantalla y tiene que ganar al fondo.
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
            child: InkWell(
              onTap: () => context.push(
                hay
                    ? Routes.practiceSessionOf(sesion!.sessionId)
                    : Routes.practiceConfig,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space4,
                ),
                child: Text(
                  hay ? 'Seguir' : 'Practicar',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
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
