# Cambios

Las notas para las tiendas de cada versión están en `notas-de-version/`.

## 1.1.1 (9): sin publicar

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
