import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/features/session/presentation/national_mock_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La inscripción al simulacro nacional vivía en el `State` de la pantalla, así
/// que salir y volver la borraba y se podía "participar" otra vez en el mismo
/// simulacro. Estos tests fijan que sobreviva.
void main() {
  late _PrefsFalsas prefs;

  setUp(() => prefs = _PrefsFalsas());

  ProviderContainer contenedor() {
    final c = ProviderContainer(
      overrides: [appPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('sin inscribirse, el usuario no figura como participante', () async {
    final c = contenedor();
    await c.read(inscripcionesNacionalesProvider.future);

    expect(c.read(inscritoEnNacionalProvider), isFalse);
  });

  test('al inscribirse queda registrado', () async {
    final c = contenedor();
    await c.read(inscripcionesNacionalesProvider.future);
    final evento = c.read(nacionalProvider);

    await c.read(inscripcionesNacionalesProvider.notifier).inscribir(evento.id);

    expect(c.read(inscritoEnNacionalProvider), isTrue);
  });

  test('la inscripción sobrevive a cerrar y reabrir la app', () async {
    // Este es el fallo original: el estado vivía en el widget y al volver a
    // entrar el botón invitaba a participar de nuevo.
    final primera = contenedor();
    await primera.read(inscripcionesNacionalesProvider.future);
    final evento = primera.read(nacionalProvider);
    await primera
        .read(inscripcionesNacionalesProvider.notifier)
        .inscribir(evento.id);

    // Contenedor nuevo = app reabierta, con el mismo almacenamiento.
    final segunda = contenedor();
    await segunda.read(inscripcionesNacionalesProvider.future);

    expect(segunda.read(inscritoEnNacionalProvider), isTrue);
  });

  test('inscribirse dos veces no duplica nada', () async {
    final c = contenedor();
    await c.read(inscripcionesNacionalesProvider.future);
    final evento = c.read(nacionalProvider);
    final notifier = c.read(inscripcionesNacionalesProvider.notifier);

    await notifier.inscribir(evento.id);
    await notifier.inscribir(evento.id);

    expect(await prefs.nacionalesInscritos(), {evento.id});
  });
}

/// Almacenamiento en memoria.
///
/// La misma instancia se comparte entre los dos contenedores del test de
/// reapertura: eso es justo lo que representa el disco del dispositivo, que
/// sobrevive a que la app se cierre.
class _PrefsFalsas implements AppPrefs {
  final _nacionales = <String>{};

  @override
  Future<bool> onboardingVisto() async => true;

  @override
  Future<void> marcarOnboardingVisto() async {}

  @override
  Future<Set<String>> nacionalesInscritos() async => _nacionales;

  @override
  Future<void> marcarInscritoEnNacional(String id) async =>
      _nacionales.add(id);
}
