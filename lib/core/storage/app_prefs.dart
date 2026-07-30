import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales que **no** son sensibles.
///
/// Los tokens no van aquí: van en `TokenStorage`, respaldado por el Keystore
/// de Android (RNF-04). Esto es solo para banderas de interfaz, que no sirven
/// de nada a quien las lea.
class AppPrefs {
  static const _kOnboardingVisto = 'onboarding_visto';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Si el onboarding ya se mostró alguna vez.
  ///
  /// El diseño dice "solo se muestra una vez", así que esto tiene que
  /// sobrevivir al cierre de la app. Al desinstalar se pierde, y está bien:
  /// una instalación nueva es un usuario nuevo desde el punto de vista de la
  /// primera impresión.
  Future<bool> onboardingVisto() async =>
      (await _prefs).getBool(_kOnboardingVisto) ?? false;

  Future<void> marcarOnboardingVisto() async =>
      (await _prefs).setBool(_kOnboardingVisto, true);

  static const _kNacionalesInscritos = 'nacionales_inscritos';

  /// Simulacros nacionales en los que el usuario ya se anotó.
  ///
  /// Esto es dato del servidor: cuando exista `GET /mock-exams/next` con el
  /// campo `inscrito`, esta copia local sobra. Mientras tanto vive aquí para
  /// que salir de la pantalla y volver no borre la inscripción, que es lo que
  /// pasaba cuando el estado vivía solo en el widget.
  Future<Set<String>> nacionalesInscritos() async =>
      (await _prefs).getStringList(_kNacionalesInscritos)?.toSet() ?? {};

  Future<void> marcarInscritoEnNacional(String id) async {
    final prefs = await _prefs;
    final actuales = prefs.getStringList(_kNacionalesInscritos) ?? [];
    if (actuales.contains(id)) return;
    await prefs.setStringList(_kNacionalesInscritos, [...actuales, id]);
  }
}
