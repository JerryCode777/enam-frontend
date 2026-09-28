# Diccionario de eventos — paquete F

Plan `PLAN-UI-SEO-PARA-OPUS.md` §12. **No hay proveedor de analítica
conectado**: ni en la app, ni (según la auditoría del 27/09) en la web ni en el
backend. Lo que existe en la app es la **interfaz** (`lib/core/analitica/`) y
los disparadores. En release los eventos van a una implementación que no hace
nada, y en desarrollo se escriben en la consola.

**Esto no cuenta como medición terminada.** Lo será cuando un proveedor
elegido por el negocio los reciba y se haya comprobado la recepción.

## Eventos

| Evento | Quién lo emite | Disparador exacto | Deduplicación |
|---|---|---|---|
| `landing_view` | Web (landing) | Carga de la portada | Por sesión de navegador |
| `demo_started` | Web (landing) | Primera respuesta de la demo | Por sesión de navegador |
| `demo_completed` | Web (landing) | Última pregunta de la demo respondida | Por sesión de navegador |
| `signup_started` | App y web | Se envía el formulario de registro con datos válidos | Ninguna (cada intento cuenta) |
| `signup_verified` | App y web | El servidor acepta el código del correo | Una por cuenta (en el servidor) |
| `profile_completed` | App y web | El servidor guarda el perfil obligatorio | Una por cuenta (en el servidor) |
| `first_practice_completed` | **Backend** | Primera sesión de práctica cerrada de la cuenta | Una por cuenta: solo el servidor lo sabe con certeza |
| `plans_viewed` | App y web | Se abre la pantalla de planes o de acceso terminado | Ninguna |
| `checkout_started` | Web (Android paga en la web) | Se inicia el cobro | Ninguna |
| `payment_confirmed` | **Backend** | Pago validado o conciliado | Una por pago |
| `access_granted` | **Backend** | Se concede acceso de pago | Una por concesión |

`checkout_started` en iPhone **no se emite**: la compra por App Store tiene
su propio flujo, que este rediseño no toca. Si hace falta, debería salir del
backend al recibir `POST /subscription/apple/verify`, no del botón.

Abrir WhatsApp no es pagar: ningún evento de pago nace de un clic.

## Propiedades

Solo estas, filtradas antes de salir (`propiedadesPermitidas`):

| Propiedad | Valores |
|---|---|
| `plataforma` | `android`, `iOS`, `web` |
| `version_visual` | `rediseno-2026-09` (compara cohortes antes y después) |
| `pantalla` | Nombre corto de la pantalla, p. ej. `registro`, `acceso_terminado` |
| `origen` | Campaña o canal, cuando se conozca |

**Nunca** nombres, correos, tokens ni texto de preguntas. La prueba
`test/analitica_test.dart` lo comprueba.

## Pendiente, fuera de este repositorio

- Elegir y configurar proveedor (cuenta, clave, política de privacidad
  actualizada). Es decisión del negocio.
- Excluir cuentas de prueba, bots y tráfico interno en el proveedor.
- Emitir los eventos de backend de la tabla.
- Comprobar la recepción de punta a punta antes del lanzamiento.
