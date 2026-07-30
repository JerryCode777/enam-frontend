import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../shared/widgets/brand_gradient.dart';

/// Pantalla 1.2 — onboarding de 3 pasos sobre el degradado de marca.
///
/// Se muestra **una sola vez**: al salir por cualquier vía (terminar o
/// "Saltar") se marca como visto y el router ya no vuelve a traer aquí.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pasos = <_Paso>[
    _Paso(
      icono: Symbols.quiz,
      titulo: 'Simulacros como el real',
      subtitulo: '180 preguntas · 3 horas · nota al instante.',
      cta: 'Siguiente',
      puntos: [
        (Symbols.timer, 'Cronómetro y grilla reales'),
        (Symbols.grade, 'Nota vigesimal al enviar'),
        (Symbols.trophy, 'Ranking nacional en vivo'),
      ],
    ),
    _Paso(
      icono: Symbols.account_tree,
      titulo: 'El temario oficial',
      subtitulo: 'El documento del que sale el examen.',
      cta: 'Siguiente',
      puntos: [
        (Symbols.balance, '10 áreas con su peso real'),
        (Symbols.play_circle, 'Practica desde cualquier punto'),
        (Symbols.monitoring, 'Tu avance siempre visible'),
      ],
    ),
    _Paso(
      icono: Symbols.download,
      titulo: 'Estudia sin señal',
      subtitulo: 'Perfecto para la guardia o el bus.',
      cta: 'Crear cuenta',
      puntos: [
        (Symbols.cloud_download, 'Descarga áreas completas'),
        (Symbols.sync, 'Se sincroniza solo'),
        (Symbols.battery_saver, 'Liviano y comprimido'),
      ],
    ),
  ];

  bool get _esUltimo => _page == _pasos.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sale del onboarding para no volver.
  ///
  /// Se marca como visto **antes** de navegar: si se hiciera después, el
  /// redirect del router se dispararía con la bandera aún en falso y traería
  /// al usuario de vuelta aquí.
  Future<void> _salir(String destino) async {
    await ref.read(startupProvider.notifier).marcarOnboardingVisto();
    if (mounted) context.go(destino);
  }

  void _siguiente() {
    if (_esUltimo) {
      _salir(Routes.register);
    } else {
      _controller.nextPage(
        duration: Motion.duration(context, Motion.normal),
        curve: Motion.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandGradient(
        circuloSecundarioArriba: false,
        formaInferior: false,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space2,
                    vertical: DesignTokens.space1,
                  ),
                  child: TextButton(
                    onPressed: () => _salir(Routes.login),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.8),
                    ),
                    child: const Text(
                      'Saltar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pasos.length,
                  itemBuilder: (context, i) => _VistaPaso(paso: _pasos[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space7,
                  DesignTokens.space4,
                  DesignTokens.space7,
                  DesignTokens.space6 + 2,
                ),
                child: Column(
                  children: [
                    _BotonClaro(
                      label: _pasos[_page].cta,
                      onPressed: _siguiente,
                    ),
                    const SizedBox(height: DesignTokens.space3 + 2),
                    _Puntos(
                      total: _pasos.length,
                      activo: _page,
                      onTap: (i) => _controller.animateToPage(
                        i,
                        duration: Motion.duration(context, Motion.normal),
                        curve: Motion.standard,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Paso {
  const _Paso({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.cta,
    required this.puntos,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String cta;

  /// Icono y texto de cada viñeta.
  final List<(IconData, String)> puntos;
}

class _VistaPaso extends StatelessWidget {
  const _VistaPaso({required this.paso});

  final _Paso paso;

  @override
  Widget build(BuildContext context) {
    // Desplazable a propósito: con la fuente del sistema al máximo, la
    // ilustración más el título más las tres viñetas no entran en 360 × 640.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space7),
      child: Column(
        children: [
          const SizedBox(height: DesignTokens.space4),
          _Ilustracion(icono: paso.icono),
          const SizedBox(height: DesignTokens.space4 + 2),
          Text(
            paso.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x1F000000)),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space4 + 2),
          Text(
            paso.subtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: DesignTokens.space4 + 2),
          _TarjetaPuntos(puntos: paso.puntos),
          const SizedBox(height: DesignTokens.space4),
        ],
      ),
    );
  }
}

/// El tile blanco con el icono, flotando en bucle.
///
/// El diseño lo marca como hueco para el arte definitivo; mientras tanto va el
/// icono, que ya transmite el tema de cada paso.
class _Ilustracion extends StatefulWidget {
  const _Ilustracion({required this.icono});

  final IconData icono;

  @override
  State<_Ilustracion> createState() => _IlustracionState();
}

class _IlustracionState extends State<_Ilustracion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Icon(
        widget.icono,
        size: 74,
        fill: 1,
        color: const Color(0xFF2382B5),
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Sube 9 px y vuelve, una vez por ciclo.
        final t = _c.value;
        final vaiven = (t < 0.5 ? t : 1 - t) * 2;
        return Transform.translate(
          offset: Offset(0, -9 * Curves.easeInOut.transform(vaiven)),
          child: child,
        );
      },
      child: tile,
    );
  }
}

/// La tarjeta translúcida con las tres viñetas del paso.
class _TarjetaPuntos extends StatelessWidget {
  const _TarjetaPuntos({required this.puntos});

  final List<(IconData, String)> puntos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space1 + 2,
      ),
      child: Column(
        children: [
          for (var i = 0; i < puntos.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.space2 + 3,
              ),
              decoration: i == 0
                  ? null
                  : BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.space2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(puntos[i].$1, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: Text(
                      puntos[i].$2,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón blanco sobre el degradado.
///
/// No es el `EnamButton` de la app: ese lleva el degradado de marca, que sobre
/// este fondo desaparecería.
class _BotonClaro extends StatelessWidget {
  const _BotonClaro({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2382B5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            const Icon(Symbols.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Puntos extends StatelessWidget {
  const _Puntos({
    required this.total,
    required this.activo,
    required this.onTap,
  });

  final int total;
  final int activo;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Semantics(
            label: 'Paso ${i + 1} de $total',
            selected: i == activo,
            button: true,
            child: GestureDetector(
              onTap: () => onTap(i),
              // El punto mide 8 px de alto pero el área táctil tiene que ser
              // usable: el rectángulo transparente la lleva a 24 px.
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedContainer(
                  duration: Motion.duration(context, Motion.normal),
                  curve: Motion.standard,
                  width: i == activo ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: i == activo ? 1 : 0.4,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
