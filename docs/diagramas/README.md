# Generador del dashboard de diagramas

Escribe los archivos **generados** a partir de lo que haya en `docs/diagramas/`:

- `docs/index.html` — el dashboard que se publica en GitHub Pages.
- `docs/diagramas/manifest.json` — los datos del listado.
- `docs/diagramas/<slug>/index.html` — el diagrama con el botón de volver inyectado dentro de
  su propio header. El botón es solo la flecha, sin texto visible; el nombre accesible vive en
  `aria-label`/`title`. Al usar los tokens del visor (`--toolbar-*`), hereda el tema
  claro/oscuro y los cuatro presets sin duplicar la paleta.

```bash
node tools/build-diagrams.mjs
```

No edites esos archivos a mano: se sobrescriben. Para cambiar el dashboard editá
`tools/dashboard.template.html`; para cambiar el botón, `RETORNO_ESTILO` y `BOTON_RETORNO`
en `tools/build-diagrams.mjs`.

## Estructura

Un diagrama = una carpeta. La carpeta es lo que descubre el generador:

```
docs/diagramas/
└── <slug>/
    ├── <slug>.html      # el diagrama de Archify (obligatorio, no se modifica)
    ├── <slug>.json      # la especificación de Archify (obligatorio)
    ├── dashboard.json   # metadatos de la tarjeta (opcional)
    └── index.html       # GENERADO: el diagrama + el botón de volver
```

Las tarjetas del dashboard enlazan a `index.html`, nunca directo al HTML de Archify. El
artefacto de Archify queda intacto: volver a correr `deliver` no rompe la navegación, porque
el generador vuelve a inyectar el botón sobre la versión nueva.

Si falta `<slug>.html` o `<slug>.json`, el script falla con código de salida 1 y no escribe
nada. Es a propósito: un diagrama mal subido debe romper el build, no desaparecer en silencio.

## `dashboard.json` (opcional)

```json
{
  "descripcion": "Qué muestra el diagrama, en una frase.",
  "etiquetas": ["arquitectura", "capas"],
  "destacado": true
}
```

Sin este archivo, la tarjeta usa el título y el tipo que ya vienen en la especificación, más
el conteo de elementos de ese tipo y su sustantivo: nodos y relaciones, estados y transiciones,
participantes y mensajes, o flujos según el diagrama.

## Agregar un diagrama

```bash
# 1. Generar el diagrama dentro de su carpeta
node <ruta-a-archify>/bin/archify.mjs deliver architecture spec.json \
  docs/diagramas/<slug>/<slug>.html --quality showcase

# 2. Copiar la especificación junto al HTML
cp spec.json docs/diagramas/<slug>/<slug>.json

# 3. (Opcional) describirlo
#    crear docs/diagramas/<slug>/dashboard.json

# 4. Regenerar el dashboard
node tools/build-diagrams.mjs

# 5. Commit y push: GitHub Pages se reconstruye solo
```

El orden del listado es: destacados primero, luego por fecha de actualización descendente y
por último por título.
