#!/usr/bin/env node
/**
 * Genera docs/index.html y docs/diagramas/manifest.json a partir de los diagramas
 * presentes en docs/diagramas/.
 *
 * Uso:  node tools/build-diagrams.mjs
 *
 * Los dos archivos de salida son generados: no editarlos a mano. Para cambiar la
 * apariencia del dashboard, editá tools/dashboard.template.html.
 *
 * Ver docs/diagramas/README.md para el flujo completo.
 */

import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docsDir = path.join(repoRoot, 'docs');
const diagramasDir = path.join(docsDir, 'diagramas');
const manifestPath = path.join(diagramasDir, 'manifest.json');
const templatePath = path.join(repoRoot, 'tools', 'dashboard.template.html');
const indexPath = path.join(docsDir, 'index.html');

const TIPOS = new Set(['architecture', 'workflow', 'sequence', 'dataflow', 'lifecycle']);

const ETIQUETA_TIPO = {
  architecture: 'Arquitectura',
  workflow: 'Proceso',
  sequence: 'Secuencia',
  dataflow: 'Flujo de datos',
  lifecycle: 'Ciclo de vida',
};

function textoTipo(tipo) {
  return ETIQUETA_TIPO[tipo] || tipo;
}

/**
 * Cada tipo de diagrama nombra distinto sus colecciones: la tarjeta tiene que contar
 * las que existen y rotularlas con el sustantivo del tipo (p. ej. "estados" y
 * "transiciones"), no siempre "nodos" y "relaciones".
 */
const CONTEO = {
  architecture: {
    nodos: 'components',
    relaciones: 'connections',
    etiquetaNodos: 'nodos',
    etiquetaRelaciones: 'relaciones',
  },
  workflow: {
    nodos: 'nodes',
    relaciones: 'edges',
    etiquetaNodos: 'nodos',
    etiquetaRelaciones: 'conexiones',
  },
  sequence: {
    nodos: 'participants',
    relaciones: 'messages',
    etiquetaNodos: 'participantes',
    etiquetaRelaciones: 'mensajes',
  },
  dataflow: {
    nodos: 'nodes',
    relaciones: 'flows',
    etiquetaNodos: 'nodos',
    etiquetaRelaciones: 'flujos',
  },
  lifecycle: {
    nodos: 'states',
    relaciones: 'transitions',
    etiquetaNodos: 'estados',
    etiquetaRelaciones: 'transiciones',
  },
};

function contarElementos(spec, tipo) {
  const conteo = CONTEO[tipo] || CONTEO.architecture;
  const cuenta = (clave) => (Array.isArray(spec[clave]) ? spec[clave].length : 0);
  return {
    nodos: cuenta(conteo.nodos),
    relaciones: cuenta(conteo.relaciones),
    etiquetaNodos: conteo.etiquetaNodos,
    etiquetaRelaciones: conteo.etiquetaRelaciones,
  };
}

function escaparHtml(texto) {
  return String(texto)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Botón de retorno al dashboard, inyectado dentro del propio visor.
 *
 * Es solo la flecha, sin texto visible: así cuadra con los controles del toolbar.
 * El nombre accesible vive en `aria-label`/`title`, que el visor no dibuja.
 *
 * Usa los tokens de chrome del visor (--toolbar-*) en lugar de colores fijos: así
 * hereda el tema claro/oscuro y los presets (classic, signal-flow, blueprint,
 * editorial) sin duplicar la paleta. El estilo replica `.toolbar button`.
 */
const RETORNO_ESTILO = `  <style id="archify-back-style">
    /* Réplica exacta de \`.toolbar button\`: así el botón pertenece al chrome del
       visor y sigue su tema y su preset sin duplicar la paleta. */
    .archify-back {
      flex: 0 0 auto;
      display: inline-flex;
      align-items: center;
      gap: .375rem;
      min-height: 2.75rem;
      padding: .5rem .875rem;
      border-radius: .625rem;
      border: 1px solid var(--toolbar-border);
      background: var(--toolbar-bg);
      color: var(--toolbar-text);
      backdrop-filter: blur(10px);
      box-shadow: 0 4px 14px rgba(0, 0, 0, .08);
      transition: background .15s, border-color .15s, color .15s;
      font-family: inherit;
      font-size: .75rem;
      font-weight: 500;
      line-height: 1;
      text-decoration: none;
      white-space: nowrap;
      cursor: pointer;
    }
    .archify-back:hover {
      background: var(--toolbar-hover);
      border-color: color-mix(in srgb, var(--arrow) 62%, var(--toolbar-border));
    }
    .archify-back:focus-visible { outline: 2px solid var(--arrow-emphasis); outline-offset: 2px; }
    .archify-back svg { width: .95rem; height: .95rem; flex: 0 0 auto; }
    html[data-present="true"] .archify-back { display: none; }

    /* El preset editorial redondea menos los controles del visor. */
    html[data-preset="editorial"] .archify-back { border-radius: .3rem; }

    /* Diagramas sin .header-row: el botón flota arriba a la izquierda. */
    .archify-back--flotante { position: fixed; top: 1rem; left: 1rem; z-index: 60; }
  </style>
`;

const BOTON_RETORNO =
  '<a class="archify-back no-print" lang="es" href="../../index.html" aria-label="Atrás" ' +
  'title="Volver a los diagramas">' +
  '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path fill="none" stroke="currentColor" ' +
  'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M19 12H5m0 0 6-6m-6 6 6 6"/></svg>' +
  '</a>';

const BOTON_RETORNO_FLOTANTE = BOTON_RETORNO.replace(
  'class="archify-back ',
  'class="archify-back archify-back--flotante ',
);

function aPosix(ruta) {
  return ruta.split(path.sep).join('/');
}

function leerJson(ruta, errores) {
  try {
    return JSON.parse(readFileSync(ruta, 'utf8'));
  } catch (error) {
    errores.push(`${aPosix(path.relative(repoRoot, ruta))}: JSON inválido (${error.message})`);
    return null;
  }
}

function normalizarEtiquetas(valor) {
  if (!Array.isArray(valor)) return [];
  const limpias = valor
    .filter((etiqueta) => typeof etiqueta === 'string')
    .map((etiqueta) => etiqueta.trim())
    .filter(Boolean);
  return [...new Set(limpias)];
}

function fechaDeActualizacion(relPath, absPath) {
  try {
    const salida = execFileSync('git', ['log', '-1', '--date=short', '--format=%cd', '--', relPath], {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    if (salida) return salida;
  } catch {
    // Sin git disponible: caemos al mtime del archivo.
  }
  return statSync(absPath).mtime.toISOString().slice(0, 10);
}

function recolectar() {
  const errores = [];

  if (!existsSync(diagramasDir)) {
    return { diagramas: [], errores: ['no existe docs/diagramas/'] };
  }

  const slugs = readdirSync(diagramasDir, { withFileTypes: true })
    .filter((entrada) => entrada.isDirectory() && !entrada.name.startsWith('.') && !entrada.name.startsWith('_'))
    .map((entrada) => entrada.name)
    .sort();

  const diagramas = [];

  for (const slug of slugs) {
    const dir = path.join(diagramasDir, slug);
    const htmlAbs = path.join(dir, `${slug}.html`);
    const specAbs = path.join(dir, `${slug}.json`);

    if (!existsSync(htmlAbs)) {
      errores.push(`docs/diagramas/${slug}/: falta ${slug}.html`);
      continue;
    }
    if (!existsSync(specAbs)) {
      errores.push(`docs/diagramas/${slug}/: falta ${slug}.json`);
      continue;
    }

    const spec = leerJson(specAbs, errores);
    if (!spec) continue;

    const tipo = typeof spec.diagram_type === 'string' ? spec.diagram_type : 'architecture';
    if (!TIPOS.has(tipo)) {
      errores.push(`docs/diagramas/${slug}/${slug}.json: diagram_type desconocido "${tipo}"`);
    }

    const extraAbs = path.join(dir, 'dashboard.json');
    const extra = existsSync(extraAbs) ? leerJson(extraAbs, errores) ?? {} : {};

    const htmlRel = aPosix(path.relative(repoRoot, htmlAbs));

    diagramas.push({
      slug,
      titulo: typeof spec.meta?.title === 'string' && spec.meta.title ? spec.meta.title : slug,
      tipo,
      tipoTexto: textoTipo(tipo),
      descripcion: typeof extra.descripcion === 'string' ? extra.descripcion : '',
      etiquetas: normalizarEtiquetas(extra.etiquetas),
      destacado: extra.destacado === true,
      ...contarElementos(spec, tipo),
      capitulos: Array.isArray(spec.meta?.views) ? spec.meta.views.length : 0,
      actualizado: fechaDeActualizacion(htmlRel, htmlAbs),
      // Todos los enlaces apuntan a la página envolvente, que aporta la barra con
      // el botón de volver al dashboard. El HTML de Archify nunca se modifica.
      archivo: aPosix(path.join(path.relative(docsDir, dir), 'index.html')),
      especificacion: aPosix(path.relative(docsDir, specAbs)),
    });
  }

  diagramas.sort((a, b) => {
    if (a.destacado !== b.destacado) return a.destacado ? -1 : 1;
    if (a.actualizado !== b.actualizado) return a.actualizado < b.actualizado ? 1 : -1;
    return a.titulo.localeCompare(b.titulo, 'es');
  });

  return { diagramas, errores };
}

/**
 * Escribe docs/diagramas/<slug>/index.html: el diagrama con el botón de retorno
 * inyectado dentro de su propio header.
 *
 * El artefacto <slug>.html que produjo `deliver` nunca se modifica: siempre se lee
 * para producir la copia publicada, así que volver a correr `deliver` no rompe nada.
 */
function escribirPaginas(diagramas) {
  for (const diagrama of diagramas) {
    const origen = path.join(diagramasDir, diagrama.slug, `${diagrama.slug}.html`);
    let html = readFileSync(origen, 'utf8');

    if (!html.includes('archify-back')) {
      if (!html.includes('</head>')) {
        console.error(`docs/diagramas/${diagrama.slug}/${diagrama.slug}.html no tiene </head>.`);
        process.exit(1);
      }
      html = html.replace('</head>', `${RETORNO_ESTILO}</head>`);

      const anclaHeader = /<div class="header-row"[^>]*>/.exec(html);
      const anclaBody = anclaHeader ? null : /<body[^>]*>/.exec(html);

      if (!anclaHeader && !anclaBody) {
        console.error(`docs/diagramas/${diagrama.slug}/${diagrama.slug}.html no tiene header ni body.`);
        process.exit(1);
      }

      const ancla = anclaHeader || anclaBody;
      const boton = anclaHeader ? BOTON_RETORNO : BOTON_RETORNO_FLOTANTE;
      const corte = ancla.index + ancla[0].length;
      html = html.slice(0, corte) + boton + html.slice(corte);
    }

    writeFileSync(path.join(diagramasDir, diagrama.slug, 'index.html'), html, 'utf8');
  }
}

function main() {
  const { diagramas, errores } = recolectar();

  if (errores.length > 0) {
    console.error('No se pudo generar el dashboard:');
    for (const error of errores) console.error(`  - ${error}`);
    process.exit(1);
  }

  if (diagramas.length === 0) {
    console.error('No hay diagramas en docs/diagramas/.');
    process.exit(1);
  }

  const manifest = {
    generado_por: 'tools/build-diagrams.mjs',
    total: diagramas.length,
    diagramas,
  };
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');

  const plantilla = readFileSync(templatePath, 'utf8');
  const marcador = '__DIAGRAMAS__';
  if (!plantilla.includes(marcador)) {
    console.error(`La plantilla ${aPosix(path.relative(repoRoot, templatePath))} no contiene ${marcador}.`);
    process.exit(1);
  }

  const datos = JSON.stringify({ total: diagramas.length, diagramas }).replace(/</g, '\\u003c');
  writeFileSync(indexPath, plantilla.replace(marcador, datos), 'utf8');

  escribirPaginas(diagramas);

  const destacados = diagramas.filter((diagrama) => diagrama.destacado).length;
  console.log(
    `OK · ${diagramas.length} diagrama(s)${destacados ? ` · ${destacados} destacado(s)` : ''} ` +
      `→ docs/index.html, docs/diagramas/manifest.json y ${diagramas.length} página(s) con botón de retorno`,
  );
}

main();
