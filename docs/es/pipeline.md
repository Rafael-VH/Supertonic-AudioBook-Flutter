# Pipeline de Procesamiento de Audio

Cómo los archivos Markdown se convierten en audios — el flujo completo de transformación.

## Resumen

```
┌─────────────┐   ┌──────────┐   ┌───────────┐   ┌────────────┐
│  Leer .md   │ → │  Limpiar │ → │ Segmentar │ → │ Sintetizar │
│             │   │ (regex)  │   │  (puro)   │   │   (ONNX)   │
└─────────────┘   └──────────┘   └───────────┘   └─────┬──────┘
                                                       │
┌──────────────────┐   ┌───────────────────┐   ┌──────▼───────┐
│ Guardar (usuario)│ ← │ Audios pendientes │ ← │ Exportar WAV │
│ rename atómico   │   │ (Audio Manager)   │   │ a _temp/     │
└──────────────────┘   └───────────────────┘   └──────────────┘
```

**Regla central**: la síntesis nunca escribe en la ruta final. Todo queda en `<carpeta_salida>/_temp/` hasta que el usuario guarda desde el Audio Manager.

## Etapas del Pipeline

### 1. Leer Archivo

**Caso de uso**: `RepositorioArchivos.leerArchivo()`

- Lee el archivo como string UTF-8
- Error de lectura/permiso → `ResultadoProceso.error` (sin lanzar)

### 2. Limpiar Markdown

**Caso de uso**: `limpiarMarkdown()` (función pura)

Elimina toda la sintaxis Markdown en orden:

| Paso | Patrón Regex | Acción |
|------|-------------|--------|
| 1 | `~~~.*?~~~` | Eliminar bloques de código |
| 2 | `` ```.*?``` `` | Eliminar bloques de código con fence |
| 3 | `^#{1,6}\s*` | Eliminar encabezados |
| 4–9 | `\*{1-3}` / `_{1-3}` | Eliminar negrita/cursiva/énfasis |
| 10 | `` `{1,3}...`{1,3} `` | Eliminar código inline |
| 11 | `![alt](url)` | Eliminar imágenes (conservar texto alt) |
| 12 | `[text](url)` | Eliminar links (conservar texto) |
| 13 | `^\s*>\s?` | Eliminar blockquotes |
| 14 | `^-{3,}$` | Eliminar reglas horizontales |
| 15 | `^[-*+]\s+` | Eliminar marcadores de listas desordenadas |
| 16 | `^\d{1,3}[.)]\s+` | Eliminar marcadores de listas ordenadas |
| 17 | `\n{3,}` | Colapsar saltos de línea múltiples |

**Decisiones clave**:
- Abreviaturas protegidas (Dr., Sr., etc.) — no se dividen en estos puntos
- Patrones anclados previenen falsos positivos (ej. `2 * 3 * 4` se mantiene)
- Resultado vacío después de limpiar → `ResultadoProceso.omitido`

### 3. Segmentar Texto

**Caso de uso**: `segmentarTexto()` (función pura)

Divide el texto limpio en chunks listos para TTS:

```
Paso 1: Fusionar párrafos cortos (< 200 chars) en buffer
Paso 2: Dividir párrafos largos (> 1500 chars) por oraciones
Paso 3: Dividir oraciones oversized por palabras
Paso 4: Dividir palabras oversized por caracteres (último recurso)
```

**Constantes**: `maxCharsPerSegment = 1500` · `mergeThreshold = 200`

**Manejo de abreviaturas**:
```
Dr. García → Dr\x00 García  (proteger)
.split('. ')               (dividir)
Dr. García                  (restaurar)
```

### 4. Sintetizar

**Caso de uso**: `MotorTts.sintetizar()` → `MotorTtsSupertonic`

Convierte segmentos de texto en muestras de audio Float32:

```dart
final wav = await motor.sintetizar(
  texto,
  steps: steps,      // 5–12, más = mejor calidad
  speed: speed,      // 0.7–2.0
  lang: lang,        // 'es', 'en', etc.
);
```

**Gestión de memoria**:
- Fragmentos acumulados en memoria (`List<Float32List>`)
- Cuando `memoriaAcumulada > presupuesto` → volcar a disco via `wavAppend()`
- Presupuesto móvil: 64 MB · desktop: 500 MB (`presupuestoMemoria()`)

**Entre fragmentos**: se insertan `silenceSamples` (26460) ceros para pausas naturales.

### 5. Exportar WAV Temporal

**Destino**: `<carpeta_salida>/<stem>_libro/_temp/.tmp_<timestamp>_0_wav`

El caso de uso `ProcesarArchivo`:

1. Crea el subdirectorio `_temp/` junto a la ruta base destino
2. Escribe el WAV de trabajo ahí (nunca en la ruta final)
3. Convierte los formatos adicionales solicitados desde ese WAV (también a `_temp/`)
4. Devuelve `ProcesarResultado` con `tempPath` apuntando al WAV generado

El caller (`HomeController`) es responsable del ciclo de vida del temp.

### 6. Audios Pendientes (Audio Manager)

Al completar un lote sin errores, `HomeController` acumula los `AudioPendiente` y navega a `/audio-manager`. Desde esa pantalla el usuario decide por cada audio:

| Acción | Implementación |
|--------|----------------|
| **Guardar** | `GuardarAudio.ejecutar()`: mueve el temp al destino con `renameSync` (atómico). Si existe conflicto de nombre agrega sufijo `(N)` |
| **Cancelar/descartar** | Elimina los WAVs temporales |

**Limpieza de huérfanos**: al arrancar la app, `LimpiarTemporales` elimina WAVs de `_temp/` con más de 24 horas.

## Procesamiento por Lotes

`HomeController.procesar()` orquesta el lote completo:

```
1. Persistir preferencias (voz, formatos, carpetas)
2. Validar: formatos no vacío, hay archivos .md
3. Pre-chequeo de memoria → MemoryWarningDialog si estima > 70 % de RAM
4. Por cada archivo seleccionado:
   - ProcesarArchivo.procesar(...) → WAV temporal
   - Acumular AudioPendiente + entrada de historial (en memoria)
5. Al terminar:
   - Lote completo sin cancelación → persistir historial (cap 100 entradas)
   - Cancelación → eliminar temps acumulados, NO persistir historial
   - Éxito sin errores → push /audio-manager con los pendientes
```

**Concurrencia**: de un solo hilo. El motor TTS no soporta síntesis concurrente.

**Cancelación**: el usuario toca "Cancelar" → `cancelar = true`; el segmento actual termina, el loop se rompe y los temps generados se eliminan.

## Vista Previa de Voz

Síntesis rápida sin pipeline completo, vía `VoicePreviewService` + `SintetizarMuestra`:

```dart
await service.reproducirMuestra(
  voz: voz,
  lang: lang,
  textoMuestra: textoMuestraIdiomas[lang] ?? t.muestra_texto,
);
```

## Estimación con Benchmark

Si hay un benchmark guardado (`benchmark.json`), al completar un lote se registra la estimación de tiempo calculada con `EstimarTiempo` a partir de los caracteres procesados.

## Resumen del Flujo de Datos

```
Input:      Archivo .md (UTF-8)
            ↓
Clean:      Texto plano (sin sintaxis Markdown)
            ↓
Segment:    List<String> (≤ 1500 chars cada uno)
            ↓
Synthesize: List<Float32List> (muestras de audio + silencio)
            ↓
Export:     WAV temporal en <salida>/_temp/
            ↓
Review:     Audio Manager (renombrar / elegir carpeta / guardar o descartar)
            ↓
Publish:    renameSync atómico → archivo final
```
