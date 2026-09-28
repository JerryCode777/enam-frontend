# Línea base del rediseño — app Flutter

Paquete A de `PLAN-UI-SEO-PARA-OPUS.md` (§13), solo para `enam-frontend`. Tomada
el 28/09/2026 sobre `main` en `01b95a8`, antes de tocar una línea de interfaz.

> Esta carpeta es `diseno/` y no `docs/` a propósito: `docs/` está ignorada
> porque ahí se guarda material privado (SSD, contrato) y el repositorio es
> público. Aquí solo hay documentación de diseño, sin datos confidenciales.

## Estado verificado

| Comprobación | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| `flutter test` | 530 aprobados, 0 fallidos (igual que la auditoría del 27/09) |
| Árbol de trabajo | Limpio; rama `rediseno-ui` creada desde `main` |

## Capturas «antes»

Se generan sin dispositivo, con la tipografía real, en tres tamaños (375×812,
393×852 y 440×956) y en claro y oscuro:

- `test/golden/pantallas_test.dart`: acceso, inicio, temario, ranking y duelo
  (14 pantallas, 84 PNG). Ya existía.
- `test/golden/estudio_test.dart`: **nuevo**. Configurar práctica, pregunta
  con una alternativa elegida, explicación, resultado, progreso, simulacros,
  descargas, acceso terminado y mi suscripción (9 pantallas, 54 PNG).

Las imágenes «antes» son las del commit que cierra este paquete. Cualquier
captura posterior se compara contra él con `git show <commit>:<ruta>`.

## Rutas y datos

Unas 40 rutas en `lib/core/router/routes.dart`. Las guardas viven en un único
`_redirect` (`app_router.dart`). Cuatro pestañas en un `StatefulShellRoute`:
Inicio, Temario, Simulacros y Progreso. Los datos que el inicio ya tiene sin
pedir nada nuevo:

| Provider | De dónde sale | Lo que da |
|---|---|---|
| `sesionesAbiertasProvider` | `GET /sessions/open` | Sesiones a medias |
| `dashboardProvider` | `GET /stats/dashboard` | Acierto por área, racha, simulacros, nota proyectada |
| `prioridadEstudioProvider` | catálogo + dashboard | Áreas ordenadas por peso, brecha y temas |
| `nacionalProvider` | `GET /mock-exams` | Convocatoria nacional, si hay |
| `subscriptionProvider` | `GET /subscription` | Acceso y plan |
| `hayRedProvider` | `connectivity_plus` | Si hay red |

## Hallazgos que el rediseño debe resolver

1. **Cifra inventada en el inicio.** `_Delta(valor: 0.60)` pinta
   «+0.60 esta semana» junto a la nota proyectada. No sale de ningún dato: el
   dashboard no trae la variación semanal.
2. **Espera artificial de 1,8 s** en `StartupNotifier.minimoEnSplash`, aunque
   la sesión y las preferencias estén listas en ~200 ms.
3. **Inicio sin una acción dominante.** Racha, duelo, «Practicar» y
   «Simulacro», exámenes pasados, tres métricas, áreas, nota, accesos y
   nacional compiten con tamaños parecidos. El duelo, con degradado, pesa más
   que estudiar.
4. **Explicación bajo el pliegue.** Al responder, el enunciado sigue arriba y
   lo primero que se ve es otra vez el caso; el veredicto y el motivo quedan
   fuera de la pantalla en 393×852.
5. **«Reportar» no envía nada.** Muestra «Gracias. Un editor va a revisarla.»
   y no hay endpoint en el backend. La ayuda (`help_screen.dart:87`) lo
   promete también.
6. **Contraste insuficiente** en el texto terciario (`#9CA3AF` sobre blanco:
   2,5:1), en el borde de controles (`#C8C8C8`: 1,7:1) y en el texto blanco
   sobre el extremo claro del degradado de botón (`#2E9BD0`: 3,1:1).
7. **Sin interfaz de eventos.** No hay analítica, Crashlytics ni push. No se
   añaden sin aprobación (ver §Pendientes externos).

## Pendientes externos detectados

- **Titular legal.** El operador pasa a ser AidaSoft. Faltan la
  razón social exacta, el RUC y la dirección, así que **no se cambia texto**.
  Menciones a Jaks Tech que habrá que sustituir:
  - `lib/features/profile/presentation/legal_screen.dart:27` y `:77`
  - `lib/features/profile/presentation/help_screen.dart:401`
  - `lib/core/config/contacto.dart:24` (comentario)
  - `README.md:5`

  Los identificadores `pe.jakstech.enamApp` / `pe.jakstech.enam_app` y los
  `productId` de Apple **no se tocan**: se transfieren las apps, no se renombran.
- **Endpoint de reporte de preguntas** (backend): no existe.
- **Analítica, errores de cliente y push**: requieren cuenta y configuración de
  un proveedor. Decisión del negocio.
