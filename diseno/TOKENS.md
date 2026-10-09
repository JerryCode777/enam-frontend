# Tokens de diseño de ENAM Prep — tabla fuente

Esta tabla es la **fuente única** del sistema visual compartido por la app
(Flutter, este repositorio) y la web (`enam-prep-web-react`). Los dos clientes
usan los mismos valores con los mismos nombres semánticos: el nombre dice qué
hace el color, nunca qué color es.

Para cambiar un valor hay que hacerlo en los tres sitios a la vez:

1. Esta tabla.
2. `lib/core/theme/design_tokens.dart` (y `motion.dart` si es movimiento).
   `test/tokens_test.dart` fija los valores y los contrastes, así que el cambio
   tiene que ser deliberado.
3. `src/index.css` de la web (variables `--enam-*`).

La galería interna muestra todo en vivo, en la misma ruta en los dos clientes:
`/dev/componentes`. Solo existe en desarrollo.

Acordado el 28/09/2026 entre las sesiones de la app y la web, a partir del
plan `PLAN-UI-SEO-PARA-OPUS.md` §3.

## Color — tema claro

| Semántico | CSS | Dart | Valor | Contraste medido |
|---|---|---|---|---|
| Fondo | `--enam-bg` | `backgroundLight` | `#F5F7FA` | — |
| Fondo hundido (pistas de barra) | `--enam-bg-secondary` | `backgroundSecondaryLight` · `scheme.surfaceContainer` | `#EAEFF5` | — |
| Superficie | `--enam-surface` | `surfaceLight` · `scheme.surface` | `#FFFFFF` | — |
| Superficie elevada | `--enam-surface-elevated` | `surfaceElevatedLight` | `#FAFBFD` | — |
| Borde de control | `--enam-border` | `borderLight` · `scheme.outline` | `#7A8BA0` | 3,48 sobre superficie · 3,25 sobre fondo |
| Borde sutil (separadores) | `--enam-border-subtle` | `borderSubtleLight` · `scheme.outlineVariant` | `#DCE4ED` | decorativo |
| Texto | `--enam-text` | `textPrimaryLight` · `scheme.onSurface` | `#102338` | 14,8 sobre fondo |
| Texto secundario | `--enam-text-secondary` | `textSecondaryLight` · `scheme.onSurfaceVariant` | `#526479` | 5,66 sobre fondo |
| Texto terciario | `--enam-text-tertiary` | `textTertiaryLight` | `#627286` | 4,58 sobre fondo |
| Acción (relleno del CTA) | `--enam-action` | `actionLight` · `scheme.primary` | `#176497` | 6,35 con su texto |
| Acción presionada | `--enam-action-pressed` | `actionPressedLight` | `#124F78` | — |
| Texto sobre acción | `--enam-on-action` | `onActionLight` · `scheme.onPrimary` | `#FFFFFF` | — |
| Texto de marca legible | `--enam-brand-text` | `actionLight` | `#176497` | 5,92 sobre fondo |
| Marca (decorativa) | `--color-brand` | `brand` | `#2E9BD0` | 3,13 sobre blanco: **nunca** texto pequeño |
| Info texto / tinte | `--enam-info-on-tint` / `--enam-info-tint` | `infoOnTintLight` / `infoTintLight` | `#176497` / `#E3F0FB` | 5,48 |
| Éxito texto / tinte | `--enam-success-on-tint` / `--enam-success-tint` | `successOnTintLight` / `successTintLight` | `#047857` / `#ECFDF5` | 5,21 |
| Error texto / tinte | `--enam-error-on-tint` / `--enam-error-tint` | `errorOnTintLight` / `errorTintLight` · `scheme.error` | `#B91C1C` / `#FEF2F2` | 5,91 |
| Aviso texto / tinte | `--enam-warning-on-tint` / `--enam-warning-tint` | `warningOnTintLight` / `warningTintLight` | `#B45309` / `#FFFBEB` | 4,84 |

Los colores base de estado (`success #10B981`, `error #EF4444`,
`warning #F59E0B`) son para iconos, bordes y rellenos, **no para texto**.

## Color — tema oscuro

La base sigue siendo azul marino, no gris ni negro.

| Semántico | CSS | Dart | Valor | Contraste medido |
|---|---|---|---|---|
| Fondo | `--enam-bg` | `backgroundDark` | `#182742` | — |
| Fondo hundido | `--enam-bg-secondary` | `backgroundSecondaryDark` | `#2B3D5C` | — |
| Superficie | `--enam-surface` | `surfaceDark` | `#22334F` | — |
| Superficie elevada | `--enam-surface-elevated` | `surfaceElevatedDark` | `#2B3D5C` | — |
| Borde de control | `--enam-border` | `borderDark` | `#6F8BBA` | 3,67 sobre superficie |
| Borde sutil | `--enam-border-subtle` | `borderSubtleDark` | `#374E75` | decorativo |
| Texto | `--enam-text` | `textPrimaryDark` | `#F3F4F6` | — |
| Texto secundario | `--enam-text-secondary` | `textSecondaryDark` | `#B8C2E0` | 7,15 sobre superficie |
| Texto terciario | `--enam-text-tertiary` | `textTertiaryDark` | `#A0AACB` | 5,5 sobre superficie |
| Acción | `--enam-action` | `actionDark` | `#6FC2E6` | 7,79 con su texto |
| Acción presionada | `--enam-action-pressed` | `actionPressedDark` | `#58B4DD` | — |
| Texto sobre acción | `--enam-on-action` | `onActionDark` | `#0A2540` | — |
| Texto de marca legible | `--enam-brand-text` | `brandLight` | `#6FC2E6` | — |
| Info texto / tinte | `--enam-info-on-tint` / `--enam-info-tint` | `infoOnTintDark` / `infoTintDark` | `#6FC2E6` / `#2A4570` | 4,82 |
| Éxito texto / tinte | — | `successOnTintDark` / `successTintDark` | `#34D399` / `#0B2E22` | ≥4,5 |
| Error texto / tinte | — | `errorOnTintDark` / `errorTintDark` | `#F87171` / `#3A1214` | ≥4,5 |
| Aviso texto / tinte | — | `warningOnTintDark` / `warningTintDark` | `#FBBF24` / `#33240A` | ≥4,5 |

## Degradados

Solo en la portada, en la marca y en momentos puntuales. Las pantallas de
estudio usan fondos estables. **El botón primario no lleva degradado** en
ninguna de las dos plataformas: en su extremo claro el texto blanco caía a
3,13:1.

| Uso | Dart | Paradas |
|---|---|---|
| Cabecera de marca | `headerGradientLight` / `Dark` | `#0A2540 → #16548C → #2E9BD0` / `#14213A → #1B3A66 → #2E76B4` |
| Superficie de marca con texto blanco (tarjeta de duelo) | `buttonGradient` | `#124F78 → #176497` (blanco ≥6,3 en todo el recorrido) |

## Tipografía

Nunito empaquetada en los dos clientes. Sus cifras ya son de ancho fijo (600
unidades cada una), así que el cronómetro, los precios y las estadísticas no
saltan de anchura sin necesidad de activar `tnum`.

| Rol | Tamaño / interlineado | Peso | Dart |
|---|---|---|---|
| Título de pantalla | 24–32 | 800 | `headlineLarge` (30), `headlineMedium` (24) |
| Subtítulo | 18 | 700 | `titleMedium` |
| Cuerpo | 16 / 1,5 | 400; 600 para énfasis | `bodyLarge` |
| Secundario | 14 / 1,5 | 400 | `bodyMedium` |
| Caso clínico | **17 / 1,6** | 400 | `AppTheme.clinicalCase`, `fontSizeClinical` |
| Mínimo | 12 | — | `fontSizeXs` |

## Forma y espacio

| Token | Valor | Uso |
|---|---|---|
| `radiusMd` | 12 | Controles: botones, campos, selectores |
| `radiusLg` | 16 | Tarjetas |
| `radiusXl` | 24 | Contenedores destacados (siguiente acción, hojas) |
| `radiusFull` | 999 | Píldoras de etiquetas cortas |
| Espaciado | 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 · 96 | `space1` … `space24` |
| Objetivo táctil | 48 | `minTouchTarget` |

## Movimiento

Con movimiento reducido todo se anula: el mismo contenido aparece directamente.

| Interacción | Duración | Dart |
|---|---|---|
| Selección de opción o botón | 140 ms | `Motion.fast` |
| Entrada de panel | 220 ms, desplazamiento ≤8 px | `Motion.normal`, `FadeUp.offset` |
| Navegación | 200 ms | `Motion.navigation` |
| Resultado o resumen | 350 ms | `Motion.slow` |
| Escalonado de bloques | 30 ms, 4 bloques como máximo | `Motion.stagger`, `Motion.maxStaggerIndex` |
| Carga | Pulso de opacidad 1 → 0,55 en 1,2 s | `Shimmer` |

Las cifras se leen correctas desde el primer fotograma (`AnimatedNumber` ya no
cuenta desde cero). Las barras sí crecen hasta su valor.

## Componentes

| Componente | Dart | Web |
|---|---|---|
| Botón primario / secundario / texto | `EnamButton`, `EnamOutlinedButton`, `TextButton` | `src/components/ui/` |
| Campo, selector | `EnamTextField`, `SegmentedButton` (tema) | ídem |
| Etiqueta de estado | `EtiquetaEstado` | ídem |
| Aviso contextual | `StateBanner` | ídem |
| Título de sección | `TituloSeccion` | ídem |
| Bloque de siguiente acción | `BloqueSiguienteAccion` | ídem |
| Resumen métrico (≤3 cifras) | `ResumenMetrico` | ídem |
| Fila de área | `FilaDeArea` | ídem |
| Opción de respuesta | `OptionCard` | ídem |
| Esqueleto | `SkeletonBox` | ídem |
| Estado vacío / error | `EstadoVacio`, `EstadoVacio.error` | ídem |

Los de la app viven en `lib/shared/widgets/estudio.dart`, salvo los que ya
tenían archivo propio.
