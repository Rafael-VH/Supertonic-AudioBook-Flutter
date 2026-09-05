# Funcionalidades Recomendadas — Supertonic-AudioBook-Flutter

> Documento de referencia. Generado el 2026-08-18. Estado actualizado el **2026-09-05**.
> El foco de la app es **generar audio desde archivos Markdown**, no reproducir. La reproducción es solo para previsualizar.
>
> Este documento lista (1) lo ya implementado, (2) las funcionalidades recomendadas
> pendientes y (3) nuevas ideas de producto. El estado refleja el código real al
> 2026-09-05 (verificado contra `lib/`, `docs/` y `openspec/specs/`).

---

## ✅ Ya implementado

| Funcionalidad | Dónde | Evidencia |
|---------------|-------|-----------|
| **Previsualización de voz** (botón *Escuchar*) | Convert | `SintetizarMuestra` + `VoicePreviewService` + textos por idioma en `muestra_voz.dart` |
| **Estimación en vivo durante la conversión** | Convert | Spec promovida `estimacion-viva-conversion` (EVC-1..4): `· ~` por archivo y `restante_estimado` del lote, visibles en barra móvil, registro y panel tablet |
| **Advertencia de memoria** | Convert | Estima el lote antes de procesar; avisa si supera el 70 % de RAM (`_requiereAdvertenciaMemoria` + `memory_warning_dialog`) |
| **Gestión de audios pendientes** (Audio Manager) | `/audio-manager` | Renombrar, elegir carpeta, guardar (rename atómico con sufijo `(N)`) o descartar WAVs temporales |
| **Biblioteca con play/pausa** | Tab del dashboard | Spec promovida `biblioteca-audiolibros`; agrupa por libro con prioridad de formato |
| **Editor de metadatos ID3** | `/editor-metadata` | Título, artista, álbum, año, género, pista, disco, comentario y carátula |
| **Benchmark del motor + tarjeta de hardware** | `/benchmark` | Tabla de 6 tamaños, historial de conversiones y `DeviceSpec` (marca/modelo/CPU/RAM) — specs `benchmark-motor`, `deteccion-hardware` |
| **Descarga del modelo resumible + SHA-256** | `/modelo` | Dio con `Range`/append sobre `.part`, verificación en Isolate, cancelación conserva `.part` |
| **Historial de conversiones** | Preferencias | Persiste a `historial_conversiones.json` (cap 100 entradas); spec `conversion-history` |
| **Onboarding de primera ejecución** | `/onboarding` | 5 pasos, saltable, decide Splash → Onboarding vs Dashboard |
| **Dashboard shell** | `/dashboard` | `NavigationBar` + `IndexedStack` (Home hub, Biblioteca, Settings); spec `dashboard` |
| **i18n ES/EN + 31 idiomas TTS + auto** | Settings / Convert | UI en ES/EN (`gen-l10n`); voces en 31 idiomas con `availableLangs` + `na` (auto) |
| **Responsive móvil/tablet** | Convert | Breakpoint 900 px: acordeón + barra inferior (móvil) vs paneles lado a lado (tablet) |
| **Pre-procesamiento de texto** (parcial) | Convert | `limpiarMarkdown` (headings, links, código, listas…) + `text_preprocessor` (NFKD, emojis, símbolos, `<lang>`). Ver #6 abajo |

---

## 🥇 Directamente ligadas al flujo de generación

### 1. Previsualización antes de generar completo ✅ IMPLEMENTADA
- Generar solo el primer párrafo o los primeros 30 segundos
- Permitir al usuario elegir voz, velocidad y pasos antes de procesar todo el libro
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — reduce regeneraciones innecesarias
- **Estado:** El botón **Escuchar** sintetiza una muestra corta con la voz, steps, velocidad e idioma configurados (`SintetizarMuestra` + `VoicePreviewService`).

### 2. Comparador de voces ⬜ PENDIENTE
- Seleccionar un fragmento de texto y generarlo con 2-3 voces diferentes
- Escuchar y elegir la que mejor suene antes del procesamiento completo
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — resuelve el problema de "¿qué voz suena mejor?"

### 3. Presets de generación ⬜ PENDIENTE
- Guardar configuraciones favoritas (voz + velocidad + pasos + formato)
- "Narración rápida", "Calidad premium", "Podcast"
- **Esfuerzo estimado:** Bajo-Medio
- **Impacto:** Medio — hoy solo se recuerda la última configuración (`preferencias.json`), no hay perfiles nombrados

---

## 🥈 Mejoras en el pipeline de generación

### 4. Reanudar generación interrumpida ⬜ PENDIENTE
- Si la app se cierra o falla, retomar desde el archivo donde quedó
- Los archivos ya convertidos en la carpeta de salida se saltan automáticamente
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — evita reprocesamiento completo
- **Nota:** la cancelación ya elimina los WAVs temporales generados; hoy **todo** lote reprocesa desde cero (sin skip)

### 5. Detección automática de capítulos ⬜ PENDIENTE
- Parsear el Markdown para identificar capítulos (`#`, `##`) antes de limpiarlo
- Generar un archivo de audio por capítulo (hoy: un `.md` → un único WAV)
- **Esfuerzo estimado:** Medio-Alto
- **Impacto:** Alto — `limpiarMarkdown` **elimina** los headings; habría que preservarlos como marcadores de capítulo

### 6. Pre-procesamiento de texto ⚠️ PARCIAL
- Limpiar Markdown antes de enviar al TTS: quitar footnotes, links, código
- Expandir abreviaturas, corregir pronunciación de siglas
- **Esfuerzo estimado:** Medio
- **Impacto:** Medio-Alto — mejora la calidad del audio generado
- **Estado:** `limpiarMarkdown()` limpia todo el Markdown y `text_preprocessor` normaliza símbolos/emojis/NFKD y protege abreviaturas del corte de oraciones. **Falta:** expansión de abreviaturas (Dr. → *doctor*), pronunciación de siglas y eliminación de footnotes (`[^…]`)

### 7. Estadísticas antes de generar ⚠️ PARCIAL
- Mostrar: cant. de palabras, tiempo estimado de generación, tamaño de salida
- "Tu libro tiene 45.000 palabras, estimado: ~12 minutos de generación"
- **Esfuerzo estimado:** Bajo
- **Impacto:** Medio — transparencia para el usuario
- **Estado:** El benchmark mide chars/seg y **durante** la corrida se ve la ETA en vivo (por archivo y restante del lote). **Falta:** estimación **previa** visible en la UI (antes de tocar Procesar), conteo de palabras y tamaño de salida estimado

### 8. Post-procesamiento de audio ⬜ PENDIENTE
- Insertar silencios entre capítulos
- Normalizar volumen entre archivos
- **Esfuerzo estimado:** Bajo-Medio
- **Impacto:** Medio — calidad profesional del output
- **Nota:** el único silencio actual es fijo entre segmentos (`silencioMuestras`); FFmpeg no aplica filtros (`loudnorm`, `adelay`, `volume`)

---

## 🥉 Experiencia de usuario y producto

### 9. Exportación por lotes a carpeta de destino única
- Elegir una sola carpeta de salida para todo el lote (hoy se guarda por audio en Audio Manager)
- **Esfuerzo estimado:** Bajo
- **Impacto:** Medio — simplifica el guardado masivo

### 10. Cola de conversión / modo "manos libres"
- Procesar varios libros en cola sin intervención, con notificación al terminar
- **Esfuerzo estimado:** Medio
- **Impacto:** Medio — útil para lotes grandes

### 11. Verificación de pronunciación de nombres propios
- Diccionario de pronunciación por usuario (reemplazos texto → fonética aproximada)
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — los nombres propios suenan mal en TTS

### 12. Soporte de otros formatos de entrada
- `.txt`, `.epub`, `.html` además de `.md`
- **Esfuerzo estimado:** Medio-Alto
- **Impacto:** Medio-Alto — amplía los casos de uso (requiere conversores/extractores)

### 13. Ajuste de velocidad/pausa por párrafo
- Marcas en el Markdown (p. ej. `<!-- pausa -->`) para controlar el ritmo de lectura
- **Esfuerzo estimado:** Bajo-Medio
- **Impacto:** Bajo-Medio — control fino del narrador

### 14. Widget / previews en vivo
- Previsualización del diseño de las pantallas durante el desarrollo (skills `flutter-add-widget-preview`)
- **Esfuerzo estimado:** Bajo
- **Impacto:** Dev UX — agiliza el desarrollo de UI (no funcional para el usuario final)

### 15. Automatización de integración E2E en CI
- Correr el flujo md → WAV (hoy manual con `flutter drive`) en GitHub Actions
- **Esfuerzo estimado:** Medio
- **Impacto:** Medio — requiere FFmpeg disponible en el runner

---

## Resumen de factibilidad

| # | Funcionalidad | Esfuerzo | Impacto | Dependencias nuevas | Estado |
|---|--------------|----------|---------|---------------------|--------|
| 1 | Previsualización | Medio | Alto | Ninguna | ✅ Implementada |
| 2 | Comparador de voces | Medio | Alto | Ninguna | ⬜ Pendiente |
| 3 | Presets | Bajo-Medio | Medio | Ninguna | ⬜ Pendiente |
| 4 | Reanudar generación | Medio | Alto | Ninguna | ⬜ Pendiente |
| 5 | Detección de capítulos | Medio-Alto | Alto | Ninguna | ⬜ Pendiente |
| 6 | Pre-procesamiento texto | Medio | Medio-Alto | Ninguna | ⚠️ Parcial |
| 7 | Estadísticas pre-gen | Bajo | Medio | Ninguna | ⚠️ Parcial |
| 8 | Post-procesamiento audio | Bajo-Medio | Medio | Ninguna | ⬜ Pendiente |
| 9 | Exportación por lotes | Bajo | Medio | Ninguna | ⬜ Pendiente |
| 10 | Cola de conversión | Medio | Medio | Ninguna | ⬜ Pendiente |
| 11 | Pronunciación de nombres | Medio | Alto | Ninguna | ⬜ Pendiente |
| 12 | Otros formatos de entrada | Medio-Alto | Medio-Alto | epub/html: nuevas | ⬜ Pendiente |
| 13 | Pausas por párrafo | Bajo-Medio | Bajo-Medio | Ninguna | ⬜ Pendiente |
| 14 | Previews en vivo (dev) | Bajo | Dev UX | Ninguna | ⬜ Pendiente |
| 15 | E2E en CI | Medio | Medio | FFmpeg en runner | ⬜ Pendiente |

**Casi todas son viables sin dependencias externas nuevas.** El proyecto ya tiene
FFmpeg, file_picker, y todas las herramientas necesarias. Las únicas que requerirían
dependencias nuevas: #12 (epub/html → requiere `epubx`/`html` parsers).

---

## Recomendación de implementación

**Empezar por 2 + 11 (Comparador de voces + Pronunciación).** Atacan el dolor
principal de calidad: la elección de voz y la pronunciación. Con comparador, el flujo
pasa de "generar → escuchar → reconfigurar → regenerar" a "previsualizar → elegir →
generar una vez". Con diccionario de pronunciación, los nombres propios suenan bien.

**Segundo bloque (quick wins de producto):** #9 (exportación por lotes), #3 (presets)
y #7 (estadísticas pre-gen) — mejoran el flujo diario con esfuerzo bajo.

**Tercer bloque (arquitectura de pipeline):** #5 (capítulos) y #8 (post-procesamiento)
comparten diseño: ambos requieren tocar el pipeline de `ProcesarArchivo` y merecen un
cambio SDD propio si se aprueban.
