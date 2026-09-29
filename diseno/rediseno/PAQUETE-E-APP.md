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
el inicio. Si hay respuestas hechas sin señal que aún no llegaron al
servidor, bajo el saludo aparece una etiqueta discreta («2 respuestas por
enviar», «Enviando tus respuestas…»); nunca dice «sincronizado» antes de que
el servidor lo acepte. Mientras se carga por primera vez hay un esqueleto con la geometría
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
  máximo. Es el mismo estilo (`AppTheme.clinicalCase`) en práctica,
  simulacro, revisión y duelo; el duelo pintaba el caso entero en negrita de
  18.
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
- **Reportar** va a `POST /api/v1/questions/{id}/reports` con el motivo
  (`clave|texto|imagen|explicacion`) y la sesión, y dice «Reporte enviado»
  solo si el servidor responde que lo recibió. Si responde 404 (un backend
  todavía sin el endpoint) o no se puede llegar, **cae al WhatsApp de
  soporte** con el código y el motivo escritos; si tampoco hay WhatsApp, lo
  dice y deja el código. Con 429 pide esperar y no lo salta por WhatsApp.
  La hoja avisa antes de a dónde va. La ayuda dejó de prometer la revisión de
  un editor.

**Backend.** El endpoint está en
[enam-backend#4](https://github.com/JerryCode777/enam-backend/pull/4),
todavía sin desplegar. Por eso el respaldo: la app funciona igual antes y
después del despliegue.

**Se comprueba con:** `test/pregunta_test.dart`, `test/reportes_contrato_test.dart`
y las capturas `4.2` y `4.3` de
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

## 10. Mi suscripción (solo lo visual; el flujo de App Store no se toca)

- Con una suscripción de **App Store**, la fila «Renovación» decía «Manual»,
  aunque se renueva sola (lo dice la letra pequeña de la compra). Ahora dice
  «Automática, por App Store».
- Para esas suscripciones, «Cancelar renovación» llamaba a nuestro servidor,
  que **no puede detener el cobro de Apple**: quien lo pulsaba creía haber
  cancelado y Apple seguía cobrando. Ahora la pantalla dice dónde se gestiona
  (Ajustes → tu nombre → Suscripciones) y enlaza a la página de suscripciones
  de Apple. Para los demás medios el botón sigue como estaba.
- No se tocan StoreKit, la verificación ni la restauración, ni se enlaza a
  pagar en la web desde iPhone.

**Se comprueba con:** `test/mi_suscripcion_test.dart`.

## 11. Tema claro por defecto

Pedido del producto, igual que en la web:

- **Claro por defecto**, aunque el sistema esté en oscuro. Antes seguía al
  sistema. «Sistema» queda como opción explícita en Ajustes (Claro · Oscuro ·
  Sistema).
- **Botón sol/luna** junto al avatar del inicio: luna en claro, sol en
  oscuro. Alterna al contrario de lo que se ve.
- La elección **se guarda** (`shared_preferences`, clave `tema`) y se aplica al
  volver a abrir la app. Antes se perdía al cerrarla.
- Las pantallas de acceso (presentación, login, registro, verificar correo,
  recuperar y nueva contraseña, completar perfil) van **siempre en claro**,
  con `SiempreClaro` en el router. Es la misma lista que la web.

**Se comprueba con:** `test/tema_test.dart`.

## 12. Medios de pago: solo App Store (iPhone) y la web con Mercado Pago (Android)

El producto pasa a AIDA SOFT SACS y la cuenta de Yape era del operador
anterior. El pago manual por Yape se retiró de la web y de la portada, y el
cobro va solo por Mercado Pago. En la app:

- **Ayuda.** La pregunta «Yapeé y sigo sin Premium» se reemplaza por «Pagué y
  todavía no tengo acceso», con el mismo texto que la web: con Mercado Pago el
  acceso se activa solo, y si tarda se escribe por WhatsApp con el número de
  operación.
- **Android.** «Activar por WhatsApp» era el canal del pago manual: abría un
  chat con «quiero activar mi cuenta». Ahora el botón es solo de ayuda
  («Escríbenos si necesitas ayuda», mensaje «necesito ayuda con mi acceso»).
  El pago es «Continuar en el navegador», con la sesión ya iniciada, y ahí
  Mercado Pago.
- **iPhone.** Se quitó la nota con la dirección del sitio: abría `/activar`,
  la pantalla desde la que se paga en la web, y en iPhone eso es ofrecer un
  medio de pago que no es App Store (guía 3.1.1). Queda solo la compra por
  App Store y el WhatsApp de ayuda. StoreKit, la verificación y la
  restauración no se tocan.
- Se borran del código el número y el texto del «asistente de ventas» por
  WhatsApp, que ya no se usaban.

Los textos legales marcados `PENDIENTE(titular)` siguen como estaban.

**Se comprueba con:** `test/cobro_por_tienda_test.dart`. La variante de
iPhone se simula con `debugDefaultTargetPlatformOverride`: `enTiendaApple` usa
ahora `defaultTargetPlatform`, que en el teléfono dice lo mismo que
`Platform.isIOS`.

## 13. Figura de marca

Una doctora **ilustrada con IA** (ChatGPT), sin nombre ni identidad real. La
revisó y aprobó la dirección del proyecto. No es una persona del equipo ni
una médica real, y no se presenta como tal.

**Recursos.** `assets/images/doctora_brazos_cruzados.webp` (400 × 592) y
`assets/images/doctora_senala.webp` (300 × 451): recortados al contorno,
WebP con transparencia a ~2× del tamaño en pantalla, **46 KB entre los dos**
(presupuesto: 200 KB). Se decodifican al tamaño en que se pintan
(`cacheWidth`). Los originales, `foto01.png` y `foto02.png` de 1024 × 1536,
**no se versionan** (el repositorio es público y pesan 1,8 MB cada uno); los
tiene la dirección del proyecto y la web usa los mismos.

**Dónde.**

| Pantalla | Figura | Cuándo |
|---|---|---|
| Presentación | Brazos cruzados, a la derecha de los beneficios, de pie detrás de la tarjeta de ejemplo (que tapa el corte a la cintura) | Siempre. 40 % del ancho con 800 dp de alto útil o más; 33 % por debajo (13 mini, 14 Pro), para que el ejemplo quepa entero (§14) |
| Inicio, bloque «Tu primer paso» / «Tu siguiente paso» / «Elige un área» | Señalando el texto, de pie detrás del botón | Solo si el contenido del bloque mide 340 dp o más: teléfonos de ~430 dp (17 Pro Max) y tabletas. En 393 dp no aparece: apretaría el texto |

No aparece al retomar una sesión ni sin conexión, donde el aviso tiene que
leerse sin adornos, ni en pantallas de pago, ni como testimonio.

**Reglas** (`FiguraDeMarca`, `lib/shared/widgets/figura_de_marca.dart`):
decorativa (`excludeFromSemantics`, sin etiqueta); sin nombre, cargo ni
frase; siempre apoyada en un borde que tape el corte.

Las capturas de acceso del banco se envuelven ahora en `SiempreClaro`, como
en el router: la «oscura» de la presentación retrataba un tema que el usuario
nunca ve.

**Se comprueba con:** `test/figura_de_marca_test.dart` (dónde aparece y dónde
no, texto al 140 %, semántica, peso de los recursos) y las capturas. Antes y
después: `antes-despues/figura-inicio-*.png` y, para la presentación,
`antes-despues/acceso-claro-presentacion-*.png`.

## 14. Acceso en el tema claro

**Antes.** `SiempreClaro` fijaba los tokens en claro, pero la presentación, el
login, el registro, verificar correo, recuperar y nueva contraseña y
completar perfil seguían pintando a mano el degradado azul marino a pantalla
completa, con títulos y botones en blanco. Además, en el 14 Pro la tarjeta de
ejemplo de la presentación quedaba cortada por los botones fijos.

**Ahora**, igual que la web (`cc94b56`):

- **Fondo** `FondoClaro`: el fondo de la app (`#F5F7FA`) con dos halos suaves
  del azul de marca, al 16 % arriba a la izquierda y al 12 % abajo a la
  derecha. Lo usan `AuthScaffold` (registro, recuperar, nueva contraseña,
  completar perfil), el login, verificar correo y la presentación.
- **Marca y textos en tinta**: el azulejo de marca (la cruz blanca sobre su
  fondo azul), títulos en `text`, bajadas en `text-secondary`.
- **Botones**: el principal sólido de acción («Crear cuenta gratis»,
  «Ingresar», «Verificar cuenta»), el secundario con borde («Ya tengo
  cuenta», «Reenviar código»). El campo del código de verificación es el
  campo claro de la app, en grande.
- La **pantalla de carga** conserva el degradado de marca, como se pidió.

**La tarjeta de ejemplo nunca se corta.** En pantallas de menos de 800 dp de
alto útil (13 mini, 14 Pro) la presentación se compacta: título de 26, marca y
huecos algo menores, los beneficios con textos más cortos y el porqué del
ejemplo en una frase. Si aun así no cabe (letra del sistema ampliada), la zona
de botones muestra un borde arriba, para que se lea como el límite de algo que
se desplaza y no como una tarjeta partida.

**Se comprueba con:** `test/onboarding_test.dart`, que con la tipografía real
y la muesca del teléfono mide que el ejemplo termina por encima del botón en
13 mini, 14 Pro y 17 Pro Max. Antes y después:
`antes-despues/acceso-claro-presentacion-*.png` y
`antes-despues/acceso-claro-login-*.png`.

## 15. Sonidos

Pedido del usuario: la app no tenía sonidos y sus otras apps sí. El plan (§7)
decía «sin efectos sonoros nuevos»; este pedido explícito lo cambia.

**Origen.** Los siete sonidos de **Rumbo** (`rumboapp`, del mismo dueño), con
el mismo catálogo y la misma lógica (`rumboapp/mobile/lib/nucleo/sonido/`).
Los WAV se pasaron a MP3 mono de 96 kbps (el formato de la web); el clic y el
de pestaña se copiaron tal cual. **142 KB en total** (los originales sumaban
2,1 MB), en `assets/sonidos/`. El motor es `audioplayers` ^6.8.1, el mismo que
Rumbo.

| Sonido | Archivo | Dónde suena |
|---|---|---|
| `toque` | `click_normal.mp3` | Al elegir una alternativa (práctica, simulacro, duelo) |
| `pestana` | `select_002.m4a` | Al cambiar de pestaña |
| `empiezaQuiz` | `start_quiz.mp3` | Al empezar una práctica, un simulacro, un examen pasado, el nacional, una práctica descargada, «repasar las incorrectas» y la primera pregunta de un duelo |
| `acierto` / `fallo` | `good_answer.mp3` / `bad_answer.mp3` | **Solo** cuando la pantalla revela si se acertó: la práctica con corrección inmediata y el cierre de cada pregunta del duelo (en blanco no suena). **Nunca** en un simulacro ni en un examen pasado: la clave está oculta hasta el final y el sonido la delataría (RF-16) |
| `buenResultado` / `malResultado` | `good_score.mp3` / `bad_score.mp3` | Al ver el resultado, una vez: nota ≥ 11 o duelo ganado → bueno; si no (empate incluido), malo |

**Vibración** como Rumbo: `selectionClick` al elegir una alternativa y al
cambiar de pestaña; nada al acertar ni al fallar. Se mantiene la vibración
corta de «Responder».

**Preferencia** en Ajustes → Sonidos: interruptor y volumen, guardados en
`shared_preferences` con las claves de Rumbo (`sonido_activo`,
`sonido_volumen`). Por defecto, activos a 0,6.

**Silencio y música.** En iOS, categoría `ambient`: respeta el interruptor de
silencio y se mezcla con la música del usuario sin cortarla. En Android, uso
de «sonido de interfaz» y sin pedir el foco de audio.

Nada suena en la presentación ni en las pantallas de acceso. En `flutter test`
los reproductores son mudos (no hay plugin de audio); las pruebas del sonido
inyectan uno que anota lo que suena (`reproductoresDeSonido`).

**Se comprueba con:** `test/sonidos_test.dart`: umbral de 11, activos a 0,6
por defecto, apagados no suena nada, el volumen elegido es el que suena y se
guarda, acierto o fallo en la práctica y **nunca** en el simulacro, y los siete
archivos existen y pesan menos de 200 KB.

**Límite.** Probado con reproductores simulados. Falta escucharlo en un
teléfono: el modo silencio, la mezcla con música y el volumen real.

## 16. Eventos del embudo conectados

La interfaz de analítica, que estaba sin proveedor, ahora manda a
`POST /api/v1/eventos` según el contrato de eventos v1 de
`enam-business/contrato/`. El detalle está en [`EVENTOS.md`](EVENTOS.md). En
resumen:

- **Solo los eventos de cliente de la app:** `signup_started` (con `metodo`,
  antes `origen`), `plans_viewed` (con `pantalla`, ahora también en «Mi
  suscripción») y, en iOS, `checkout_started` al pulsar comprar.
  `signup_verified` y `profile_completed` pasaron al servidor y se quitaron
  de la app.
- **Propiedades comunes:** plataforma, `version_app` (con `-dev` fuera de la
  tienda), versión visual y un `anonimo_id` del dispositivo. Nunca
  `usuario_id`. Se fijan al generar el evento y viajan con él en la cola: al
  vaciarla sale un sobre por cada combinación, así que lo encolado antes de
  una actualización conserva su versión (contrato, §4, `4beea62`).
- **Envío:** cola persistente (500 eventos, 7 días), lotes de 50, reintentos
  con los mismos `evento_id` y token opcional que se renueva una vez.
- **Altas:** registro, Google y Apple llevan `anonimoId`, y todas las
  peticiones llevan `X-Plataforma`, para que el servidor una la visita con la
  cuenta.
- El envío va por un cliente propio, sin el interceptor de sesión: un fallo
  de la analítica no puede cerrar la sesión de nadie ni mostrar nada.

**Se comprueba con:** `test/emisor_de_eventos_test.dart`,
`test/analitica_test.dart` y `test/alta_con_anonimo_test.dart`.

**Límite.** El backend todavía no tiene el endpoint. Hasta entonces el envío
falla en silencio y los eventos esperan en la cola, sin que nada lo note.

## 17. Universidad con buscador

Completar perfil y Editar perfil tenían cada uno su lista fija de siglas, y
se guardaba el texto suelto («UNSA», «U. San Agustín»…). Ahora las dos
pantallas abren el mismo buscador sobre `GET /api/v1/catalog/universidades`,
que es público (`lib/features/universidades/`).

- **Buscador.** Por nombre o siglas, sin tildes ni mayúsculas, con las
  palabras en cualquier orden. Arriba «Con Medicina» y debajo «Otras
  universidades», en el orden del catálogo.
- **Qué se guarda.** `PATCH /me` recibe solo `universidadId`. Si no está en
  la lista, «Mi universidad no está en la lista» pasa a un campo de texto
  (hasta 120 caracteres, con lo buscado ya escrito) y se manda
  `universidadId: "otra"` con el nombre. Si la universidad no se tocó, no se
  manda.
- **Lo que se muestra.** El perfil trae `universidadId`. Con el catálogo a
  mano se muestra el nombre del catálogo; sin él, el texto guardado. Los
  perfiles viejos con siglas los traduce el backend (su mapeo de siglas y
  nombres heredados).
- **Caché.** El catálogo se guarda en el teléfono un día, como su
  `Cache-Control`. Sin red se usa la copia aunque sea vieja. Sin red y sin
  copia, el buscador lo dice, deja reintentar y deja escribir «Otra».
- **Ranking.** El podio acorta a las siglas cuando las hay, venga el nombre
  largo o las siglas viejas. La fila admite el nombre en dos líneas.

**Se comprueba con:** `test/universidades_test.dart` (búsqueda, nombre
mostrado, caché y cuerpo del `PATCH`) y `test/buscador_de_universidad_test.dart`
(buscar, elegir, «Otra», sin red, y Editar perfil guarda el id).
`test/fixtures/universidades.json` es la respuesta real de producción
(143 universidades, 42 con Medicina), tomada con un solo `GET` público; no se
hizo ningún `PATCH` contra producción.
