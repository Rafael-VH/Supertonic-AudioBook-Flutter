# Plan de mejora de interfaz

> **📜 DOCUMENTO HISTÓRICO (2026-08).** Este plan fue implementado y el código
> evolucionó después: las rutas que cita (`lib/presentation/screens/home_screen.dart`,
> `settings_screen.dart`, etc.) corresponden a la estructura **pre-refactor**. Hoy
> esas pantallas viven en `lib/features/<feature>/presentation/screens/` y el
> dashboard es un shell con NavigationBar. No usar como referencia del estado actual:
> ver `README.md` y `docs/es|en/` para la documentación vigente.

> Consolidado de dos revisiones (UI Designer + UX Architect) validadas contra los
> estándares mínimos de Flutter (`flutter-build-responsive-layout`, `flutter-fix-layout-issues`).
> Solo plan — sin código.

## 1. Inventario de widgets y espacio que ocupan

### HomeScreen — `lib/presentation/screens/home_screen.dart`

| Card | Contenido | Alto aprox. |
|---|---|---|
| **Carpeta de origen** | `titleMedium` + Row(ruta `bodySmall` ellipsis 2 líneas + `FilledButton.icon` Examinar) | ~120 px |
| **Salida de audio** | idéntica a la anterior | ~120 px |
| **Archivos encontrados** | Row(título + 3 `TextButton` Todo/Nada/Refrescar) + conteo + ayuda 2 líneas + lista fija 280 px (`CheckboxListTile` dense) | ~420 px |
| **Opciones de síntesis** | Wrap de `FilterChip` (formatos) + Row Voz (`DropdownButton` sin `isExpanded` + texto suelto) + 2 sliders (pasos 5–12, velocidad 0.7–2.0) + Row idioma (`DropdownButton` con `isExpanded` + ellipsis) + `FilledButton.icon` Escuchar | ~380 px |
| **Registro** | contenedor fijo 200 px (log monospace) + estado + `BarraProgreso` + Row(Procesar `FilledButton` | Cancelar `OutlinedButton`) | ~350 px |

`AppBar`: título + `IconButton` ajustes (48 px). Cuerpo: `SingleChildScrollView`+`Row` 50/50 (≥900 px) o `ListView` apilado (<900 px).

### SettingsScreen — `lib/presentation/screens/settings_screen.dart`

`ListView` con 4 `_SeccionCard` (padding 16, título bold): Tema (`SegmentedButton` 2 opciones), Estilo (`SegmentedButton` 3 opciones), Idioma (`SegmentedButton` 2), Acerca de (`AcercaDeSection`).

### ModeloScreen — `lib/presentation/screens/modelo_screen.dart`

`Center` > `ConstrainedBox(480)` > `Padding(24)` > `Column(min)`: ícono 56 px, título `headlineSmall`, aviso, y por estado: spinner / `LinearProgressIndicator` + MB + archivo + Cancelar / error + Descargar.

### Widgets compartidos

- `ArchivoTile` (`lib/presentation/widgets/archivo_tile.dart`): `CheckboxListTile` **`dense: true`**, `controlAffinity: leading`, título ellipsis 1 línea, sin subtitle.
- `BarraProgreso` (`barra_progreso.dart`): `LinearProgressIndicator` + % en `SizedBox(width: 40)`.
- `AcercaDeSection` (`acerca_de_section.dart`): enlaces con `minimumSize(0, 32)` + `shrinkWrap` (violan el target de 48 px).

## 2. Problemas de distribución (priorizados)

### P0 — Acción principal enterrada (móvil)
En <900 px el usuario llega a "Procesar" tras ~1500 px de scroll. El progreso queda bajo el pliegue: no se ve mientras se trabaja. **Fix: barra de acción persistente.**

### P0 — Scroll anidado y alturas fijas
Lista fija 280 px + registro fijo 200 px dentro de un scroll general. En tablet, si hay 2 archivos queda aire muerto; con muchos, doble scroll confuso.

### P1 — Selector de salida duplicado en percepción
`salida_audio` vive en la card de entrada junto a `carpeta_origen`: es prerrequisito de la síntesis, no de la entrada. Confunde el flujo.

### P1 — Jerarquía de botones plana
4 `FilledButton` con el mismo peso (2× Examinar, Escuchar, Procesar). M3 pide un solo botón lleno destacado. Escuchar (prueba) debería ser tonal.

### P1 — Sin tope de ancho en tablet
Por encima de ~1200 px las cards se estiran a todo el ancho; el patrón `ConstrainedBox(480)` de ModeloScreen no se reutiliza.

### P2 — Riesgos de overflow reales en 375 px
- Fila "Voz": `DropdownButton` sin `isExpanded` + `Text(modelo_supertonic)` suelto en Row.
- Header de archivos: título + 3 `TextButton` apretados.
- Settings: `SegmentedButton` de Estilo con "Skeuomorfismo" no wrappea.

### P2 — Touch targets < 48 px
- `ArchivoTile` `dense: true` (~40 px).
- 3 `TextButton` Todo/Nada/Refrescar.
- Enlaces de Acerca de: `minimumSize(0,32)` + `shrinkWrap`.

### P2 — Estados pobres y detalles
- Lista vacía = solo texto centrado, sin ícono ni CTA.
- Sin estados loading/error en la lista.
- `BarraProgreso` siempre visible con total=0 (ruido).
- Sin % numérico en descarga del modelo.
- Contraste: `texto_secundario` (#79747E) da ~3.5:1 sobre `superficieVariante` en claro — falla AA para log/rutas/etiquetas pequeñas.

## 3. Distribución objetivo por pantalla

### Breakpoints (2 tiers, la app es móvil-only: Android + iOS)

| Tamaño | Umbral | Estructura |
|---|---|---|
| Móvil | <700 | columna única + **barra inferior persistente** |
| Tablet | ≥700 | carpetas en 2 columnas; 2 paneles con scroll independiente (archivos 3fr \| opciones+log 2fr) |

> Nota: el código actual usa `umbralAncho = 900` (paneles lado a lado por
> encima; apilados por debajo). El tier de tablet queda como evolución opcional.

### HomeScreen

1. **Barra inferior persistente (móvil)**: `SafeArea` + borde superior: `BarraProgreso` compacta (visible solo si `total > 0`) + `FilledButton` "Procesar" expandido; "Cancelar" (`OutlinedButton`) solo durante ejecución. Progreso SIEMPRE visible.
2. **Mover salida a síntesis**: la card "Salida de audio" pasa a Opciones de síntesis (debajo de formatos), como `ListTile` + `FilledButton.tonal` "Examinar". Entrada queda solo con origen.
3. **Lista de archivos sin altura fija**: móvil → la card ocupa el espacio libre (`Expanded`); tablet → `ListView.builder` llena el alto del panel. Sacar `dense: true`.
4. **Jerarquía de acciones**: Procesar = único `FilledButton` (ícono `play_arrow`); Escuchar = `FilledButton.tonal`; Examinar ×2 = `OutlinedButton.icon`.
5. **Opciones en `ExpansionTile` (móvil)** "Opciones de síntesis" colapsado por defecto → la lista es protagonista.
6. **Registro en `ExpansionTile`** "Registro" colapsado; se auto-expande al ejecutar o en error. En tablet con altura adaptativa (~260 máx).
7. **Estados ricos de lista**: vacío → ícono `folder_off` + texto + CTA "Examinar"; loading → `LinearProgressIndicator` en cabecera; error → texto color error + reintentar.
8. **Voz sin overflow**: `DropdownButton(isExpanded: true)` + "modelo_supertonic" como `helperText`; labels `labelMedium` arriba de cada control.
9. **Rutas**: `Tooltip` con ruta completa en ambos selectores y en cada tile; `ArchivoTile` con `subtitle` (directorio padre) + `secondary` icono.
10. **Conteo**: `Badge` en el header "Archivos encontrados".

### SettingsScreen

1. `Center` + `ConstrainedBox(maxWidth: 640)` sobre el `ListView` (espejo de ModeloScreen).
2. Tema → `SwitchListTile` "Modo oscuro" (acción binaria, target grande).
3. Estilo → 3 `RadioListTile` con `leading` + subtitle descriptivo (lee bien en móvil angosto).
4. Idioma → mantener `SegmentedButton` (2 opciones, entra sin problema).
5. Acerca de → enlaces como `ListTile` (leading `open_in_new`, alto 48+, `Divider`); en tablet opción `AboutDialog`.
6. Cards con subtítulo `bodySmall` de ayuda; separar "Acerca de" con `Divider`.

### ModeloScreen

1. `SingleChildScrollView` + `Center` + `ConstrainedBox(480)` (scroll solo de emergencia).
2. Ícono 56 px en contenedor circular (`primaryContainer`).
3. Botones Descargar/Cancelar con `ConstrainedBox(maxWidth: 280)` centrado (no stretch).
4. % numérico junto al `LinearProgressIndicator` + "archivo X de Y".
5. Error con ícono `error_outline` + `FilledButton` "Reintentar".

## 4. Checklist de estándares mínimos de Flutter (skills aplicadas)

De `flutter-build-responsive-layout`:

- [x] Decidir layout por **espacio disponible** (`LayoutBuilder`/`MediaQuery.sizeOf`), no por tipo de hardware ni orientación. — Usar `LayoutBuilder` sobre `constraints.maxWidth`, no `MediaQuery` global.
- [x] `Expanded`/`Flexible` para distribuir espacio; `ListView.builder`/`GridView.builder` para listas grandes. — Ya se usan; falta `isExpanded` en DropdownButton de Voz.
- [x] `ConstrainedBox` + `Center` para evitar estiramiento en pantallas grandes. — Falta en Home y Settings.
- [x] Escalado de texto respetado (no fijar tamaños de fuente): los textos usan `textTheme` — mantener; quitar el `fontSize` hardcodeado si aparece.
- [x] No bloquear orientación; soportar teclado/mouse (touch targets ≥48, atajos opcionales).
- [x] Breakpoints estándar 600/1024 como referencia — el plan propone 700/1100 (tiers propios de la app) con justificación de contenido.

De `flutter-fix-layout-issues`:

- [x] Riesgo de "RenderFlex overflowed" en la Row de Voz (375 px) → `DropdownButton(isExpanded: true)` + `helperText`.
- [x] Riesgo en header de Archivos (3 TextButton) → migrar a `IconButton` con tooltip (48 px).
- [x] Lista/registro dentro de scroll: contener con `Expanded`/`ConstrainedBox` (ya hay `SizedBox` fijos; reemplazar).
- [x] Probar en 360×640, 375×667, 768×1024 y fullscreen tablet.

Reglas generales:

- [x] Touch targets ≥48×48 dp en todo control (ArchivoTile, TextButton, enlaces Acerca de).
- [x] Componentes estándar (Card, ListTile, ExpansionTile, FilledButton) antes que custom.
- [x] `const` constructors donde aplique.
- [x] Tokens centralizados: espaciado (4/8/12/16/24) y padding de card (12 móvil / 16 tablet) en el tema, no `SizedBox` sueltos.
- [x] Contraste AA en tema claro (subir tono de `texto_secundario`).
- [x] `Semantics`/tooltips en iconos de acción; log con `SelectableText` (ya está).

## 5. Orden de implementación sugerido

1. **Barra inferior persistente + sacar alturas fijas** (móvil: acción y progreso siempre visibles; elimina scroll anidado). Mayor impacto en comodidad.
2. **Mover salida a síntesis + jerarquía de botones** (un solo `FilledButton` = Procesar; tonal/outlined el resto).
3. **Lista con estados vacío/loading/error y scroll propio** en tablet; `ArchivoTile` sin `dense`, con `subtitle` y `Tooltip`.
4. **Settings**: `ConstrainedBox(640)` + Switch/Radio + enlaces 48 px.
5. **Contraste** del texto secundario en tema claro.
6. **Modelo**: scroll safety + % + `ConstrainedBox(280)` en botones.
7. Validación final en los 4 viewports + resize en tablet + `flutter test`.
