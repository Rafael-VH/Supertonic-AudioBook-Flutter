# Generador del dashboard de diagramas

Escribe los archivos **generados** a partir de lo que haya en `docs/diagramas/`:

- `docs/index.html` — el dashboard que se publica en GitHub Pages.
- `docs/diagramas/manifest.json` — los datos del listado.
- `docs/diagramas/<slug>/index.html` — la página envolvente de cada diagrama: barra de
  navegación con el botón **← Volver a los diagramas** y el diagrama embebido debajo.

```bash
node tools/build-diagrams.mjs
```

No edites esos archivos a mano: se sobrescriben. Para cambiar el dashboard editá
`tools/dashboard.template.html`; para cambiar la barra del diagrama,
`tools/diagram.template.html`.

## Estructura

Un diagrama = una carpeta. La carpeta es lo que descubre el generador:

```
docs/diagramas/
└── <slug>/
    ├── <slug>.html      # el diagrama de Archify (obligatorio, no se modifica)
    ├── <slug>.json      # la especificación de Archify (obligatorio)
    ├── dashboard.json   # metadatos de la tarjeta (opcional)
    └── index.html       # GENERADO: barra con el botón de volver + diagrama embebido
```

Las tarjetas del dashboard enlazan a `index.html` (la envolvente), nunca directo al HTML de
Archify. Así el botón de volver siempre está presente y el artefacto de Archify queda intacto:
volver a correr `deliver` no rompe la navegación.

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
el conteo de nodos y relaciones.

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
