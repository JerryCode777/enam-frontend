# Eventos del embudo en la app

**El contrato normativo está en `enam-business/contrato/`**: `eventos.json`
(los 15 eventos, sus propiedades, límites y rechazos) y `EVENTOS.md` (el
porqué). Este documento solo cuenta cómo lo cumple la app. Si choca con el
contrato, manda el contrato.

## Qué emite la app

Solo los eventos de **cliente** que el contrato asigna a `ios` y `android`:

| Evento | Dónde | Propiedades |
|---|---|---|
| `signup_started` | Se envía el formulario de registro ya validado | `metodo`: `correo` (la app no tiene alta con Google o Apple desde el formulario; esas altas las cuenta el servidor en `account_created`) |
| `plans_viewed` | Se abre «Acceso terminado» o «Mi suscripción» | `pantalla`: `acceso_terminado` o `perfil` |
| `checkout_started` | **Solo iOS**: se pulsa comprar un plan de App Store | `plan_id` (`mensual`, `intensivo`, `semestral`; el trimestral de Apple es `intensivo`, como en el backend) y `medio`: `apple` |

`signup_verified` y `profile_completed` **ya no salen de la app**: son de
servidor. Tampoco `account_created`, `trial_started`,
`first_practice_completed`, `payment_*` ni `access_*`.

## Propiedades comunes

Van en el sobre (`comunes`) de cada lote:

| Propiedad | Valor |
|---|---|
| `plataforma` | `ios` o `android` |
| `version_app` | La de pubspec (`1.0.0+7`). Fuera de una compilación de tienda, con `-dev` al final (`1.0.0+7-dev`): el servidor la cuenta como **prueba**, no como gente |
| `version_visual` | `rediseno-2026-09` |
| `anonimo_id` | UUID v4 aleatorio generado la primera vez y guardado en el teléfono (`shared_preferences`, `enam.anonimo`). Sobrevive a cerrar sesión |

**Nunca `usuario_id`**: lo pone el servidor desde el token. Nada de datos
personales, IP ni texto libre: cada propiedad se filtra contra la lista
cerrada del contrato antes de encolar, y un evento sin sus obligatorias ni se
encola.

## Envío (`lib/core/analitica/`)

- **Cola local persistente** (`cola_de_eventos.dart`): hasta 500 eventos y 7
  días. Se guarda **antes** de mandar, así que cerrar la app no pierde nada.
  Cada evento nace con su `evento_id` y un reintento manda el mismo: el
  servidor lo marca como duplicado.
- **Lotes** (`emisor_de_eventos.dart`) de hasta 50 eventos y 64 KiB, a
  `POST /api/v1/eventos` con un cliente HTTP propio, sin el interceptor de
  sesión: un 401 de la analítica no puede cerrar la sesión de nadie.
- **Respuestas**, según la tabla del contrato:
  - 200: se retira lo contestado. Lo que el servidor no nombró espera a la
    próxima ronda.
  - 400: se descarta el lote.
  - 413: se parte.
  - 429: se espera lo que diga `Retry-After`.
  - Sin red, 5xx o tiempo agotado: se reintenta con retroceso de 1 a 60 s.
- **Token opcional.** Con sesión va el access token. Si el servidor responde
  401, se renueva una vez (con el mismo candado que el resto de la API); si
  vuelve a fallar, el lote sale sin token, como anónimo.
- **Cuándo se manda.** Dos segundos después de registrar, al abrir la app, al
  volver del segundo plano y al recuperar la red.
- **Nunca rompe el producto.** Nada de esto lanza errores ni muestra nada.

## El alta une la visita con la cuenta

`POST /auth/register`, `/auth/google` y `/auth/apple` llevan `anonimoId` en
el cuerpo. Todas las peticiones a la API llevan además la cabecera
`X-Plataforma: ios|android`. Con eso el servidor escribe `account_created`
con la plataforma de alta y une la sesión anónima con la cuenta.

## Sin servidor

Con datos de ejemplo (`USE_MOCKS`) no hay a dónde mandar: los eventos se
escriben en la consola. Mientras el backend no tenga el endpoint, el envío
falla en silencio y los eventos esperan en la cola hasta siete días.

## Pruebas

- `test/emisor_de_eventos_test.dart`:
  - la cola sobrevive a reiniciar, con 500 como máximo y 7 días de vigencia;
  - lotes de 50;
  - las comunes van, y nunca `usuario_id`;
  - sin red no se pierde nada y se reintenta con los mismos ids;
  - retiro parcial, 400, 429 y renovación de token.
- `test/analitica_test.dart`:
  - lista cerrada, sin eventos de servidor;
  - filtro de propiedades;
  - `checkout_started` solo en iOS;
  - `version_app` con `-dev`;
  - `metodo` en el registro.
- `test/alta_con_anonimo_test.dart`: `anonimoId` en las tres altas.

## Pendiente fuera de la app

- El endpoint y los eventos de servidor (backend).
- Declarar la analítica de uso y los 400 días de retención en la política de
  privacidad (Ley 29733, contrato §10).
