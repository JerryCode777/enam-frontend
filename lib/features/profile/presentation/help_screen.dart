import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';

/// Ayuda y contacto.
///
/// **No venía en el diseño.** Play Store exige un canal de contacto para
/// publicar, y las preguntas frecuentes ahorran soporte: las cuatro primeras de
/// abajo son las que este producto va a recibir sí o sí.
///
/// El correo de soporte se abre con el contexto ya escrito (versión, entorno,
/// modelo). Pedirle esos datos al usuario en el hilo alarga cada caso un día.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  static const _correo = 'soporte@enamprep.pe';

  String _version = '';

  @override
  void initState() {
    super.initState();
    _cargarVersion();
  }

  Future<void> _cargarVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version} (${info.buildNumber})');
    }
  }

  static const _faq = <({String pregunta, String respuesta})>[
    (
      pregunta: '¿La nota proyectada predice mi resultado real?',
      respuesta:
          'No. Es una estimación calculada con tu porcentaje de acierto por '
          'área, ponderado por el peso de cada área en el examen. Sirve para '
          'ver tendencia y decidir qué estudiar, no para anticipar tu nota.',
    ),
    (
      pregunta: '¿Por qué hay temas sin preguntas?',
      respuesta:
          'El banco se carga por áreas y de forma progresiva. Un tema marcado '
          'como "disponible pronto" todavía no tiene preguntas publicadas; no '
          'es un error de la app.',
    ),
    (
      pregunta: '¿El simulacro nacional es oficial?',
      respuesta:
          'No. Es un simulacro de práctica dentro de la app, con fecha y hora '
          'programadas para que todos rindan al mismo tiempo. No tiene relación '
          'con ASPEFAM ni con tu inscripción al ENAM real.',
    ),
    (
      pregunta: 'Yapeé y sigo sin Premium',
      respuesta:
          'La verificación de Yape es manual y suele tomar menos de 2 horas en '
          'horario de atención. Si pasó más tiempo, escríbenos con la captura '
          'de tu operación y lo activamos.',
    ),
    (
      pregunta: '¿Por qué las preguntas tienen mi correo encima?',
      respuesta:
          'Es una marca de agua para desalentar la difusión del banco, que es '
          'el trabajo de nuestro equipo editorial. No se ve en la impresión ni '
          'afecta tu práctica.',
    ),
    (
      pregunta: 'Encontré una pregunta con la clave equivocada',
      respuesta:
          'Repórtala desde el botón "Reportar" en la pantalla de '
          'retroalimentación. Un editor la revisa y, si corresponde, la '
          'corrige o la retira.',
    ),
    (
      pregunta: '¿Puedo usar la app sin internet?',
      respuesta:
          'Con Premium puedes descargar áreas completas y practicar sin '
          'conexión. Tus respuestas se sincronizan al reconectar. Los '
          'simulacros nacionales siempre requieren conexión.',
    ),
    (
      pregunta: 'Si cancelo Premium, ¿pierdo mi progreso?',
      respuesta:
          'No. Tu historial, tus estadísticas y tus preguntas marcadas se '
          'conservan. Vuelves al plan gratis: 20 preguntas al día y el '
          'simulacro de muestra.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Ayuda'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                DesignTokens.space4,
                DesignTokens.space4,
                DesignTokens.space8,
              ),
              children: [
                FadeUp(child: _Contacto(onEscribir: _escribir)),
                const SizedBox(height: DesignTokens.space5),
                FadeUp(
                  index: 1,
                  child: Text(
                    'PREGUNTAS FRECUENTES',
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < _faq.length; i++)
                        _Pregunta(
                          item: _faq[i],
                          esUltima: i == _faq.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                FadeUp(index: 2, child: _Version(version: _version)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el correo con el contexto técnico ya puesto.
  Future<void> _escribir() async {
    final user = ref.read(currentUserProvider);

    final cuerpo = Uri.encodeComponent(
      '\n\n---\n'
      'No borres esta parte, nos ayuda a resolver más rápido:\n'
      'Versión: $_version\n'
      'Entorno: ${AppConfig.environment.name}\n'
      'Cuenta: ${user?.email ?? "sin sesión"}\n',
    );
    final asunto = Uri.encodeComponent('Ayuda con ENAM Prep');

    final uri = Uri.parse('mailto:$_correo?subject=$asunto&body=$cuerpo');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      // Sin cliente de correo configurado el mailto falla en silencio, así que
      // se muestra la dirección para que pueda copiarla.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escríbenos a $_correo')),
      );
    }
  }
}

class _Contacto extends StatelessWidget {
  const _Contacto({required this.onEscribir});

  final VoidCallback onEscribir;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return InkWell(
      onTap: onEscribir,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: states.info.tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Row(
          children: [
            Icon(Symbols.mail, size: 24, fill: 1, color: states.info.onTint),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escríbenos',
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  Text(
                    'Respondemos en horario de atención, de lunes a sábado.',
                    style: context.texts.bodySmall?.copyWith(
                      color: states.info.onTint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, size: 20, color: states.info.onTint),
          ],
        ),
      ),
    );
  }
}

class _Pregunta extends StatefulWidget {
  const _Pregunta({required this.item, required this.esUltima});

  final ({String pregunta, String respuesta}) item;
  final bool esUltima;

  @override
  State<_Pregunta> createState() => _PreguntaState();
}

class _PreguntaState extends State<_Pregunta> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: widget.esUltima
            ? null
            : Border(bottom: BorderSide(color: context.scheme.outlineVariant)),
      ),
      child: InkWell(
        onTap: () => setState(() => _abierta = !_abierta),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.pregunta,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Icon(
                    _abierta ? Symbols.expand_less : Symbols.expand_more,
                    size: 20,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_abierta) ...[
                const SizedBox(height: DesignTokens.space3),
                Text(
                  widget.item.respuesta,
                  style: context.texts.bodyMedium?.copyWith(
                    height: DesignTokens.lineHeightRelaxed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Version extends StatelessWidget {
  const _Version({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'ENAM Prep${version.isEmpty ? "" : " · $version"}',
            style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
          ),
          Text(
            'Jaks Tech SAC',
            style: context.texts.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
