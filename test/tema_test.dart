import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Claro por defecto, oscuro a un toque, y la elección se guarda.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin elección guardada, claro aunque el sistema esté en oscuro', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    // El predeterminado es claro, no «el del sistema».
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('alternar pasa al contrario de lo que se ve y se guarda', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(themeModeProvider.notifier).alternar(oscuroAhora: false);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tema'), 'dark');
  });

  test('al volver a abrir la app, se aplica lo elegido', () async {
    SharedPreferences.setMockInitialValues({'tema': 'dark'});
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(themeModeProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('el botón del inicio muestra la luna en claro y cambia', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _AppDePrueba(child: Scaffold(body: BotonTema())),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Usar tema oscuro'), findsOneWidget);
    await tester.tap(find.byType(BotonTema));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Usar tema claro'), findsOneWidget);
  });

  testWidgets('las pantallas de acceso van en claro aunque se elija oscuro', (
    tester,
  ) async {
    late Brightness brillo;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: SiempreClaro(
          child: Builder(
            builder: (context) {
              brillo = Theme.of(context).brightness;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(brillo, Brightness.light);
  });
}

/// Una app mínima que obedece al tema elegido, como la de verdad.
class _AppDePrueba extends ConsumerWidget {
  const _AppDePrueba({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ref.watch(themeModeProvider),
    home: child,
  );
}
