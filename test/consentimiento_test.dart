import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// El consentimiento tiene que llegar al servidor (RNF-06, Ley 29733).
///
/// La casilla llevaba tiempo en la pantalla de registro, el botón no se
/// habilitaba sin marcarla, y aun así el dato **no viajaba**: el repositorio
/// mandaba `{email, password, nombre}` y nada más. Contra el backend real eso
/// es un 422 `CONSENT_REQUIRED` en cada alta, o sea una app incapaz de
/// registrar a nadie, y no lo cazó nadie porque el mock aceptaba cualquier
/// cosa.
///
/// De ahí estos tests: fijan que el parámetro existe y que **el mock rechaza
/// igual que el servidor**. Un mock más permisivo que la API deja el camino sin
/// probar justo hasta el día del despliegue.
void main() {
  late AuthRepository repo;

  setUp(() => repo = MockAuthRepository());

  group('registro con correo', () {
    test('sin aceptar los términos no se crea la cuenta', () async {
      await expectLater(
        repo.register(
          email: 'nueva@unsa.pe',
          password: 'claveLarga123',
          nombre: 'Ana',
          aceptaTerminos: false,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.code,
            'code',
            'CONSENT_REQUIRED',
          ),
        ),
      );
    });

    test('aceptando los términos sí se crea', () async {
      await repo.register(
        email: 'nueva@unsa.pe',
        password: 'claveLarga123',
        nombre: 'Ana',
        aceptaTerminos: true,
      );

      final usuario = await repo.currentUser();
      expect(usuario?.email, 'nueva@unsa.pe');
    });
  });

  // Google y Apple no tienen casilla: el botón vive en el login. Por eso el
  // primer intento va sin consentimiento y es el servidor quien lo pide; la
  // pantalla enseña los términos y reintenta. Marcarlo de oficio sería sellar
  // una prueba de algo que nadie aceptó.
  group('registro con Google y Apple', () {
    test('el primer intento sin consentimiento lo pide', () async {
      await expectLater(
        repo.loginConGoogle('id-token'),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.code,
            'code',
            'CONSENT_REQUIRED',
          ),
        ),
      );
    });

    test('el reintento con consentimiento entra', () async {
      final usuario = await repo.loginConGoogle('id-token', aceptaTerminos: true);
      expect(usuario.emailVerificado, isTrue);
    });

    test('Apple se comporta igual', () async {
      await expectLater(
        repo.loginConApple(identityToken: 'identity-token'),
        throwsA(isA<ValidationFailure>()),
      );

      final usuario = await repo.loginConApple(
        identityToken: 'identity-token',
        nombre: 'Ana',
        aceptaTerminos: true,
      );
      expect(usuario.nombre, 'Ana');
    });
  });

  // El reenvío es público —quien lo necesita todavía no verificó, así que no
  // tiene sesión— y por eso el correo va en el cuerpo. Llamarlo sin él devuelve
  // 422, que es lo que hacía la app.
  test('reenviar la verificación exige el correo', () async {
    await repo.reenviarVerificacion('a@unsa.pe');
  });
}
