# Gratis limitado en la app (fase 1)

El plan está en `PLAN-GRATIS-LIMITADO.md`, en la carpeta del proyecto, aprobado
por el usuario el 04/10/2026. Este documento cuenta cómo lo aplica la app.

**Contrato confirmado por el backend el 05/10/2026** (sección «Contrato
confirmado» del plan). Todo lo que depende de él está en un solo sitio
(`lib/features/subscription/domain/acceso.dart`).

## Qué cambia

Antes, al vencer la prueba de 24 h la app entera quedaba tras «Acceso
terminado» (D-01). Ahora sigue abierta con **10 preguntas al día** (día de
Lima), y se vende en el momento en que se topa un límite.

| Dónde | En gratis |
|---|---|
| Inicio, cabecera | «Te quedan 6 de 10 preguntas hoy» / «Usaste tus 10 preguntas de hoy» |
| Inicio, siguiente acción | «Sigue con tus preguntas de hoy» (Practicar), o «Respondiste tus 10 preguntas de hoy» (Ver Premium). No sugiere área: elegirla es Premium |
| Inicio, Estudiar | Simulacro completo y Exámenes pasados con etiqueta «Premium». Sin nota proyectada |
| Nueva práctica | Todo el temario, `todas`, y hasta el cupo que queda. Área y filtro se ven con candado y abren el muro. Sin cupo, el botón es «Ver Premium» |
| Simulacros | Las tres tarjetas con «Premium». Empezar el completo o el de muestra abre el muro. El nacional se abre (es la vista previa); inscribirse da 403 → muro |
| Exámenes pasados | La lista se ve entera, con «Premium»; tocar uno abre el muro |
| Progreso | Quedan vistas, acierto global, simulacros y racha. La nota, el acierto por área y la sugerencia de área se reemplazan por una tarjeta Premium |
| Descargas | Descargar abre el muro (candado en la fila). Lo ya descargado se puede borrar |
| Pregunta | Responder sin cupo (403 `LIMITE_DIARIO`): abre el muro y deja un aviso con «Ver Premium», no un error |

## El muro de venta

`/premium?motivo=limite` o `/premium?funcion=<código>` (`MuroDeVentaScreen`).
Se apila y se cierra («Ahora no» o la ×), así que no encierra a nadie.

1. Qué pasó o qué hay detrás: el cupo agotado («Mañana tienes 10 más…») o la
   vista previa de la función.
2. «Con Premium», en cuatro líneas: funciones, no precios.
3. «Tu cuenta gratis sigue: 10 preguntas al día…».
4. Cómo pagar, según la tienda (`OpcionesDePago`, sin cambios): en iPhone,
   App Store; en Android, la web con Mercado Pago.

Si alguien compra desde el muro y la suscripción pasa de gratis a premium, el
muro se cierra solo.

### Diferencias con la web, a propósito

- **Sin ofertas.** El 50 % es solo web, por las normas de las tiendas. El muro
  de la app no lo muestra ni lo menciona (lo comprueba
  `test/gratis_limitado_test.dart` en las dos tiendas).
- **En iPhone, solo App Store** (guía 3.1.1): ningún enlace al pago web.

## Contrato

- `GET /subscription` añade `acceso`:
  - `{"nivel": "premium", "gratis": null}`;
  - o `{"nivel": "gratis", "gratis": {"preguntasPorDia", "restantesHoy", "renuevaEn"}}`.
  Es la única fuente del contador (no `/me`).
- `details` es un mapa de strings. La app solo lee `funcion`; los números salen
  de `GET /subscription`.
- 403 `LIMITE_DIARIO`: el muro de cupo. Crear una práctica sin cupo también lo
  da.
- 403 `FUNCION_PREMIUM` (`details.funcion`): el muro de esa función. Los
  códigos son:
  - `practica_a_medida`;
  - `simulacro`, también el de muestra;
  - `examen_pasado`;
  - `simulacro_nacional`;
  - `sin_conexion`: descargar y también sincronizar.

  Uno desconocido abre el muro genérico, nunca un error.
- La nota proyectada y las estadísticas por área **no** las restringe el
  servidor en la fase 1: el candado de Progreso es solo de la app
  (`FuncionPremium.estadisticas`, que nunca llega en un 403).
- El cliente de red conserva ahora los `details` de un 403 (antes se perdían).

**Con un servidor anterior** (sin `acceso`), la app se comporta como antes: la
prueba vencida bloquea tras «Acceso terminado». Lo decide
`Subscription.bloqueada` y lo fija `test/acceso_test.dart`. Así se puede
publicar antes que el backend.

## Sin conexión en gratis

Si quedaron respuestas sin enviar de la prueba, la sincronización da
`FUNCION_PREMIUM` (`sin_conexion`). La bandeja **no se toca**: la excepción
sale antes de quitar nada, y las respuestas esperan hasta que la cuenta vuelva
a premium. Una descarga que reciba ese 403 no queda marcada como fallida.

## Eventos

El catálogo 6 de BI (`enam-business` 834ba23) añade:

- `muro_visto` {`motivo`, `recurso`|`funcion`, `con_oferta`}; en la app,
  `con_oferta` siempre es `false`;
- `plans_viewed.pantalla = 'muro'`;
- `limite_alcanzado`, que es de servidor.

**No se emiten hasta que el backend valide el catálogo 6**: antes se rechazan y
se pierden. Mientras tanto, el muro registra `plans_viewed` con
`pantalla: acceso_terminado`, porque reemplaza a esa pantalla.

## Probar sin backend

Con datos de ejemplo (`USE_MOCKS`):

- `vencido@enam.pe`, `expirado@enam.pe` y `cancelado@enam.pe`: gratis, con 6 de
  10 preguntas hoy;
- `agotado@enam.pe`: gratis, con el cupo gastado;
- `premium@enam.pe`: premium.

## Pruebas

- `test/gratis_limitado_test.dart`:
  - el modelo y la caché;
  - los 403 y la ruta del muro;
  - la siguiente acción;
  - el muro en las dos tiendas, sin ofertas, y «Ahora no»;
  - Nueva práctica: lo que manda, el candado y los dos 403;
  - responder sin cupo;
  - simulacros.
- `test/acceso_test.dart`: la prueba vencida con `acceso` ya no bloquea, y sin
  él sí.
- `test/inicio_contextual_test.dart`: los dos estados de gratis, y que en
  premium no aparece nada de esto.
- Capturas:
  - `test/golden/gratis_test.dart`: el muro (cupo y función), configurar,
    progreso, simulacros y exámenes pasados;
  - `test/golden/inicio_test.dart`: los estados `gratis` y `gratisAgotado`.
