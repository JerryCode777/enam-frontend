# Informe del rediseño — app Flutter

Paquetes A, B, E, F y G de `PLAN-UI-SEO-PARA-OPUS.md` en la parte que toca a
`enam-frontend`. Rama `rediseno-ui`, 19 commits sobre `main` (`01b95a8`). La
landing, la web y el backend los llevan otras sesiones. Los tokens, las reglas
del inicio y el diccionario de eventos se acordaron con ellas.

## Documentos

| Documento | Qué contiene |
|---|---|
| [`LINEA-BASE.md`](LINEA-BASE.md) | Estado antes de empezar y hallazgos |
| [`../TOKENS.md`](../TOKENS.md) | Tabla fuente de tokens compartida con la web |
| [`PAQUETE-E-APP.md`](PAQUETE-E-APP.md) | Cada cambio de pantalla: antes, ahora y cómo se comprueba |
| [`EVENTOS.md`](EVENTOS.md) | Diccionario de eventos y qué emite cada plataforma |
| [`antes-despues/`](antes-despues/) | Capturas comparadas, iPhone 14 Pro, claro y oscuro |

## Qué cambió

**Sistema visual (B).** Hay nuevos tokens, con los mismos valores y nombres que
la web: fondo frío, texto azul marino y un color de acción plano que cumple AA
en los dos temas. El botón principal deja el degradado. Los radios quedan en
12/16/24, el enunciado clínico en 17/1,6 y el movimiento en 140/220/350 ms con
un escalonado de 30 ms. Hay componentes compartidos (siguiente acción, resumen
métrico, fila de área, etiqueta de estado, estados vacío y de error) y una
galería en `/dev/componentes`, solo fuera de release. Un test fija los valores
y los contrastes de cada par.

**Pantallas (E).** Ver `PAQUETE-E-APP.md`. En resumen:

1. **Arranque** sin espera artificial de 1,8 s. Si tarda, lo dice y deja
   reintentar. Se abre sin señal con el último perfil conocido.
2. **Inicio contextual.** Una siguiente acción según el estado (retomar, sin
   conexión, primera práctica, área prioritaria o elegir área), con la misma
   regla y los mismos titulares que la web.
3. **Pregunta.** Enunciado a 17 px, columna de lectura, el veredicto a la vista
   al responder y la explicación ordenada. «Reportar» va al endpoint de
   reportes y, si el backend aún no lo tiene o no hay red, al WhatsApp de
   soporte con el código de la pregunta.
4. **Resultado de práctica** con cifras que cuadran y una siguiente acción.
5. **Temario.** «Aún sin práctica» en vez de 0 %.
6. **Descargas.** Cancelar, reintentar desde la fila y fecha del paquete.
7. **Presentación** en una pantalla con ejemplo y acción directa.
8. **Progreso.** Misma sugerencia que el inicio y la gráfica también en tabla.
9. **Simulacros.** Convocatoria nacional real y acciones según el estado.
10. **Mi suscripción.** Las de App Store se renuevan solas y se cancelan en
    Apple.
11. **Tema.** Claro por defecto, botón sol/luna en el inicio, la elección se
    guarda y las pantallas de acceso van siempre en claro.
12. **Medios de pago.** Solo App Store en iPhone y la web con Mercado Pago en
    Android. Se retiraron el pago manual por Yape, la activación por WhatsApp y
    el enlace a la web desde iPhone.
13. **Figura de marca** (ilustración generada con IA): en la presentación y,
    solo en pantallas anchas, en el bloque de siguiente acción del inicio.
    Decorativa, 46 KB.
14. **Acceso en el tema claro**: presentación, login, registro, verificación,
    recuperar y nueva contraseña y completar perfil, sobre el fondo claro con
    halos de marca, como la web. La tarjeta de ejemplo cabe entera en los
    teléfonos bajos.

**Eventos (F).** Interfaz y disparadores sin proveedor. Ver `EVENTOS.md`.

## Datos falsos o engañosos que había y ya no

| Dónde | Qué decía | Ahora |
|---|---|---|
| Inicio, nota proyectada | «+0.60 esta semana», escrito en el código | Sin variación hasta que el servidor la mande |
| Simulacros, nacional | «dom 16 ago · 1,847 participantes», sin convocatoria | La convocatoria de `GET /mock-exams`, o «no hay» |
| Pregunta, reportar | «Gracias. Un editor va a revisarla.», sin enviar nada | `POST /questions/{id}/reports`; WhatsApp de respaldo |
| Ayuda | Prometía la revisión de un editor | Explica que se envía por WhatsApp |
| Resultado de práctica | Las en blanco contadas también como falladas | Correctas, incorrectas y en blanco por separado |
| Resultado de práctica | Anillo de «aprobado» por 10 preguntas | Color neutro y «Resultado de tu práctica» |
| Temario | «acierto 0 %» con vistas pero sin respuestas | «aún sin práctica» |
| Mi suscripción (App Store) | «Renovación: Manual» y un cancelar que no cancela | «Automática, por App Store» y dónde cancelarla |
| Dashboard y ranking | Cifras de la cuenta anterior tras cambiar de usuario | Se descartan al cambiar de cuenta |

## Fallos que salieron al revisar

- Con sesión y sin red, la app **no pasaba del splash**. Arreglado: arranca con
  el último perfil conocido.
- En oscuro, la letra de la alternativa elegida iba en blanco sobre la acción
  aclarada y no se leía; los iconos de correcta e incorrecta daban 2,5:1.
- Los tokens de texto terciario, borde de control, rojo de error e info
  oscuro no llegaban a AA.
- Tres capturas dependían del reloj real y habrían fallado al día siguiente.

## Validación

| Comprobación | Antes (`01b95a8`) | Ahora (`1ed726d`) |
|---|---|---|
| `flutter analyze` | Sin problemas | Sin problemas |
| `flutter test` (todo) | 530 | **710**, todos aprobados |
| Capturas (golden) | 84 | 176 |

Las pruebas nuevas son de comportamiento, no copias de widgets: la regla del
inicio, el veredicto visible al responder, el conteo del resultado, el arranque
sin red y con reintento, cancelar y reintentar descargas, el cambio de cuenta,
los contrastes de los tokens, el filtro de propiedades de los eventos, el
teclado abierto y el texto al 140 % en 360 px.

## Límites

- **No se probó en dispositivos.** Las capturas son de `flutter test` con la
  tipografía real. Faltan un recorrido en iPhone y Android físicos, las
  mediciones de arranque en frío y en caliente en modo profile, y los tiempos
  de fotograma al desplazar y practicar (plan §11).
- **Lector de pantalla:** se añadieron etiquetas semánticas donde el rediseño
  tocó (alternativas, veredicto, resumen, gráfica, cifras), pero no se hizo un
  recorrido con VoiceOver o TalkBack.
- Pantallas que solo recibieron los tokens, sin rediseño propio: acceso
  (login, registro, verificación), temario por área, ranking, duelo, ajustes,
  ayuda y legales.
- Los datos de las capturas son de ejemplo (repositorios falsos). Las del
  inicio lo son explícitamente; ninguna se presenta como resultado de alumnos.

## Pendientes externos

| Pendiente | Quién |
|---|---|
| Desplegar `POST /api/v1/questions/{id}/reports` (enam-backend#4); la app ya lo usa, con WhatsApp de respaldo mientras tanto | Backend |
| Emitir `first_practice_completed`, `payment_confirmed`, `access_granted` | Backend |
| Elegir proveedor de analítica y comprobar la recepción | Negocio |
| Crashlytics y notificaciones push | Negocio: requieren cuentas y configuración |
| Razón social, RUC y dirección de AidaSoft para los textos legales (`PENDIENTE(titular)`) | Negocio |
| Evolución semanal real de la nota, si se quiere volver a mostrar | Backend |
| Recorrido en dispositivos y mediciones en modo profile | Quien tenga los dispositivos |

## Cómo revertir

Todo vive en la rama `rediseno-ui` y no hay nada publicado en las tiendas.

- Descartar el rediseño entero: no fusionar la rama.
- Quitar una parte: `git revert <commit>` del apartado correspondiente. Los
  commits son independientes salvo el del sistema visual (`f1efc9f`), del que
  dependen los demás.
- Tras fusionar, revertir el merge. Las capturas del banco vuelven con él.

No hay migraciones de datos. Lo único nuevo en el almacenamiento es el perfil
guardado para arrancar sin red (`enam.usuario`, en el almacenamiento seguro),
que se borra al cerrar sesión y no afecta a una versión anterior.
