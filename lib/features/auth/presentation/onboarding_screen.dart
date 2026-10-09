import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/figura_de_marca.dart';
import '../../../shared/widgets/fondo_claro.dart';

/// Pantalla 1.2 — presentación, **una sola pantalla**, en el tema claro.
///
/// Era un carrusel de tres pasos: para llegar a crear la cuenta había que
/// deslizar o pulsar «Siguiente» dos veces. Ahora el beneficio y un ejemplo en
/// una pantalla, y la acción directa (plan §6). Y va en claro —fondo de la app
/// con dos halos de marca— y no sobre el degradado azul marino: el producto
/// pidió la primera impresión en el tema claro, igual que la web.
///
/// **La tarjeta de ejemplo nunca queda cortada** por los botones fijos de
/// abajo. En pantallas bajas ([_Medidas.compacta]) todo se ajusta para caber
/// —título algo menor, beneficios más cortos, figura más chica, el porqué en
/// una frase—, y si aun así no cabe (letra del sistema ampliada), la zona de
/// botones muestra un borde arriba: se lee como el límite de algo que se
/// desplaza, no como una tarjeta partida.
///
/// Se muestra **una sola vez**: al salir por cualquier vía se marca como visto
/// y el router ya no vuelve a traer aquí.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _scroll = ScrollController();

  /// Si el contenido no cabe y queda algo por debajo de los botones.
  bool _desborda = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_medir);
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _medir() {
    if (!_scroll.hasClients || !mounted) return;
    final desborda =
        _scroll.position.maxScrollExtent > 0 &&
        _scroll.offset < _scroll.position.maxScrollExtent;
    if (desborda != _desborda) setState(() => _desborda = desborda);
  }

  /// Sale para no volver. Se marca como visto **antes** de navegar: si se
  /// hiciera después, el redirect del router se dispararía con la bandera aún
  /// en falso y traería al usuario de vuelta aquí.
  Future<void> _salir(String destino) async {
    await ref.read(startupProvider.notifier).marcarOnboardingVisto();
    if (mounted) context.go(destino);
  }

  @override
  Widget build(BuildContext context) {
    final m = _Medidas.de(context);

    return Scaffold(
      body: FondoClaro(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _medir();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.space6,
                      m.compacta ? DesignTokens.space4 : DesignTokens.space6,
                      DesignTokens.space6,
                      DesignTokens.space4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Presentacion(m: m),
                        SizedBox(height: m.separacionEjemplo),
                        _Ejemplo(m: m),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: _desborda
                          ? DesignTokens.borderSubtleLight
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space6,
                    DesignTokens.space3,
                    DesignTokens.space6,
                    DesignTokens.space3,
                  ),
                  child: _Acciones(
                    onCrear: () => _salir(Routes.register),
                    onEntrar: () => _salir(Routes.login),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las medidas que cambian con el alto disponible.
///
/// «Compacta» es un teléfono de hasta ~850 dp de alto (13 mini, 14 Pro): ahí
/// todo se ajusta un poco para que el ejemplo quepa entero sobre los botones.
class _Medidas {
  const _Medidas({required this.compacta});

  factory _Medidas.de(BuildContext context) {
    final media = MediaQuery.of(context);
    final alto = media.size.height - media.padding.vertical;
    return _Medidas(compacta: alto < 800);
  }

  final bool compacta;

  double get titulo => compacta ? 26 : 30;
  double get marca => compacta ? 32 : 40;
  double get beneficio => compacta ? 15 : 16;
  double get separacionEjemplo =>
      compacta ? DesignTokens.space4 : DesignTokens.space5;

  /// Parte del ancho que ocupa la figura.
  double get figura => compacta ? 0.33 : 0.4;

  /// Cuánto baja la figura: cruza el hueco y queda 16 px detrás de la tarjeta,
  /// que la tapa. Así no se ve el corte recto de la imagen.
  double get solapeFigura => separacionEjemplo + 16;
}

class _Presentacion extends StatelessWidget {
  const _Presentacion({required this.m});

  final _Medidas m;

  @override
  Widget build(BuildContext context) {
    const tinta = DesignTokens.textPrimaryLight;
    const suave = DesignTokens.textSecondaryLight;

    // Cortos a propósito: a la izquierda de la figura, en un teléfono chico,
    // cada renglón de más empuja el ejemplo hacia los botones.
    final beneficios = [
      (Symbols.quiz, 'La explicación de cada alternativa'),
      (
        Symbols.timer,
        'Simulacros de ${Blueprint.totalQuestions} preguntas en '
            '${Blueprint.examDuration.inHours} horas',
      ),
      (Symbols.download, 'Estudia sin señal lo que descargues'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BrandMarkTile(size: m.marca, radio: m.marca * 0.3),
            const SizedBox(width: DesignTokens.space2 + 2),
            const Text(
              'ENAM Prep',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tinta,
              ),
            ),
          ],
        ),
        SizedBox(
          height: m.compacta ? DesignTokens.space4 : DesignTokens.space6,
        ),
        Semantics(
          header: true,
          child: Text(
            'Practica para el ENAM y entiende cada respuesta',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: m.titulo,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: tinta,
            ),
          ),
        ),
        SizedBox(
          height: m.compacta ? DesignTokens.space3 : DesignTokens.space4,
        ),
        // Los beneficios a la izquierda y la figura a la derecha, apoyada
        // abajo. Su borde inferior es un corte a la cintura: se esconde detrás
        // de la tarjeta de ejemplo, que se pinta después y la tapa.
        LayoutBuilder(
          builder: (context, c) {
            final ancho = (c.maxWidth * m.figura).clamp(92.0, 190.0);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (icono, texto) in beneficios)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: DesignTokens.space2,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(
                                    icono,
                                    size: 20,
                                    color: DesignTokens.actionLight,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.space3),
                                Expanded(
                                  child: Text(
                                    texto,
                                    style: TextStyle(
                                      fontFamily: DesignTokens.fontFamily,
                                      fontSize: m.beneficio,
                                      height: 1.35,
                                      color: suave,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  SizedBox(
                    width: ancho,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: Offset(0, m.solapeFigura),
                        child: FiguraDeMarca.brazosCruzados(ancho: ancho),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Un ejemplo de cómo se ve una pregunta respondida, **rotulado como tal**.
///
/// El contenido es deliberadamente de manual —la adrenalina intramuscular
/// como primera línea en la anafilaxia— para que el ejemplo no pueda enseñar
/// nada discutible. Lo que muestra es la forma: el veredicto y el porqué.
class _Ejemplo extends StatelessWidget {
  const _Ejemplo({required this.m});

  final _Medidas m;

  @override
  Widget build(BuildContext context) {
    final ok = context.states.success;
    final scheme = context.scheme;
    final hueco = m.compacta ? DesignTokens.space2 + 2 : DesignTokens.space3;

    return Semantics(
      label:
          'Ejemplo de pregunta respondida. En la anafilaxia, el tratamiento '
          'de primera línea es la adrenalina intramuscular.',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(
          m.compacta ? DesignTokens.space3 + 2 : DesignTokens.space4,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF102338).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EJEMPLO',
              style: context.texts.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: DesignTokens.space1 + 2),
            Text(
              '¿Cuál es el tratamiento de primera línea en la anafilaxia?',
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            SizedBox(height: hueco),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space2 + 2,
              ),
              decoration: BoxDecoration(
                color: ok.tint,
                border: Border.all(color: ok.base, width: 1.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.check_circle,
                    size: 20,
                    fill: 1,
                    color: ok.onTint,
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Text(
                      'Adrenalina intramuscular',
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ok.onTint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: hueco),
            Text(
              m.compacta
                  ? 'Por qué: revierte la vasodilatación y el broncoespasmo.'
                  : 'Por qué: revierte la vasodilatación y el broncoespasmo. '
                        'Los antihistamínicos y los corticoides no la '
                        'sustituyen.',
              style: context.texts.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones({required this.onCrear, required this.onEntrar});

  final VoidCallback onCrear;
  final VoidCallback onEntrar;

  @override
  Widget build(BuildContext context) {
    // El principal sólido y el secundario con borde, como en la web.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnamButton(label: 'Crear cuenta gratis', onPressed: onCrear),
        const SizedBox(height: DesignTokens.space2),
        // La regla real del servidor (D-02): el día de prueba no empieza al
        // registrarse sino con la primera práctica.
        const Text(
          'Tu prueba de 24 horas empieza con tu primera práctica.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.textSecondaryLight,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        EnamOutlinedButton(
          label: 'Ya tengo cuenta',
          height: DesignTokens.minTouchTarget,
          onPressed: onEntrar,
        ),
      ],
    );
  }
}
