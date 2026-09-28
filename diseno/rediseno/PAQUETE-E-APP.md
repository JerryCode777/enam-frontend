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
