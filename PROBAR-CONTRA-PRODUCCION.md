# Probar la app contra el backend de producción

El backend ya está desplegado en Railway con las 2 200 preguntas del banco. No
hace falta levantar nada en local: ni Postgres, ni el servidor Go, ni Docker.

## 1. Traer los cambios

```sh
git checkout main
git pull
flutter pub get
```

Necesitas **Flutter 3.44 o superior** (el proyecto exige Dart ≥ 3.12.2). Si el
`pub get` se queja de la versión del SDK:

```sh
flutter upgrade
```

## 2. Correr la app

Con el simulador ya abierto:

```sh
flutter run --dart-define=USE_MOCKS=false \
            --dart-define=API_URL=https://api-production-4b34.up.railway.app
```

Los dos `--dart-define` son imprescindibles: sin ellos la app arranca con los
mocks y no toca el servidor.

**Ya no hace falta pasar `GOOGLE_SERVER_CLIENT_ID`.** Estuvo vacío por defecto y
era el que más despistaba, porque el síntoma no se parecía a la causa: al apagar
los mocks para probar contra el servidor, **el botón de Google desaparecía**.
Nadie relaciona «quité los datos falsos» con «se fue un botón», así que costaba
tardes averiguar que faltaba un parámetro de compilación que solo tenía quien
hizo la última build.

Ahora el client ID del proyecto viene puesto en `app_config.dart`. Se puede
seguir sobreescribiendo con `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` para
apuntar a otro proyecto de Google Cloud.

No es un secreto: es el client ID **web** de OAuth, el mismo que viaja dentro
del APK y del IPA y que el navegador enseña en cualquier login con Google. Lo
que protege el acceso es la huella SHA-1 más el nombre del paquete, registrados
del lado de Google. Lo que sí es secreto es `android/key.properties`, y ese no
se comparte.

Falta además un archivo que **no viaja en git** y sin el cual Android no
compila: `android/app/google-services.json`. Se descarga de la consola de
Firebase —Configuración del proyecto, la app de Android— o te lo pasa alguien
del equipo por un canal privado. El equivalente en iOS es
`ios/Runner/GoogleService-Info.plist`.

## 3. Entrar

```
Correo:      jerry@test.pe
Contraseña:  12345678
```

Tiene el plan mensual activo, así que no aparecen topes ni paywall. Si prefieres
crear tu propia cuenta, se puede registrar desde la app, pero **el correo de
verificación no llega**: todavía no hay cuenta de Resend y los correos se
escriben en los logs del servidor. Pídeselo a Jerry y te pasa el enlace.

## Qué mirar

- **Temario**: 2 200 preguntas repartidas por área (Medicina 480, Pediatría 400,
  Gineco 360, Cirugía 360, Emergencias 200…). Son las del banco auditado, no
  las de relleno.
- **Práctica**: al responder salen la clave y **las cuatro explicaciones**, una
  por alternativa.
- **Simulacro completo**: 180 preguntas armadas con el blueprint de ASPEFAM.

## Diferencias con los mocks que conviene tener presentes

Estas cosas se comportan distinto contra el servidor, y es donde han aparecido
los fallos:

1. **La clave y las explicaciones no viajan hasta responder** la pregunta
   (RF-13). El mock las entregaba desde el inicio; ya no, para que se parezca al
   servidor.
2. **Las fechas viajan en ISO 8601 con zona** (`...Z`). Un `DateTime` local
   serializado sin `toUtc()` lo rechaza el servidor con 422.
3. **Las cuatro pestañas viven en un `StatefulShellRoute`**: para ir de una a
   otra hay que usar `context.go`, no `context.push`. Pushear apila una segunda
   copia del shell y la app muere con pantalla roja.

## Si algo falla

- **Pantalla de login que no avanza** → revisa que el `API_URL` no lleve barra
  final ni `/api/v1`; la app lo añade sola.
- **404 en algún endpoint** → el servidor puede estar por detrás de `main`.
  Avisa y se redespliega.
- **Errores de red en el simulador** → comprueba que la API responde:
  `curl https://api-production-4b34.up.railway.app/health`

## Volver a los mocks

```sh
flutter run
```

Sin `--dart-define`, la app usa los datos falsos de siempre y no necesita
conexión.
