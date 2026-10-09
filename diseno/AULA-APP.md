# Aula de cursos en la app

Las clases en video del temario oficial, con su práctica. Es el gemelo de `/cursos` de la web (`enam-prep-web-react`, `src/features/aula`) y habla con el aula del backend (`enam-backend/internal/aula`, `AULA.md`).

## Pantallas

| Ruta | Pantalla | Qué tiene |
|---|---|---|
| `/cursos` | `CursosScreen` | «Seguir viendo», el **Repaso final ENAM destacado arriba** («Para las últimas semanas») y los cursos por área, con profe, lema, «N clases · X min» y «N de M vistas». Un curso sin clases sale como «Próximamente» y no se abre. |
| `/cursos/:curso` | `CursoScreen` | Portada, lema, profe, avance y el botón «Empezar el curso» o «Seguir con el curso», que va a `continuar` (lo decide el servidor). Sin Premium: «Tienes N clases gratis…». Temario por módulos: duración, «Gratis», candado, «Vista» y la barrita de lo empezado. |
| `/cursos/:curso/clase/:clase` | `ClaseScreen` | El reproductor, el título y el profe, «Practicar este tema», Anterior/Siguiente, «Lo que aprendes» y «Referencias (n)», y debajo el temario del curso. |

**La entrada** es la tarjeta «Cursos» del inicio (`EntradaAlAula`), con «Nuevo» o «Muy pronto», como en la web.

**Los textos son los de la web**, con una excepción: el subtítulo del catálogo. El de la web no cabe en la cabecera de un teléfono, así que se usa el de la entrada del inicio.

## El reproductor

**Paquete: `video_player` solo**, con controles propios.

- **Formato.** Las clases son MP4 H.264 servidos por CloudFront con rango. `video_player` usa ExoPlayer en Android y AVPlayer en iOS, que ya piden por rango.
- **Subtítulos.** El paquete trae `WebVTTCaptionFile`.
- **Por qué no chewie.** Traería su UI y sus textos.
- **Por qué no media_kit.** Mete libmpv: decenas de MB por ABI para algo que ExoPlayer ya hace.
- **`wakelock_plus`.** Mantiene la pantalla encendida mientras corre la clase. `video_player_android` 2.12 no implementa `preventsDisplaySleepDuringVideoPlayback`.

Qué hace:

- **Subtítulos.** El VTT se baja con un cliente aparte, porque la URL es de CloudFront y no lleva la cabecera de sesión. Se activan y desactivan desde los controles. Si no llegan, la clase sigue sin ellos.
- **Velocidad.** 1×, 1,25×, 1,5× y 2×.
- **Pantalla completa.** En horizontal y sin barras del sistema, con el mismo video. Al salir, vuelve a vertical, como fija `main.dart`.
- **Retomar.** Si la clase no está vista y la posición guardada no está ni al principio ni al final, se salta ahí. Sale «Sigues donde lo dejaste, en el m:ss.» con «Desde el inicio».
- **El progreso.** Es como `useProgresoDeVideo.ts` de la web:
  - Cuenta los segundos **distintos** vistos (`SegundosVistos`), así que adelantar no cuenta.
  - Los manda cada 15 s de reproducción, al pausar, al terminar, al salir de la app y al cerrar la clase.
  - El servidor marca la clase completada al 90 %.
- **La URL caduca a las 4 h.** Si el video falla, se pide la clase otra vez y se sigue en la última posición buena. Una sola vez por minuto: si vuelve a fallar enseguida, no es la firma, y sale «No pudimos reproducir la clase.» con «Reintentar».

## El muro

Una clase con candado abre una hoja con el texto de la web, «Los cursos completos son de Premium» (`abrirMuroDeCursos`). Se abre al tocarla, sin pedirla, o cuando el servidor responde 403 `FUNCION_PREMIUM`.

- **En Android no hay botón de compra**, por la política de pagos de Google Play: la app no tiene Play Billing. Sale «Tu acceso Premium se activa con tu cuenta de ENAM Prep.» (`PremiumConTuCuenta`).
- **En iOS**, «Ver Premium» lleva a la compra con App Store.
- **Gratis limitado (PR #2).** Cuando entre a `main`, `abrirMuroDeCursos` pasa a ser el muro de venta con `FuncionPremium.cursos`.

## Contrato

- **El código de la API.** Los modelos (`aula_models.dart`) son los de `src/types/aula.ts` de la web y los del handler del backend.
- **Dónde difiere `AULA.md` del código.** El código manda:
  - Lo gratis se marca **por clase**, no por módulo. Por defecto son las 3 primeras.
  - La práctica sin preguntas da **422 `VALIDATION_ERROR`**, no `SIN_PREGUNTAS`.
  - `GET /subscription` trae `acceso.gratis.cursos = {clasesGratis: true}`.
- **El catálogo trae también los cursos sin publicar.** La app los muestra como «Próximamente».
- **`GET /aula/continuar` responde 204 sin cuerpo.** `ApiClient.getOpcional` lo lee como `null`.
- **Reintentos.** Riverpod reintenta cualquier error por defecto. En el aula solo se reintenta la red (`soloSiEsLaRed`): un 403 no cambia por insistir, y cada reintento volvía a abrir el muro.

## Analítica

No se emite nada todavía. `curso_visto` es del catálogo 10 y espera a que BI lo confirme.

## Pruebas

- `test/aula_contrato_test.dart` cubre:
  - los JSON del backend, con sus nulos y estados nuevos;
  - los segundos vistos y los textos;
  - el repositorio contra respuestas HTTP: 204, PUT, 403 y la práctica.
- `test/aula_pantallas_test.dart` cubre:
  - el catálogo, el curso con Premium y en gratis, y la clase;
  - el muro en Android sin botón de compra.
- `test/aula_reproductor_test.dart`, con un video falso, cubre:
  - el progreso cada 15 s;
  - que adelantar no cuenta;
  - retomar y empezar desde el inicio;
  - la URL que caduca, y que falle dos veces seguidas;
  - la velocidad, y el envío al salir.
- `test/golden/aula_test.dart` saca las capturas en un Android de 412 × 915, en claro y oscuro.
- `test/aula_backend_local_test.dart` (tag `backend-local`) prueba el repositorio contra el backend local:
  - catálogo, curso y clase;
  - MP4 con rango (206);
  - el VTT, leído con el lector del reproductor;
  - el progreso y «seguir viendo».

## Probar contra el backend local

```sh
# En enam-backend, con la base local migrada:
go run ./cmd/cargar-aula -dir ../enam-contenido/cursos/pediatria
AULA_MEDIOS_DIR=../enam-contenido/cursos go run ./cmd/api

# El repositorio, sin teléfono:
AULA_API=http://localhost:8080/api/v1 AULA_TOKEN=<accessToken> \
  flutter test --tags backend-local test/aula_backend_local_test.dart

# La app en el emulador: el emulador ve el backend en su localhost.
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=USE_MOCKS=false --dart-define=API_URL=http://localhost:8080
```

Solo en debug, `android/app/src/debug/res/xml/network_security_config.xml` deja ir por HTTP a `localhost` y `10.0.2.2`. Sin eso, ExoPlayer no carga los videos del backend local. Release no la tiene.
