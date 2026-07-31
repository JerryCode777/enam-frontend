import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../auth/domain/auth_models.dart';

/// Pantalla 9.1 — ajustes y cuenta (incluye 9.2 notificaciones y 9.3 tema).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tema = ref.watch(themeModeProvider);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Ajustes'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                DesignTokens.space4,
                DesignTokens.space4,
                DesignTokens.space8,
              ),
              children: [
                FadeUp(child: _TarjetaPerfil(user: user)),
                const SizedBox(height: DesignTokens.space5),
                const _Titulo('ESTUDIO'),
                const FadeUp(index: 1, child: _Estudio()),
                const SizedBox(height: DesignTokens.space5),
                const _Titulo('APARIENCIA'),
                FadeUp(index: 2, child: _Apariencia(modo: tema)),
                const SizedBox(height: DesignTokens.space5),
                const _Titulo('CUENTA Y PRIVACIDAD'),
                FadeUp(index: 3, child: _Cuenta(user: user)),
                const SizedBox(height: DesignTokens.space5),
                const _Titulo('AYUDA'),
                const FadeUp(index: 4, child: _Ayuda()),
                const SizedBox(height: DesignTokens.space5),
                FadeUp(
                  index: 5,
                  child: Center(
                    child: TextButton.icon(
                      icon: const Icon(Symbols.logout, size: 18),
                      label: const Text('Cerrar sesión'),
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
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

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Text(
        texto,
        style: context.texts.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TarjetaPerfil extends StatelessWidget {
  const _TarjetaPerfil({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final condicion = user?.condicion;

    // Etiqueta amable de la condición: "repitiente" no se le enseña al usuario.
    final condicionTexto = switch (condicion) {
      StudentCondition.preinterno => 'Preinterno(a)',
      StudentCondition.interno => 'Interno(a)',
      StudentCondition.egresado => 'Egresado(a)',
      StudentCondition.repitiente => 'Voy a rendirlo de nuevo',
      null => null,
    };

    final detalle = [
      ?user?.universidad,
      ?condicionTexto,
      if (user?.fechaObjetivo != null)
        'ENAM ${DateFormat('d MMM yyyy', 'es').format(user!.fechaObjetivo!)}',
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.editProfile),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: states.info.tint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _iniciales(user?.nombre),
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: states.info.onTint,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space3 + 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nombre ?? 'Tu perfil',
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detalle.isNotEmpty)
                      Text(
                        detalle,
                        style: context.texts.bodySmall?.copyWith(fontSize: 13),
                      ),
                  ],
                ),
              ),
              Icon(
                Symbols.edit,
                size: 20,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
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

class _Estudio extends ConsumerStatefulWidget {
  const _Estudio();

  @override
  ConsumerState<_Estudio> createState() => _EstudioState();
}

class _EstudioState extends ConsumerState<_Estudio> {
  bool _recordatorio = true;
  bool _avisosNacional = true;
  TimeOfDay _hora = const TimeOfDay(hour: 21, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: _recordatorio,
            onChanged: (v) => setState(() => _recordatorio = v),
            secondary: const Icon(Symbols.notifications),
            title: const Text('Recordatorio diario'),
            subtitle: Text(
              _recordatorio
                  ? 'Todos los días · ${_hora.format(context)}'
                  : 'Apagado',
              style: context.texts.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          if (_recordatorio) ...[
            Divider(height: 1, color: context.scheme.outlineVariant),
            ListTile(
              leading: const Icon(Symbols.schedule),
              title: const Text('Hora del recordatorio'),
              trailing: Text(
                _hora.format(context),
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: _elegirHora,
            ),
          ],
          Divider(height: 1, color: context.scheme.outlineVariant),
          SwitchListTile(
            value: _avisosNacional,
            onChanged: (v) => setState(() => _avisosNacional = v),
            secondary: const Icon(Symbols.campaign),
            title: const Text('Avisos de simulacro nacional'),
            subtitle: Text(
              'Participación, inicio y resultados',
              style: context.texts.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          ListTile(
            leading: const Icon(Symbols.download),
            title: const Text('Estudiar sin conexión'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.downloads),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora);
    if (elegida != null) setState(() => _hora = elegida);
  }
}

class _Apariencia extends ConsumerWidget {
  const _Apariencia({required this.modo});

  final ThemeMode modo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Row(
          children: [
            const Icon(Symbols.dark_mode),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Text(
                'Tema',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
              ],
              selected: {modo},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              // El cambio es inmediato, sin reiniciar.
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cuenta extends ConsumerWidget {
  const _Cuenta({this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.workspace_premium),
            title: const Text('Mi suscripción'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.mySubscription),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          SwitchListTile(
            value: !(user?.ocultoEnRanking ?? false),
            onChanged: (visible) async {
              final actualizado = await ref
                  .read(authRepositoryProvider)
                  .updateProfile(ocultoEnRanking: !visible);
              ref.read(authControllerProvider.notifier).setUser(actualizado);
            },
            secondary: const Icon(Symbols.visibility),
            title: const Text('Aparecer en rankings'),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          ListTile(
            leading: const Icon(Symbols.lock),
            title: const Text('Cambiar contraseña'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.changePassword),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          ListTile(
            leading: Icon(Symbols.delete_forever, color: states.error.onTint),
            title: Text(
              'Eliminar mi cuenta y mis datos',
              style: TextStyle(color: states.error.onTint),
            ),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.deleteAccount),
          ),
        ],
      ),
    );
  }
}

class _Ayuda extends StatelessWidget {
  const _Ayuda();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.help),
            title: const Text('Ayuda y contacto'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.help),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          ListTile(
            leading: const Icon(Symbols.gavel),
            title: const Text('Términos y privacidad'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.terms),
          ),
        ],
      ),
    );
  }
}
