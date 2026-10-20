# Cambios

Las notas para las tiendas de cada versión están en `notas-de-version/`.

## 1.1.2 (10): sin publicar

**Antes de compilar:** tiene que estar desplegado en producción el PR B del backend (enam-backend-07): el origen `fin_dia_gratis` y el catálogo 25 de BI. Sin él, el servidor responde 422 a «Sí» o «No», la tarjeta se queda con el error y los eventos se rechazan con `TIPO_DESCONOCIDO`.

- **Permiso de correos comerciales al terminar el día gratis.** Aprobado por Jerry el 19/10/2026; igual que la web.
  - Una tarjeta arriba del inicio, solo para quien no decidió (`aceptaComerciales` nulo) y con el día gratis ya terminado (plan `trial`, `expira > inicia` y ya pasado). Sale una sola vez por cuenta en el teléfono; en la visita en que sale, sigue en el inicio aunque se navegue.
  - El texto es el de marketing (enam-marketing 4dcb4ef): «¿Te avisamos de descuentos y novedades?». Es igual que la web, salvo que aquí dice «puedes cambiarlo cuando quieras en Ajustes».
  - Dos botones del mismo tamaño y el mismo estilo, «Sí, avísenme» y «No, gracias», y la política a un toque. Nada premarcado y ningún descuento prometido. Cerrarla con la X no decide nada. Tras el sí: «Listo. Puedes cambiarlo cuando quieras.».
  - Analítica del catálogo 25, igual que la web: `consentimiento_visto` cuando aparece y `consentimiento_respuesta` (`si`, `no` o `cerro`) al tocar, antes del PATCH, con `lugar = fin_dia_gratis`.
  - `PATCH /me {aceptaComerciales, origenConsentimiento: "fin_dia_gratis"}`. Si falla, la tarjeta queda abierta con el error y se puede tocar otra vez.
  - No coincide con el aviso del día gratis: ese se va justo al vencer.
- **Ajustes:** el interruptor «Novedades y ofertas por correo» (origen `ajustes`), para cambiar la decisión cuando quiera.
- **Eventos básicos para BI** (20/10/2026, pedido del director). Hasta la 1.1.1 la app solo mandaba `signup_started`, `plans_viewed` y, en iOS, `checkout_started`. Ahora suma:
  - `muro_visto` (catálogo 6) en cada apertura del muro: `limite` con `recurso: preguntas`, o `funcion` con su código; `con_oferta: false`. `plans_viewed` sigue al lado, para no cortar la serie.
  - `curso_visto` (catálogo 10) al abrir un curso desde el catálogo (`desde: catalogo`) o por un enlace (`enlace`). Sin origen conocido, no se manda.
  - `registro_visto` (catálogo 19) al abrir el registro con correo, y `registro_fallido` cuando falla el registro o la entrada: correo, Google o Apple, con su motivo (`correo_en_uso`, `proveedor_cancelado`, `red`…).
  - La analítica de la app ahora manda booleanos y códigos con el tipo que exige el contrato.
  - Sin `dispositivo` ni `pantalla` en el registro: en el contrato son solo de la web, y con ellos el servidor rechazaba el evento entero. `test/contrato_eventos_test.dart` valida cada evento que la app puede mandar contra la copia del contrato del backend, con sus mismas reglas (`solo_en`, `obligatoria_si`, `ausente_si`, tipos).
  - El cupo agotado y la primera práctica ya los cuenta el servidor (`limite_alcanzado`, `first_practice_completed`). `oferta_vista` es solo de la web.

## 1.1.1 (9): compilada, sin publicar

Compilada desde la rama del #20 (firma de AIDA SOFT). Si nunca se envió a revisión, la 1.1.2 (10) la reemplaza y lleva todo lo de abajo.


- **Día gratis de 24 h (#17).** Las cuentas nuevas vuelven a tener un día gratis, que pone el servidor: todo menos los cursos completos.
  - «Mi suscripción» dice «Día gratis», con la hora de fin, y nunca «prueba».
  - El muro dice lo que incluye el día gratis y no fija ningún número del cupo.
  - Si el acceso vence en medio de un simulacro, la app lo avisa y abre el muro, en vez de dejar «Responder» sin respuesta.
  - En el inicio y en el resultado de la práctica, un aviso con lo que trae y cuánto queda: «Tu día gratis: práctica sin límite, simulacros y estadísticas. Te quedan X h. En los cursos ves sus clases gratis.». Antes de la primera práctica dice «Tu día gratis empieza con tu primera práctica…». Es el mismo texto que la web, sin precios.
- **Sin «oficial» (#16):** «con la distribución del ENAM» en vez de «blueprint oficial», y «los nombres de ASPEFAM».

## 1.1.0 (8): subida a App Store

Compilada desde 3d6be54 más el #15 (mínimo iOS 15, Flutter 3.47.7). Lleva también los textos sin «en video» (ebd6f70) y «3 clases gratis» en la tarjeta del curso (#14). Al 11/10/2026 estaba en revisión en App Store.

- **Rediseño (#1):**
  - un sistema visual nuevo;
  - un inicio que dice qué hacer hoy;
  - datos que no mienten, como la fecha del ENAM (22/11/2026) o que no se muestra el tamaño del banco.
- **Gratis limitado (#2).** Al no tener Premium, la app sigue abierta con preguntas cada día. Las funciones de pago llevan su etiqueta y abren el muro de venta.
- **Sin día de prueba ni oferta.** Las cuentas nuevas entran directo a gratis, y no hay descuento. En la 1.1.1 vuelve un día gratis, que pone el servidor.
- **Aula de cursos (#5, #7, #12):**
  - catálogo, curso y clase, con portadas;
  - reproductor con subtítulos, velocidades, pantalla completa y retomar donde quedó;
  - la práctica de cada tema;
  - las clases gratis de cada curso;
  - el muro de venta con la función «cursos».
- **Pagos:**
  - en Android, ningún camino de compra fuera de Google Play (#3);
  - en iPhone, solo App Store (#8).
- **Titular AIDA SOFT S.A.C.S. (#4)** y **contacto de soporte nuevo (#6).** Los ids de las tiendas (`pe.jakstech.*`) no cambian.

## 1.0.0 (7): publicada

El binario que Apple pidió tras el rechazo 2.1(b).
