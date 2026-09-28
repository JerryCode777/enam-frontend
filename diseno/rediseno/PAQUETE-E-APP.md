# Paquete E — la app Flutter

Parte del rediseño de `PLAN-UI-SEO-PARA-OPUS.md` (§5, §7 y §13). Cada apartado
corresponde a un commit de la rama `rediseno-ui` y dice qué cambió, por qué y
cómo se comprueba.

## 1. Arranque

**Antes.** El splash esperaba 1,8 s como mínimo aunque la sesión y las
preferencias estuvieran listas en ~200 ms, con el logo latiendo, un ECG y una
barra en bucle. Si la comprobación de la sesión fallaba, la app se quedaba en
el splash para siempre.

**Ahora.**

- Sin espera mínima: la app entra en cuanto el router sabe a dónde ir. Las
  preferencias y la sesión se piden en paralelo, y ningún temporizador del
  splash decide el destino.
- La marca es estática. Si algo tarda más de 400 ms aparece «Cargando…» sin
  porcentajes. A los 8 s dice «Está tardando más de lo normal» y ofrece
  reintentar; si la sesión no se pudo comprobar, lo dice en seguida. El botón
  no lanza un segundo intento mientras el primero sigue en curso.
- **Arranque sin señal.** Con sesión iniciada y sin red, `GET /me` fallaba y
  no había forma de entrar, ni siquiera para usar lo descargado. Ahora el
  repositorio recuerda el último perfil (en el almacenamiento seguro, junto a
  los tokens) y entra con él cuando no se pudo preguntar. Si el servidor
  responde que la sesión no vale, manda el servidor. El perfil se borra al
  cerrar sesión.
- **Cambio de usuario.** El dashboard y el ranking no dependían del usuario:
  quien entraba después de otra persona en el mismo teléfono veía sus cifras
  hasta que algo forzara una recarga. Ahora se descartan al cambiar de cuenta.

**Se comprueba con:** `test/splash_test.dart`, `test/arranque_test.dart`,
`test/arranque_sin_red_test.dart` y `test/cambio_de_usuario_test.dart`.

**Límite.** Las mediciones de arranque en frío y en caliente en modo profile,
en un dispositivo representativo, siguen pendientes (plan §11). Lo que ya no
depende del hardware es la espera artificial, que se retiró.

## 2. Inicio contextual

**Antes.** Once tarjetas de peso parecido: portada en degradado, racha, duelo
(también en degradado, por encima de «Practicar»), dos accesos grandes,
exámenes pasados, tres métricas en tarjetas iguales, cuatro áreas, la nota
proyectada con una variación semanal **escrita en el código** («+0.60 esta
semana») y el nacional.

**Ahora.** Una cabecera compacta (saludo y cuenta regresiva), un **bloque de
siguiente acción** que cambia según el estado, y debajo, más pequeños: los
accesos de estudio, el progreso (tres cifras como máximo, racha, y la nota
solo con 50 respuestas o más) y al final el nacional y el duelo.

La regla es una función pura, `decidirSiguienteAccion`
(`lib/features/home/domain/siguiente_accion.dart`), con el mismo orden y los
mismos titulares que la web:

| Estado | Titular | Acción |
|---|---|---|
| Sesión a medias | «Continúa tu práctica» / «Termina tu simulacro» | Retomar, con «Pregunta N de M» y barra de avance |
| Sin red | «Practica sin conexión» / «Sin conexión por ahora» | Ir a lo descargado |
| Sin ninguna respuesta | «Empieza con una práctica corta» | Configurar con 10 preguntas, editable |
| Con historial | «Practica ‹área›» + «Pesa N preguntas en el ENAM y vas en X % de acierto» | Practicar esa área; o elegir otra |
| Dashboard o catálogo caídos | «Elige un área para practicar» | Configurar, sin porcentajes |

El acceso vencido lo sigue resolviendo la guarda del router, antes de pintar
el inicio. Mientras se carga por primera vez hay un esqueleto con la geometría
del bloque; en una recarga el bloque se queda y solo cambia su contenido.

**Se comprueba con:** `test/siguiente_accion_test.dart` (la regla),
`test/inicio_contextual_test.dart` (la pantalla en cada estado, que la acción
quepa en 390 × 844 y que no haya cifras inventadas) y
`test/golden/inicio_test.dart` (capturas de los seis estados).
