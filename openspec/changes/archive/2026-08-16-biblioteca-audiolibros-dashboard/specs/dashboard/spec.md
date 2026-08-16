# Dashboard Specification

## Purpose

Hub principal tras el onboarding: hero de bienvenida, cards de función consistentes con `cardTheme` + `PaletaExt`, acceso activo a la Biblioteca y Card de estado del modelo con CTA de descarga. Cierra los hallazgos W-1..W-5 de la auditoría.

## Requirements

### Requirement: Botón de Biblioteca activo (DASH-1) — Prioridad: must — Vínculo: W-5

El dashboard MUST reemplazar el placeholder "Próximamente" por una card "Biblioteca" que navega a `Rutas.biblioteca` (sin `onTap: null`).

#### Scenario: Acceso a la biblioteca

- GIVEN el dashboard
- WHEN se toca la card Biblioteca
- THEN se navega a `/biblioteca`

### Requirement: Claves l10n descriptivas (DASH-2) — Prioridad: must — Vínculo: W-5

Las claves del dashboard MUST ser descriptivas (`dashboard_biblioteca`, `dashboard_procesar_sueltos`, `dashboard_modelo_*`). MUST NOT existir `dashboard_opcion2/3` ni claves con espacio embebido como `"Modelos: "` (el prefijo se compone en el widget).

#### Scenario: Sin claves genéricas

- GIVEN `app_es.arb` y `app_en.arb`
- WHEN se inspeccionan las claves del dashboard
- THEN no existen `dashboard_opcion2/3` ni valores con espacio embebido

### Requirement: Cards con el tema global (DASH-3) — Prioridad: must — Vínculo: W-2

Las cards del dashboard MUST heredar color, shape y elevación del `cardTheme` global; los acentos y biseles MUST usar `PaletaExt`. Ninguna card MUST hardcodear `color` o `shape` propios.

#### Scenario: Herencia del cardTheme

- GIVEN un `cardTheme` con radio 12 y borde de la paleta
- WHEN se construye el dashboard
- THEN las cards usan el shape y color del tema, sin override local

#### Scenario: Biseles por PaletaExt en ambos estilos

- GIVEN temas claro/oscuro con estilos neumo y skeuo
- WHEN se alternan las combinaciones
- THEN las cards conservan contraste y biseles de `PaletaExt`

### Requirement: Redirect del gate devuelve al origen (DASH-4) — Prioridad: must — Vínculo: W-1

Cuando el modelo queda listo en `/modelo`, el redirect MUST devolver a la ruta de origen conocida en `state.extra` (dashboard, home o seleccion); sin origen conocido, MUST volver a `/home`.

#### Scenario: CTA de descarga desde el dashboard

- GIVEN el usuario en `/dashboard` toca el CTA de descarga con origen `/dashboard`
- WHEN el modelo termina de descargarse
- THEN el redirect devuelve a `/dashboard`

#### Scenario: Sin origen conocido

- GIVEN se llega a `/modelo` por el gate normal, sin `state.extra`
- WHEN el modelo queda listo
- THEN el redirect vuelve a `/home` (sin regresión del gate)

### Requirement: Estado del modelo veraz (DASH-5) — Prioridad: must — Vínculo: W-4

La Card de estado del modelo MUST reflejar `ModeloEstado`: `descargando:true` MUST mostrar progreso de descarga (nunca "sin descargar"); `verificando` → "verificando…"; `listo` → "descargado"; `error` → mensaje de error.

#### Scenario: Descarga en curso

- GIVEN `ModeloEstado.descargando = true` con bytes/total
- WHEN se renderiza la Card de estado
- THEN se muestra el progreso de descarga
- AND el texto "sin descargar" no aparece

#### Scenario: Error de descarga

- GIVEN `ModeloEstado.error != null` tras una descarga fallida
- WHEN se renderiza la Card
- THEN se muestra el error
- AND el CTA de descarga vuelve a estar disponible

### Requirement: CTA de descarga y refresh accesibles (DASH-6) — Prioridad: must — Vínculo: W-4

Sin modelo listo ni descarga en curso, la Card MUST mostrar un CTA que navega a `/modelo` (con origen). El botón de refresh MUST tener hit target ≥48dp (hoy 24dp).

#### Scenario: CTA de descarga visible

- GIVEN modelo no descargado y no descargando
- WHEN se observa la Card
- THEN hay un CTA que navega a `/modelo`
- AND el refresh mide ≥48×48dp

#### Scenario: CTA durante descarga

- GIVEN `descargando = true`
- WHEN se observa la Card
- THEN el CTA queda reemplazado por el progreso (sin doble descarga)

### Requirement: Rebuilds aislados del estado del modelo (DASH-7) — Prioridad: must — Vínculo: W-3

El estado del modelo MUST observarse solo en la Card de estado (`select()` o watch local). Los ticks de descarga/verificación MUST NOT reconstruir el hero ni las cards de función.

#### Scenario: Ticks de progreso no re-renderizan las cards

- GIVEN el dashboard con una descarga emitiendo progreso
- WHEN `bytes/total` se actualizan repetidamente
- THEN el hero y las cards de función no se reconstruyen (test de widget con contador de builds)

### Requirement: Hero de bienvenida (DASH-8) — Prioridad: must

El dashboard MUST mostrar un hero de bienvenida destacado en el tope (título + subtítulo), antes de las cards.

#### Scenario: Hero visible

- GIVEN el dashboard
- WHEN se renderiza
- THEN el hero con la bienvenida aparece antes de las cards

### Requirement: Diseño responsive (DASH-9) — Prioridad: must

El contenido MUST apilarse en una columna en móvil (ancho < 600dp) y MOSTRAR un grid de 2 columnas desde 600dp.

#### Scenario: Móvil en columna

- GIVEN ancho 400dp
- WHEN se renderiza el dashboard
- THEN las cards se apilan en una columna

#### Scenario: Pantalla ancha en grid

- GIVEN ancho 800dp
- WHEN se renderiza el dashboard
- THEN las cards se distribuyen en 2 columnas

### Requirement: Accesibilidad (DASH-10) — Prioridad: should

Todos los controles táctiles del dashboard MUST tener hit target ≥48dp y los iconos con acción MUST exponer semantics (tooltip o etiqueta).

#### Scenario: Semantics en iconos

- GIVEN el botón refresh y el acceso a settings
- WHEN se inspecciona el árbol de semantics
- THEN ambos tienen etiqueta accesible
- AND sus hit targets miden ≥48dp
