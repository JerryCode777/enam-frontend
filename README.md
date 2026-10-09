# ENAM Prep — App móvil

App Flutter de preparación para el Examen Nacional de Medicina del Perú.

Referencia normativa: **SSD-ENAM-001**. Los comentarios del código citan sus
requerimientos como `RF-xx`, `RN-xx` y `RNF-xx`.

## Estado

Publicada en App Store (solo iPhone) y Google Play. Tiene práctica, simulacros,
exámenes pasados, simulacro nacional, progreso, ranking, modo duelo, descargas
para estudiar sin conexión y compra por App Store en iPhone.

En la rama `rediseno-ui`: el rediseño de `PLAN-UI-SEO-PARA-OPUS.md` (carpeta
superior del workspace). El resumen, con lo validado, lo pendiente y cómo
revertir, está en [`diseno/rediseno/INFORME-APP.md`](diseno/rediseno/INFORME-APP.md).

## Diseño

- **Tokens:** [`diseno/TOKENS.md`](diseno/TOKENS.md) es la tabla fuente compartida
  con la web: colores, tipografía, radios, espaciado y movimiento, con sus
  contrastes medidos. `test/tokens_test.dart` la hace cumplir.
- **Galería de componentes:** `/dev/componentes`, solo fuera de release. Cada
  pieza del sistema en sus estados y en los dos temas.
- **Capturas:** `test/golden/` retrata las pantallas en tres tamaños de iPhone
  y en claro y oscuro. Se regeneran con
  `flutter test --update-goldens test/golden`.

## Empezar

```sh
flutter pub get
dart run build_runner build      # genera *.freezed.dart y *.g.dart
flutter run --dart-define=ENV=dev
```

Tras cambiar cualquier modelo con `@freezed`, hay que volver a correr
`build_runner`. Durante el desarrollo conviene dejarlo en modo continuo:

```sh
dart run build_runner watch
```

## Entornos

El entorno se elige **al compilar**, nunca editando código:

```sh
flutter run --dart-define=ENV=dev
```

| Flag | Valores | Por defecto | Para qué |
|---|---|---|---|
| `ENV` | `dev`, `staging`, `prod` | `dev` | Elige la URL del backend |
| `USE_MOCKS` | `true`, `false` | `true` | Datos falsos sin backend. En release se apagan siempre |
| `API_URL` | una URL | — | Sobrescribe el backend |

**Producción se compila con `API_URL`.** `ENV=prod` solo apunta a
`api.enamprep.pe`, que no existe: el backend de producción está en Railway.

```sh
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=https://api-production-4b34.up.railway.app
```

El paso a paso para publicar, con los archivos que no están en git y la
firma de iOS, está en `PUBLICAR-TIENDAS.md`. Para probar contra producción
desde el simulador, ver `PROBAR-CONTRA-PRODUCCION.md`:

```sh
flutter run --dart-define=USE_MOCKS=false \
  --dart-define=API_URL=https://api-production-4b34.up.railway.app
```

### Usuarios de prueba (con mocks)

| Correo | Qué pasa |
|---|---|
| cualquiera | Entra con el perfil completo |
| `nuevo@enam.pe` | Falla el login |
| cualquiera + contraseña `error` | Falla el login |
| `sinverificar@enam.pe` | Entra con el correo sin verificar |
| `nuevo2@enam.pe` | Entra con el perfil incompleto |
| `existente@enam.pe` | El registro falla por correo duplicado |

## Estructura

```
lib/
├── main.dart              punto de entrada
├── app.dart               MaterialApp.router y tema
├── core/
│   ├── config/            entorno (--dart-define) y endpoints
│   ├── domain/            blueprint oficial: pesos, nota vigesimal
│   ├── error/             jerarquía de Failure
│   ├── mock/              datos falsos
│   ├── network/           ApiClient + interceptor de auth
│   ├── router/            go_router y guardas
│   ├── storage/           tokens en Keystore
│   ├── theme/             design tokens, tema, colores por área
│   └── providers.dart     inyección de dependencias
├── features/<feature>/
│   ├── domain/            modelos (freezed)
│   └── data/              repositorio: interfaz + API + mock
└── shared/widgets/        widgets compartidos
```

Cada feature declara una **interfaz** de repositorio con dos implementaciones:
una contra la API y otra falsa. La UI depende de la interfaz, así que apagar los
mocks no toca ni una pantalla.

## Decisiones de arquitectura

Se toman como corrección explícita a la deuda técnica de la app hermana
(`rumbo-serums`), auditada antes de empezar. Detalle en
`../docs/AUDITORIA-rumbo-serums.md`.

| Tema | App hermana | Aquí | Motivo |
|---|---|---|---|
| Navegación | `setState` con un `String _currentStep` | `go_router` | Deep links y botón atrás correcto |
| Tokens | `shared_preferences` (texto plano) | `flutter_secure_storage` | Keystore de Android |
| Entorno | `const` que había que editar | `--dart-define` | No recompilar ni equivocarse de backend |
| Red | `http` sin interceptores | `dio` + interceptor | Auth y errores centralizados |
| Modelos | `toJson` a mano | `freezed` | Menos errores de parseo |
| Tokens de diseño | Nombres de color muertos | Nombres semánticos | Sobreviven a un cambio de paleta |

## Seguridad

- **Tokens en Keystore**, nunca en `shared_preferences`.
- **Refresh con mutex**: peticiones concurrentes comparten un solo refresh, para
  que la rotación de refresh token del servidor no invalide sesiones.
- **Nunca se loguean headers** — ahí viaja el Bearer.
- **El servidor manda** (RN-03): la app muestra los límites del plan, pero no
  decide. Un 403 se traduce a paywall; nada de contenido premium en el cliente.
- **Marca de agua** con el ID del usuario en el enunciado de cada pregunta
  (RNF-05).
- **Eliminación de cuenta** por Ley 29733 (RNF-06), desde Ajustes.

## Comandos

```sh
flutter analyze                     # debe salir limpio
flutter test                        # toda la batería, capturas incluidas
flutter test --exclude-tags golden  # sin las capturas, más rápido
dart run build_runner build         # regenerar modelos
```

Para compilar y subir a las tiendas: `PUBLICAR-TIENDAS.md`.

## Pendiente

1. Notificaciones push (RF-34), analítica de producto y registro de errores de
   cliente: requieren cuenta y configuración de un proveedor. No se añaden sin
   aprobación del negocio.
2. Los reportes de preguntas van a `POST /questions/{id}/reports`, que aún no
   está desplegado (enam-backend#4). Hasta entonces caen al WhatsApp de
   soporte.
3. Actualizar el titular legal a AidaSoft cuando estén la razón social y el
   RUC. Los textos afectados están marcados con `PENDIENTE(titular)`.
