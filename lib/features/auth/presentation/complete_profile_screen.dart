import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/auth_models.dart';

/// Pantalla 1.7 — perfil inicial (RF-04).
///
/// Nota de copy, tomada del diseño: la condición `repitiente` se muestra como
/// **"Voy a rendirlo de nuevo"**. Cerca del 43 % del público ya desaprobó y
/// vuelve a rendir; la etiqueta técnica se guarda en el dato, no se le enseña.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nombre = TextEditingController();

  String? _universidad;
  StudentCondition? _condicion;
  DateTime? _fechaObjetivo;
  String? _fechaEtiqueta;

  String? _nombreError;
  bool _loading = false;

  /// Etiqueta amable de cada condición. `repitiente` no se nombra así en la UI.
  static const _labels = {
    StudentCondition.preinterno: 'Preinterno(a)',
    StudentCondition.interno: 'Interno(a)',
    StudentCondition.egresado: 'Egresado(a)',
    StudentCondition.repitiente: 'Voy a rendirlo de nuevo',
  };

  /// Fechas oficiales conocidas. El usuario también puede elegir una libre.
  static final _fechasOficiales = <({String label, DateTime fecha})>[
    (label: 'ENAM Ordinario', fecha: DateTime(2026, 12, 12)),
    (label: 'ENAM Extraordinario', fecha: DateTime(2027, 4, 17)),
  ];

  static const _universidades = [
    'UNMSM',
    'UNSA',
    'UPCH',
    'UNT',
    'UNFV',
    'USMP',
    'UCSM',
    'UNAP',
    'UNC',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nombre.text = user.nombre;
      _universidad = user.universidad;
      _condicion = user.condicion;
      _fechaObjetivo = user.fechaObjetivo;
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  bool get _completo =>
      _nombre.text.trim().isNotEmpty &&
      _universidad != null &&
      _condicion != null &&
      _fechaObjetivo != null;

  /// Días hasta la fecha elegida, o `null` si aún no eligió.
  ///
  /// El aviso reacciona a la fecha en el momento, sin esperar a guardar: es lo
  /// que hace que elegir la fecha se sienta como una decisión y no un trámite.
  int? get _diasRestantes {
    final fecha = _fechaObjetivo;
    if (fecha == null) return null;

    final hoy = DateTime.now();
    final dias = DateUtils.dateOnly(
      fecha,
    ).difference(DateUtils.dateOnly(hoy)).inDays;
    return dias > 0 ? dias : null;
  }

  Future<void> _submit() async {
    if (_loading) return;

    setState(() {
      _nombreError = _nombre.text.trim().isEmpty ? 'Ingresa tu nombre.' : null;
    });
    if (_nombreError != null || !_completo) return;

    setState(() => _loading = true);
    try {
      final user = await ref.read(authRepositoryProvider).updateProfile(
        nombre: _nombre.text.trim(),
        universidad: _universidad,
        condicion: _condicion,
        fechaObjetivo: _fechaObjetivo,
      );
      // Refresca el estado de auth: el router ve el perfil completo y deja pasar.
      if (mounted) ref.read(authControllerProvider.notifier).setUser(user);
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickUniversidad() async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _UniversidadSheet(
        opciones: _universidades,
        seleccionada: _universidad,
      ),
    );
    if (elegida != null) setState(() => _universidad = elegida);
  }

  Future<void> _pickFecha() async {
    final elegida = await showModalBottomSheet<({String? label, DateTime fecha})>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FechaSheet(oficiales: _fechasOficiales),
    );
    if (elegida == null || !mounted) return;

    if (elegida.label == null) {
      final libre = await showDatePicker(
        context: context,
        initialDate: _fechaObjetivo ?? DateTime.now().add(const Duration(days: 90)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        helpText: 'Fecha de tu examen',
      );
      if (libre != null) {
        setState(() {
          _fechaObjetivo = libre;
          _fechaEtiqueta = null;
        });
      }
      return;
    }

    setState(() {
      _fechaObjetivo = elegida.fecha;
      _fechaEtiqueta = elegida.label;
    });
  }

  String get _fechaTexto {
    final fecha = _fechaObjetivo;
    if (fecha == null) return 'Elige una fecha';
    final formato = DateFormat('d MMM yyyy', 'es').format(fecha);
    return _fechaEtiqueta == null ? formato : '$_fechaEtiqueta · $formato';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Cuéntanos dónde estás en tu preparación',
      subtitulo: 'Ajustamos tu plan y la cuenta regresiva.',
      tamanoTitulo: 26,
      tarjeta: [
        EnamTextField(
          label: 'Nombre',
          controller: _nombre,
          error: _nombreError,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          enabled: !_loading,
          onChanged: (_) => setState(() => _nombreError = null),
        ),
        _PickerField(
          label: 'Universidad',
          value: _universidad ?? 'Elige tu universidad',
          placeholder: _universidad == null,
          icon: Symbols.arrow_drop_down,
          onTap: _loading ? null : _pickUniversidad,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu situación',
              style: context.texts.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            // Wrap y no Row: "Voy a rendirlo de nuevo" es largo y a 360 px
            // tiene que poder bajar de línea sin recortarse.
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: [
                for (final entry in _labels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _condicion == entry.key,
                    onSelected: _loading
                        ? null
                        : (_) => setState(() => _condicion = entry.key),
                  ),
              ],
            ),
          ],
        ),
        _PickerField(
          label: 'Fecha objetivo',
          value: _fechaTexto,
          placeholder: _fechaObjetivo == null,
          icon: Symbols.calendar_month,
          onTap: _loading ? null : _pickFecha,
        ),
        if (_diasRestantes != null)
          AuthTintNote(
            icono: Symbols.event,
            iconoRelleno: true,
            texto: Text.rich(
              TextSpan(
                style: context.texts.bodySmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
                children: [
                  const TextSpan(text: 'Faltan '),
                  TextSpan(
                    text: '$_diasRestantes días',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: ' — buen momento para empezar.'),
                ],
              ),
            ),
          ),
        EnamButton(
          label: 'Empezar',
          loading: _loading,
          onPressed: _completo ? _submit : null,
        ),
        if (!_completo)
          Text(
            'Completa los cuatro datos para continuar.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Campo que abre un selector en vez de aceptar texto. Se ve como un campo real
/// para que el formulario se lea uniforme.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.placeholder = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space1 + 2),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyLarge?.copyWith(
                      color: placeholder
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                Icon(icon, size: 22, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UniversidadSheet extends StatefulWidget {
  const _UniversidadSheet({required this.opciones, this.seleccionada});

  final List<String> opciones;
  final String? seleccionada;

  @override
  State<_UniversidadSheet> createState() => _UniversidadSheetState();
}

class _UniversidadSheetState extends State<_UniversidadSheet> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final visibles = widget.opciones
        .where((u) => u.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.space4,
        right: DesignTokens.space4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + DesignTokens.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu universidad',
            style: context.texts.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Buscar',
              prefixIcon: Icon(Symbols.search),
            ),
            onChanged: (v) => setState(() => _filtro = v),
          ),
          const SizedBox(height: DesignTokens.space2),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: visibles.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(visibles[i]),
                trailing: widget.seleccionada == visibles[i]
                    ? const Icon(Symbols.check)
                    : null,
                onTap: () => Navigator.of(context).pop(visibles[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FechaSheet extends StatelessWidget {
  const _FechaSheet({required this.oficiales});

  final List<({String label, DateTime fecha})> oficiales;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4,
              vertical: DesignTokens.space2,
            ),
            child: Text(
              '¿Cuándo rindes?',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final opcion in oficiales)
            ListTile(
              leading: const Icon(Symbols.event),
              title: Text(opcion.label),
              subtitle: Text(
                DateFormat('d MMMM yyyy', 'es').format(opcion.fecha),
              ),
              onTap: () => Navigator.of(context).pop(opcion),
            ),
          ListTile(
            leading: const Icon(Symbols.edit_calendar),
            title: const Text('Otra fecha'),
            onTap: () => Navigator.of(
              context,
            ).pop((label: null, fecha: DateTime.now())),
          ),
          const SizedBox(height: DesignTokens.space2),
        ],
      ),
    );
  }
}
