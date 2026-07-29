import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// Condición del estudiante respecto al ENAM (RF-04).
///
/// `repitiente` importa para el producto: ~43 % desaprueba y vuelve a rendir,
/// así que es un segmento grande y el tono de la app debe considerarlo.
@JsonEnum(fieldRename: FieldRename.snake)
enum StudentCondition {
  preinterno('Preinterno'),
  interno('Interno'),
  egresado('Egresado'),
  repitiente('Repitiente');

  const StudentCondition(this.label);
  final String label;
}

/// Rol del usuario (RF-05). La app móvil es solo para estudiantes; los demás
/// roles trabajan desde el panel admin en React.
@JsonEnum(fieldRename: FieldRename.snake)
enum UserRole { estudiante, editor, admin }

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String nombre,
    @Default(UserRole.estudiante) UserRole rol,
    String? universidad,
    StudentCondition? condicion,

    /// Fecha objetivo de examen (RF-04). Alimenta la cuenta regresiva del home.
    DateTime? fechaObjetivo,
    @Default(false) bool emailVerificado,

    /// Si el usuario eligió ocultarse del ranking público (RF-22).
    @Default(false) bool ocultoEnRanking,
  }) = _User;

  const User._();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// El perfil está completo cuando tiene lo que pide RF-04.
  bool get perfilCompleto =>
      universidad != null && condicion != null && fechaObjetivo != null;

  /// Días que faltan para el examen objetivo. `null` si no hay fecha.
  int? get diasParaExamen {
    final objetivo = fechaObjetivo;
    if (objetivo == null) return null;
    final hoy = DateTime.now();
    return objetivo.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
  }
}

/// Respuesta de `/auth/login` y `/auth/refresh`.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required User user,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}
