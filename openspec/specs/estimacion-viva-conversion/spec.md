# Estimación Viva de Conversión Specification

## Purpose

Durante la conversión de un lote de archivos markdown a audio (`HomeController.procesar()`), el usuario necesita visibilidad de cuánto falta para terminar. Esta capacidad muestra, Mientras un lote se convierte, un **tiempo estimado en vivo**: la estimación por archivo (según sus caracteres × la tasa por carácter del benchmark guardado) y un **tiempo restante del lote** auto-corregido a partir del tempo real transcurrido por archivo procesado × archivos restantes. Si no hay `benchmark_results` guardado, no se muestra ninguna estimación (silencio total).

## Requirements

### Requirement: Estimación por archivo en vivo (EVC-1) — Prioridad: must

Mientras un archivo se procesa, la UI MUST mostrar un tiempo estimado para ese archivo, calculado con `estimarTiempo` a partir de sus caracteres limpios (`limpiarMarkdown(leerArchivo(ruta)).length`) × la tasa por carácter del benchmark guardado. Si el archivo tiene 0 caracteres, la estimación MUST NOT mostrarse (nunca un "0 s").

#### Scenario: Estimación del archivo en curso

- GIVEN un `benchmark_results` guardado con datos no vacíos
- AND un lote con archivos que tienen caracteres > 0
- WHEN `procesar()` convierte un archivo
- THEN se muestra el tiempo estimado de ese archivo
- AND la estimación usa los caracteres limpios del archivo y la tasa del benchmark

#### Scenario: Archivo vacío sin "0 s"

- GIVEN un archivo con 0 caracteres tras limpiar el markdown
- WHEN `procesar()` llega a ese archivo
- THEN no se muestra estimación "0 s" para ese archivo

#### Scenario: Fallo de lectura no rompe la conversión

- GIVEN un archivo corrupto o ilegible
- WHEN `procesar()` intenta preleer sus caracteres
- THEN la lectura falla en silencio (try/catch)
- AND la conversión continúa sin crash
- AND no se muestra una estimación para ese archivo

### Requirement: Tiempo restante del lote (EVC-2) — Prioridad: must

Después de que el primer archivo del lote complete su conversión, la UI MUST mostrar un tiempo restante del lote, calculado como `tiempo_real_promedio_por_archivo × archivos_restantes`, donde el promedio usa el tiempo transcurrido real desde el inicio. Antes de que se procese el primer archivo, la estimación restante de lote MUST NOT mostrarse (evita división por cero).

#### Scenario: Estimación restante tras el primer archivo

- GIVEN un lote de N archivos con `benchmark_results` guardado
- WHEN el primer archivo completa su conversión
- THEN se muestra la estimación de tiempo restante del lote
- AND se calcula con el promedio real transcurrido × archivos restantes

#### Scenario: Sin restante durante el primer archivo

- GIVEN un lote de N archivos con `benchmark_results` guardado
- WHEN aún no ha terminado ningún archivo
- THEN no se muestra ninguna estimación de tiempo restante de lote

#### Scenario: Autocorrección en vivo

- GIVEN un lote en conversión con `benchmark_results` guardado
- WHEN se procesan más archivos
- THEN la estimación restante se recalcula con el promedio real acumulado

### Requirement: Guarda sin benchmark (silencioso) (EVC-3) — Prioridad: must

Si no existe un `benchmark_results` guardado (o está vacío), la UI MUST NOT mostrar ninguna estimación (ni por archivo ni de lote), SIN hint ni leyenda. Un usuario que nunca ejecutó el benchmark no ve números falsos.

#### Scenario: Sin benchmark no hay estimación

- GIVEN no existe `benchmark_results` guardado (o está vacío)
- WHEN `procesar()` convierte el lote
- THEN no se muestra ninguna estimación (ni por archivo ni de lote)
- AND no se muestra hint alguno de "ejecutá el benchmark"

### Requirement: Limpieza de la estimación (EVC-4) — Prioridad: must

Cuando el lote termina (finaliza o se cancela), la estimación en vivo MUST desaparecer del estado (`tiempoEstimado` se limpia). Si el usuario cancela a mitad del lote, la estimación MUST limpiarse al salir del `procesar()`.

#### Scenario: Fin de lote sin estimación residual

- GIVEN un lote que termina (con o sin cancelación)
- WHEN `procesar()` retorna
- THEN la estimación en vivo no queda visible en el estado

#### Scenario: Cancelación a mitad de lote

- GIVEN un lote en conversión con estimación visible
- WHEN el usuario cancela el proceso
- THEN la estimación se limpia
- AND no queda un número residual en la UI
