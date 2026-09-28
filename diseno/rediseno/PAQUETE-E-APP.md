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

## 3. Pregunta y explicación

**Antes.** Enunciado a 16 px. Al responder, la pantalla se quedaba donde
estaba: en un caso clínico largo, lo primero que se veía era otra vez el
enunciado, con el veredicto y la explicación debajo del borde. En la
explicación, tu respuesta errada iba antes que la correcta, y los distractores
a 12 px pegados al texto de la alternativa. Las etiquetas de área enseñaban
identificadores internos («medicina-infecciosos»). «Reportar» agradecía
(«Un editor va a revisarla») sin enviar nada.

**Ahora.**

- Enunciado a **17 px con interlineado 1,6**, en una columna de 720 px como
  máximo.
- Al confirmar, la pantalla baja sola hasta el **veredicto** («Correcto. Elegiste
  la A» / «Incorrecto. La correcta es la C»), dicho con texto, icono y color y
  anunciado al lector de pantalla. Después, la correcta, tu respuesta si
  fallaste, el porqué, y «Por qué no las demás» a tamaño de lectura con la
  letra delante. Las etiquetas muestran el nombre del temario.
- Seleccionar sigue sin responder; confirmar da una vibración corta, la única
  de la pantalla.
- Reportar, marcar y avanzar son tres controles distintos: el marcador en la
  cabecera, «Reportar» con borde e icono a un lado, «Siguiente» como botón
  principal.
- **Reportar** abre el WhatsApp de soporte con el código de la pregunta y el
  motivo ya escritos, y la hoja lo dice antes de elegir. Si WhatsApp no se
  puede abrir, lo dice y deja el código. La ayuda dejó de prometer la revisión
  de un editor.

**Pendiente de backend.** `POST /api/v1/questions/{id}/reports` (motivo
`clave|texto|imagen|explicacion`, comentario opcional, `sessionId` opcional;
201, 404, 429). Está acordado con la sesión del backend y en cola detrás de
Mercado Pago. Cuando exista, `_reportar` cambia de destino; los códigos de
motivo ya están en `_BarraAccion.motivos`.

**Se comprueba con:** `test/pregunta_test.dart` y las capturas `4.2` y `4.3` de
`test/golden/estudio_test.dart`.
