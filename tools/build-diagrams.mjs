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
const diagramTemplatePath = path.join(repoRoot, 'tools', 'diagram.template.html');

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

function escaparHtml(texto) {
  return String(texto)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

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
      nodos: Array.isArray(spec.components) ? spec.components.length : 0,
      relaciones: Array.isArray(spec.connections) ? spec.connections.length : 0,
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
 * Escribe docs/diagramas/<slug>/index.html: una página envolvente con la barra
 * de navegación (botón "Volver a los diagramas") y el diagrama embebido.
 *
 * El HTML que genera Archify queda intacto: nunca lo reescribimos, así que
 * volver a correr `deliver` no rompe nada.
 */
function escribirEnvoltorios(diagramas) {
  const plantilla = readFileSync(diagramTemplatePath, 'utf8');
  const marcadores = ['__TITULO__', '__TIPO__', '__DIAGRAMA__', '__ESPECIFICACION__'];

  for (const marcador of marcadores) {
    if (!plantilla.includes(marcador)) {
      console.error(`tools/diagram.template.html no contiene el marcador ${marcador}.`);
      process.exit(1);
    }
  }

  for (const diagrama of diagramas) {
    const html = plantilla
      .replaceAll('__TITULO__', escaparHtml(diagrama.titulo))
      .replaceAll('__TIPO__', escaparHtml(diagrama.tipoTexto))
      .replaceAll('__DIAGRAMA__', `${diagrama.slug}.html`)
      .replaceAll('__ESPECIFICACION__', `${diagrama.slug}.json`);

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

  escribirEnvoltorios(diagramas);

  const destacados = diagramas.filter((diagrama) => diagrama.destacado).length;
  console.log(
    `OK · ${diagramas.length} diagrama(s)${destacados ? ` · ${destacados} destacado(s)` : ''} ` +
      `→ docs/index.html, docs/diagramas/manifest.json y ${diagramas.length} página(s) envolvente(s)`,
  );
}

main();
