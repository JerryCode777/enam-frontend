import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/estudio.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../session/domain/session_models.dart';
import '../../session/presentation/widgets/option_card.dart';

/// Galería interna de componentes (plan §3). **Solo en desarrollo.**
///
/// Muestra cada pieza del sistema visual en sus estados —normal, deshabilitado,
/// cargando, error, texto largo— y en los dos temas, uno al lado del otro con
/// el interruptor de arriba. Sirve para revisar un cambio de token de un
/// vistazo, sin recorrer la app buscando dónde se usa.
///
/// La ruta (`/dev/componentes`) no existe en una build de release: la registra
/// el router solo con `!kReleaseMode`. La web tiene la suya en la misma ruta.
///
/// Los datos de aquí son de muestra y lo dicen: nada de esta pantalla llega a
/// un usuario.
class GaleriaComponentesScreen extends StatefulWidget {
  const GaleriaComponentesScreen({this.oscuroInicial = false, super.key});

  final bool oscuroInicial;

  @override
  State<GaleriaComponentesScreen> createState() =>
      _GaleriaComponentesScreenState();
}

class _GaleriaComponentesScreenState extends State<GaleriaComponentesScreen> {
  late bool _oscuro = widget.oscuroInicial;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _oscuro ? AppTheme.dark : AppTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Componentes'),
            actions: [
              Row(
                children: [
                  Text('Oscuro', style: context.texts.bodyMedium),
                  Switch(
                    value: _oscuro,
                    onChanged: (v) => setState(() => _oscuro = v),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: const [
              _Seccion('Colores', _Paleta()),
              _Seccion('Tipografía', _Tipografia()),
              _Seccion('Botones', _Botones()),
              _Seccion('Campos y selectores', _Campos()),
              _Seccion('Etiquetas y avisos', _Avisos()),
              _Seccion('Siguiente acción', _SiguienteAccion()),
              _Seccion('Resumen métrico', _Resumen()),
              _Seccion('Filas de área', _Filas()),
              _Seccion('Alternativas', _Alternativas()),
              _Seccion('Carga, vacío y error', _Estados()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo, this.contenido);

  final String titulo;
  final Widget contenido;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: context.texts.headlineMedium),
          const SizedBox(height: DesignTokens.space3),
          contenido,
        ],
      ),
    );
  }
}

class _Paleta extends StatelessWidget {
  const _Paleta();

  @override
  Widget build(BuildContext context) {
    final s = context.scheme;
    final muestras = <(String, Color, Color)>[
      ('bg', Theme.of(context).scaffoldBackgroundColor, s.onSurface),
      ('surface', s.surface, s.onSurface),
      ('bg-secondary', s.surfaceContainer, s.onSurface),
      ('action', s.primary, s.onPrimary),
      ('border', s.outline, s.surface),
      ('border-subtle', s.outlineVariant, s.onSurface),
      ('text', s.onSurface, s.surface),
      ('text-secondary', s.onSurfaceVariant, s.surface),
      ('brand (decorativo)', DesignTokens.brand, DesignTokens.textPrimaryLight),
    ];

    return Wrap(
      spacing: DesignTokens.space2,
      runSpacing: DesignTokens.space2,
      children: [
        for (final (nombre, fondo, texto) in muestras)
          Container(
            width: 104,
            height: 64,
            padding: const EdgeInsets.all(DesignTokens.space2),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: s.outlineVariant),
            ),
            child: Text(
              nombre,
              style: TextStyle(
                color: texto,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _Tipografia extends StatelessWidget {
  const _Tipografia();

  @override
  Widget build(BuildContext context) {
    final t = context.texts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Título de pantalla 30/800', style: t.headlineLarge),
        Text('Título 24/800', style: t.headlineMedium),
        Text('Subtítulo 18/700', style: t.titleMedium),
        Text(
          'Cuerpo 16/400. Texto de interfaz y alternativas.',
          style: t.bodyLarge,
        ),
        Text('Secundario 14/400', style: t.bodyMedium),
        const SizedBox(height: DesignTokens.space3),
        Text(
          'Caso clínico 17/1,6. Varón de 62 años con dolor torácico opresivo '
          'de dos horas de evolución, diaforesis y náuseas. PA 150/90 mmHg.',
          style: AppTheme.clinicalCase(context),
        ),
        const SizedBox(height: DesignTokens.space3),
        // Nunito trae las cifras con ancho fijo: el cronómetro no baila.
        Text('01:59:58 · S/ 129 · 1.234', style: t.headlineMedium),
      ],
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnamButton(label: 'Primario', onPressed: () {}),
        const SizedBox(height: DesignTokens.space2),
        const EnamButton(label: 'Primario deshabilitado', onPressed: null),
        const SizedBox(height: DesignTokens.space2),
        EnamButton(label: 'Cargando', loading: true, onPressed: () {}),
        const SizedBox(height: DesignTokens.space2),
        EnamButton(
          label: 'Una etiqueta muy larga que no cabe en una línea del botón',
          icon: Symbols.arrow_forward,
          onPressed: () {},
        ),
        const SizedBox(height: DesignTokens.space2),
        EnamOutlinedButton(label: 'Secundario', onPressed: () {}),
        const SizedBox(height: DesignTokens.space2),
        TextButton(onPressed: () {}, child: const Text('Texto')),
      ],
    );
  }
}

class _Campos extends StatefulWidget {
  const _Campos();

  @override
  State<_Campos> createState() => _CamposState();
}

class _CamposState extends State<_Campos> {
  int _cantidad = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Correo')),
        const SizedBox(height: DesignTokens.space3),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Contraseña',
            errorText: 'Tiene que tener al menos 8 caracteres',
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        const TextField(
          enabled: false,
          decoration: InputDecoration(labelText: 'Deshabilitado'),
        ),
        const SizedBox(height: DesignTokens.space3),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 10, label: Text('10')),
            ButtonSegment(value: 20, label: Text('20')),
            ButtonSegment(value: 40, label: Text('40')),
          ],
          selected: {_cantidad},
          onSelectionChanged: (v) => setState(() => _cantidad = v.first),
        ),
      ],
    );
  }
}

class _Avisos extends StatelessWidget {
  const _Avisos();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            EtiquetaEstado(texto: 'Descargada', tipo: BannerKind.success),
            EtiquetaEstado(texto: 'Por sincronizar', tipo: BannerKind.warning),
            EtiquetaEstado(texto: 'Falló', tipo: BannerKind.error),
            EtiquetaEstado(texto: 'Muestra', tipo: BannerKind.info),
          ],
        ),
        SizedBox(height: DesignTokens.space3),
        StateBanner(message: 'Aviso informativo.'),
        SizedBox(height: DesignTokens.space2),
        StateBanner(kind: BannerKind.success, message: 'Todo se guardó.'),
        SizedBox(height: DesignTokens.space2),
        StateBanner(
          kind: BannerKind.warning,
          message:
              'Aviso con texto largo para comprobar que el renglón se parte '
              'bien y el icono se queda arriba, alineado con la primera línea.',
        ),
        SizedBox(height: DesignTokens.space2),
        StateBanner(kind: BannerKind.error, message: 'No pudimos guardar.'),
        SizedBox(height: DesignTokens.space3),
        TituloSeccion('Título de sección', enlace: 'Ver todo', onEnlace: _nada),
      ],
    );
  }
}

class _SiguienteAccion extends StatelessWidget {
  const _SiguienteAccion();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BloqueSiguienteAccion(
          antetitulo: 'Tienes una práctica a medias',
          titulo: 'Continúa tu práctica',
          detalle: 'Pregunta 8 de 20 · ejemplo',
          progreso: 7 / 20,
          accion: 'Retomar',
          onAccion: () {},
        ),
        const SizedBox(height: DesignTokens.space3),
        BloqueSiguienteAccion(
          antetitulo: 'Tu siguiente paso',
          titulo: 'Practica Medicina',
          criterio: 'Pesa 40 preguntas en el ENAM y vas en 52 % de acierto.',
          accion: 'Practicar Medicina',
          onAccion: () {},
          secundaria: 'Elegir otra área',
          onSecundaria: () {},
        ),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    return const ResumenMetrico(
      metricas: [
        (
          valor: '262',
          etiqueta: 'preguntas vistas',
          detalle: 'hasta hoy',
        ),
        (valor: '66 %', etiqueta: 'de acierto', detalle: 'en 262'),
        (valor: '—', etiqueta: 'simulacros', detalle: 'ninguno aún'),
      ],
    );
  }
}

class _Filas extends StatelessWidget {
  const _Filas();

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          FilaDeArea(
            nombre: 'Medicina',
            color: AreaColors.of('medicina', b),
            peso: 40,
            acierto: 0.63,
            onTap: () {},
          ),
          const Divider(),
          FilaDeArea(
            nombre: 'Salud pública y gestión de establecimientos de salud',
            color: AreaColors.of('gestion', b),
            peso: 10,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _Alternativas extends StatelessWidget {
  const _Alternativas();

  @override
  Widget build(BuildContext context) {
    QuestionOption op(String id, String texto) =>
        QuestionOption(id: id, texto: texto);
    return Column(
      children: [
        for (final (letra, visual, texto) in [
          ('A', OptionVisual.normal, 'Sin seleccionar'),
          ('B', OptionVisual.seleccionada, 'Seleccionada, sin confirmar'),
          ('C', OptionVisual.incorrecta, 'Tu respuesta, incorrecta'),
          ('D', OptionVisual.correcta, 'La correcta'),
        ]) ...[
          OptionCard(
            opcion: op(letra, texto),
            letra: letra,
            visual: visual,
            onTap:
                visual == OptionVisual.normal ||
                    visual == OptionVisual.seleccionada
                ? () {}
                : null,
          ),
          const SizedBox(height: DesignTokens.space2),
        ],
      ],
    );
  }
}

class _Estados extends StatelessWidget {
  const _Estados();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SkeletonBox(height: 96, radius: DesignTokens.radiusXl),
        const SizedBox(height: DesignTokens.space2),
        const SkeletonBox(height: 56, radius: DesignTokens.radiusLg),
        const SizedBox(height: DesignTokens.space3),
        const Card(
          child: EstadoVacio(
            titulo: 'Aún no marcaste preguntas',
            mensaje: 'Toca el marcador en una pregunta para repasarla aquí.',
            icono: Symbols.bookmark,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        Card(
          child: EstadoVacio.error(
            mensaje: 'Revisa tu conexión y vuelve a intentarlo.',
            onReintentar: () {},
          ),
        ),
      ],
    );
  }
}

void _nada() {}
