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

## 4. Resultado de la práctica

**Antes.** «Fallaste 8» y «Dejaste en blanco 3» con 2 correctas de 10: las en
blanco se contaban dos veces. El tiempo era la diferencia entre el inicio y el
fin de la sesión (retomar al día siguiente daba «1 440 min»), y con tiempos
cortos decía «0 s por pregunta». El anillo se pintaba de verde o ámbar según
si esas diez preguntas «aprobarían» el ENAM, una comparación engañosa.

**Ahora.** Dice qué fue («Resultado de tu práctica · 10 preguntas»). El
anillo va en el color de acción. El desglose es correctas / incorrectas / en
blanco, sin solaparse. El tiempo sale de lo registrado en cada pregunta y no
aparece si no hay. Una sola acción principal: repasar las incorrectas si las
hay, otra práctica si no.

**Se comprueba con:** `test/resumen_practica_test.dart` y la captura `4.4`.

## 5. Temario sin práctica

Sin respuestas no hay dominio que medir. El temario, las prioridades y el
progreso dicen ahora lo mismo, «Aún sin práctica», donde antes alternaban
«Sin empezar» y «sin datos». Se corrige además un caso que sí mentía: un tema
con preguntas vistas pero sin respuestas contadas decía «acierto 0 %».

**Se comprueba con:** `test/temario_sin_practica_test.dart`.

## 6. Descargas

Ya mostraba el tamaño real, el progreso cuando el servidor dice cuánto pesa, y
lo pendiente de enviar. Faltaba:

- **Cancelar.** Mientras un área baja, su botón la corta. Lo recibido se
  descarta y no cuenta como fallo. Por dentro viaja un `CancelToken` desde la
  pantalla hasta dio.
- **Reintentar a la vista.** Si falla, la fila lo dice («No se pudo descargar.
  Toca para reintentar.») y su botón reintenta. Antes solo había un aviso que
  desaparecía. Si lo que falta es el plan, se sigue llevando al pago.
- **Fecha.** «actualizada el 20 jul» (cuándo generó el servidor el paquete) en
  lugar de un «al día» sin referencia.

La pantalla nunca dice «sincronizado»: lo pendiente sale de la bandeja local y
desaparece solo cuando el servidor lo acepta.

**Se comprueba con:** `test/descargas_pantalla_test.dart`.

## 7. Presentación (onboarding)

**Antes.** Un carrusel de tres pasos con viñetas; crear la cuenta pedía pasar
por los tres.

**Ahora.** Una pantalla: el beneficio en una frase, tres líneas de qué ofrece
la app (explicaciones, simulacro de 180 preguntas y 3 horas, estudio sin
señal), un **ejemplo rotulado como tal** de pregunta respondida y dos
acciones fijas abajo: «Crear cuenta gratis» y «Ya tengo cuenta». Dice la regla
real de la prueba: las 24 horas empiezan con la primera práctica, no al
registrarse.

El ejemplo es deliberadamente de manual (adrenalina intramuscular en la
anafilaxia) para no enseñar nada discutible. No es una pregunta del banco.

El perfil obligatorio (universidad, condición, fecha objetivo) se mantiene:
quitarlo es un cambio de negocio que el plan deja fuera.

**Se comprueba con:** `test/onboarding_test.dart` y la captura `1.2`.

## 8. Progreso

- «Dónde invertir tu tiempo» usa el mismo dato y el mismo texto que el inicio
  («Pesa N preguntas en el ENAM y vas en X % de acierto»). Antes tomaba el
  acierto del catálogo, que el servidor manda todavía en cero, y podía
  contradecir al inicio sobre el mismo área.
- La evolución de la nota tiene **alternativa en tabla** («Ver como tabla») y
  un resumen para lector de pantalla. El trazo solo no se lee sin vista.
- Se mantiene el umbral de 50 respuestas para la nota proyectada.

**Se comprueba con:** `test/progreso_test.dart`.

## 9. Simulacros

- La tarjeta del **Simulacro Nacional** tenía escrito «dom 16 ago, 8:00 a.m. ·
  1,847 participantes»: se veía aunque no hubiera convocatoria, con una cifra
  de inscritos que no salía de ningún sitio. Ahora usa la convocatoria real
  de `GET /mock-exams` y, si no hay, dice «No hay una convocatoria programada
  por ahora».
- Cada tarjeta dice lo que hará según el estado real: «Comenzar» o «A medias ·
  continuar en la pregunta N de 180» para el completo (y al tocarla continúa
  en vez de empezar otro), «Inscribirme», «Ya estás inscrito», «En curso ·
  entrar» o «Ver resultados» para el nacional.

**Se comprueba con:** `test/simulacros_hub_test.dart`.
