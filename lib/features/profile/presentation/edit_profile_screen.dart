import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/enam_text_field.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../auth/domain/auth_models.dart';

/// Editar perfil (RF-04).
///
/// Lo mismo que el perfil inicial pero editable en cualquier momento. Cambiar la
/// fecha objetivo recalcula la cuenta regresiva del inicio.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nombre;
  String? _universidad;
  StudentCondition? _condicion;
  DateTime? _fechaObjetivo;

  String? _nombreError;
  bool _guardando = false;

  static const _labels = {
    StudentCondition.preinterno: 'Preinterno(a)',
    StudentCondition.interno: 'Interno(a)',
    StudentCondition.egresado: 'Egresado(a)',
    StudentCondition.repitiente: 'Voy a rendirlo de nuevo',
  };

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
    _nombre = TextEditingController(text: user?.nombre ?? '');
    _universidad = user?.universidad;
    _condicion = user?.condicion;
    _fechaObjetivo = user?.fechaObjetivo;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Editar perfil'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                FadeUp(
                  child: EnamTextField(
                    label: 'Nombre',
                    controller: _nombre,
                    error: _nombreError,
                    enabled: !_guardando,
                    onChanged: (_) {
                      if (_nombreError != null) {
                        setState(() => _nombreError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                FadeUp(
                  index: 1,
                  child: _Selector(
                    label: 'Universidad',
                    valor: _universidad ?? 'Elige tu universidad',
                    placeholder: _universidad == null,
                    icon: Symbols.arrow_drop_down,
                    onTap: _guardando ? null : _elegirUniversidad,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                FadeUp(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu situación',
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Wrap(
                        spacing: DesignTokens.space2,
                        runSpacing: DesignTokens.space2,
                        children: [
                          for (final entry in _labels.entries)
                            ChoiceChip(
                              label: Text(entry.value),
                              selected: _condicion == entry.key,
                              onSelected: _guardando
                                  ? null
                                  : (_) =>
                                        setState(() => _condicion = entry.key),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                FadeUp(
                  index: 3,
                  child: _Selector(
                    label: 'Fecha objetivo',
                    valor: _fechaObjetivo == null
                        ? 'Elige una fecha'
                        : DateFormat('d MMM yyyy', 'es').format(_fechaObjetivo!),
                    placeholder: _fechaObjetivo == null,
                    icon: Symbols.calendar_month,
                    onTap: _guardando ? null : _elegirFecha,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                const FadeUp(
                  index: 4,
                  child: StateBanner(
                    message:
                        'Cambiar la fecha objetivo recalcula tu cuenta '
                        'regresiva del inicio.',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: EnamButton(
              label: 'Guardar cambios',
              loading: _guardando,
              onPressed: _guardar,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirUniversidad() async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final u in _universidades)
              ListTile(
                title: Text(u),
                trailing: _universidad == u ? const Icon(Symbols.check) : null,
                onTap: () => Navigator.of(context).pop(u),
              ),
          ],
        ),
      ),
    );
    if (elegida != null) setState(() => _universidad = elegida);
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          _fechaObjetivo ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Fecha de tu examen',
    );
    if (elegida != null) setState(() => _fechaObjetivo = elegida);
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    setState(() {
      _nombreError = _nombre.text.trim().isEmpty ? 'Ingresa tu nombre.' : null;
    });
    if (_nombreError != null) return;

    setState(() => _guardando = true);
    try {
      final user = await ref.read(authRepositoryProvider).updateProfile(
        nombre: _nombre.text.trim(),
        universidad: _universidad,
        condicion: _condicion,
        fechaObjetivo: _fechaObjetivo,
      );
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).setUser(user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      context.pop();
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.label,
    required this.valor,
    required this.icon,
    required this.onTap,
    this.placeholder = false,
  });

  final String label;
  final String valor;
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
                    valor,
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
