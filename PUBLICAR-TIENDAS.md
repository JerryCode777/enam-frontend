# Publicar en las tiendas

Cómo compilar y subir una versión, como la 1.1.0 (8), desde una Mac donde nunca se compiló la app. Las notas de cada versión están en `notas-de-version/`.

## 1. Lo que tiene que tener la Mac

- **Espacio:** unos 15 GB libres. Un build de release de Android deja unos 2–3 GB en `build/`, y el de iOS otros tantos más los de Xcode.
- **Flutter 3.44 o superior** (el proyecto exige Dart ≥ 3.12.2).
- **Xcode**, con la cuenta de Apple del equipo que publica la app (equipo `7XUZZ52F47`):
  - entra en Xcode → Settings → Accounts;
  - acepta la licencia la primera vez con `sudo xcodebuild -license accept`.
- **CocoaPods.** iOS se compila con CocoaPods: `brew install cocoapods`.
- **Android Studio**, con el Android SDK y su JDK, el que trae (el proyecto compila con Java 17).
- **Transporter**, de la Mac App Store, para subir el `.ipa`.

Comprueba que todo esté:

```sh
flutter doctor
```

Tienen que salir en verde Flutter, Android toolchain y Xcode. Si Android pide licencias:

```sh
flutter doctor --android-licenses
```

## 2. El código

```sh
git clone https://github.com/JerryCode777/enam-frontend.git
cd enam-frontend
git checkout main
git pull
flutter pub get
```

Comprueba que la versión es la que se publica:

```sh
grep '^version' pubspec.yaml   # version: 1.1.0+8
```

El `+8` es el número de compilación. En las dos tiendas tiene que ser mayor que el de la última subida.

## 3. Los archivos que no están en git

Son cuatro. Están en `.gitignore`, y **se pasan solo por AirDrop, de Mac a Mac**: nunca por chat, correo ni un repositorio.

| Archivo | Dónde va | Para qué |
|---|---|---|
| `key.properties` | `android/key.properties` | Las contraseñas y el alias de la clave de subida de Play |
| `upload-keystore.jks` | `android/app/upload-keystore.jks` | La clave de subida de Play. `key.properties` la busca por ese nombre (`storeFile=upload-keystore.jks`) |
| `google-services.json` | `android/app/google-services.json` | La configuración de Firebase para Android |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` | La configuración de Firebase para iOS |

- **Sin `key.properties`** el build de Android para en seco, a propósito: firmar con la clave de depuración da un `.aab` que Play rechaza.
- **Si se pierden** `upload-keystore.jks` o sus contraseñas, no se puede volver a actualizar la app en Play. Guarda una copia fuera de las dos Macs.
- **Los archivos de Firebase** hoy no los usa la compilación: no hay plugin de Firebase y el `.plist` no está en el proyecto de Xcode. Se pasan igual, para que la Mac quede como la de siempre.

**Para iOS hace falta además la firma de distribución.** La configuración Release firma a mano, con:
- la identidad «Apple Distribution» del equipo `7XUZZ52F47`;
- el perfil «ENAM Prep App Store» del bundle `pe.jakstech.enamApp`.

En la Mac nueva:

1. **El certificado con su clave privada.** En la Mac donde se compiló antes, abre Acceso a Llaveros, busca «Apple Distribution», expórtalo como `.p12` con una contraseña y pásalo por AirDrop. En la Mac nueva, ábrelo con doble clic.
   - Si ese certificado ya no está, se crea otro en developer.apple.com (Certificates) y se regenera el perfil.
2. **El perfil.** Xcode → Settings → Accounts → el equipo → *Download Manual Profiles*.

## 4. Compilar

Las dos con producción. `ENV=prod` solo no basta: apunta a `api.enamprep.pe`, que no existe. El que manda es `API_URL`.

```sh
# Android: el App Bundle para Play
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=https://api-production-4b34.up.railway.app

# iOS: el .ipa para App Store
flutter build ipa --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=https://api-production-4b34.up.railway.app
```

**En release los datos falsos se apagan solos** (`kReleaseMode`). No hace falta `USE_MOCKS=false`.

Dónde quedan:

| Tienda | Archivo |
|---|---|
| Google Play | `build/app/outputs/bundle/release/app-release.aab` |
| App Store | `build/ios/ipa/*.ipa` (y el archivo de Xcode en `build/ios/archive/Runner.xcarchive`) |

**Si `flutter build ipa` compila pero falla al exportar el `.ipa`** (pasa con la firma manual si el perfil no se encuentra), el archivo ya está hecho:

1. Ábrelo: `open build/ios/archive/Runner.xcarchive`.
2. En el Organizer de Xcode, sigue *Distribute App* → *App Store Connect* → *Upload*. Así se sube sin Transporter.

## 5. Subir

**Google Play** (play.google.com/console, la cuenta de AIDA SOFT):

1. Abre ENAM Prep, ve a Producción (o primero a Pruebas internas) y elige *Crear versión*.
2. Sube `app-release.aab`.
3. En «Novedades» pega el bloque de Google Play de `notas-de-version/1.1.0.md`, en el idioma de la ficha (español).
4. Revisa y envía.

**App Store** (App Store Connect):

1. Abre Transporter, inicia sesión con la cuenta de Apple, arrastra el `.ipa` y dale a *Entregar*.
2. Espera a que la compilación aparezca procesada en App Store Connect → ENAM Prep → TestFlight. Suele tardar entre 10 y 30 minutos.
3. Crea la versión 1.1.0 en App Store y elige la compilación 8.
4. En «Novedades en esta versión» pega el bloque de App Store de `notas-de-version/1.1.0.md`. Ese bloque no nombra a AIDA SOFT: en App Store el vendedor sigue siendo Jaks Tech S.A.C. hasta que Apple apruebe la cuenta de AIDA SOFT.
5. Envía a revisión.

## 6. Antes de enviar a revisión

- **La versión.** El `.aab` y el `.ipa` dicen 1.1.0 (8): en Play Console sale al subir, y en App Store Connect, en la compilación.
- **Las notas.** Las de cada tienda son su bloque. En ninguna hay prueba ni descuentos.
- **Una prueba en un teléfono real contra producción**, con la build de release, no con `flutter run`:
  - **Android:** instala desde Pruebas internas de Play. O bien, con el teléfono conectado:

    ```sh
    flutter build apk --release \
      --dart-define=ENV=prod \
      --dart-define=API_URL=https://api-production-4b34.up.railway.app
    flutter install --release
    ```

  - **iPhone:** instala la compilación 8 desde TestFlight.
  - **Qué probar en las dos:**
    - Entrar con una cuenta real.
    - Responder una pregunta.
    - Abrir Cursos y reproducir una clase gratis, con subtítulos y en pantalla completa.
    - Tocar una clase con candado y ver el muro.
    - Abrir «Mi suscripción».
    - En Android, que no haya ningún camino de compra. En iPhone, que la compra sea con App Store.

## 7. Después

- **Borra `build/`** (`flutter clean`): ocupa varios GB.
- **No hagas commit** de nada de lo que entró por AirDrop. `git status` no tiene que mostrar ninguno de los cuatro archivos.
