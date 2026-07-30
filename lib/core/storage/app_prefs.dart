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
}
