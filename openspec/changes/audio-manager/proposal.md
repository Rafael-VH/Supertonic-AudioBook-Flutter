# Proposal: audio-manager

## Intent

`HomeController.procesar()` es un paso atómico: sintetiza, exporta y publica en una sola pasada. El usuario no puede elegir dónde guardar, renombrar o revisar antes de confirmar. Esto impide flujos donde procesás varios archivos y después decidís dónde va cada uno.

Separamos síntesis de publicación. La síntesis genera WAVs temporales; el usuario luego elige carpeta, nombre y formato de cada audio antes de que se escriba el destino final.

## Scope

### In Scope

- **`ProcesarResultado` gana `rutaWavTemp`** — el WAV de trabajo existente se expone en vez de destruirse
- **Nuevo módulo `lib/features/audio_manager/`** — domain (entidades, contratos, casos de uso), data (repositorio de temporales), presentation (controller + pantalla)
- **`AudioPendiente` entity** — nombre original, ruta WAV temporal, duración, caracteres, formatos disponibles
- **Pantalla "Audios Pendientes"** — lista de audios procesados, tile por audio, menú más (elegir carpeta, renombrar, confirmar)
- **Caso de uso `ExportarPendiente`** — mueve/convierde WAV temporal al destino del usuario
- **Caso de uso `EstimarMemoria`** — estima RAM antes de procesar, muestra warning si >70%
- **Limpieza de huérfanos** — al iniciar la app, elimina WAVs en `_temp/` más viejos de 24h

### Out of Scope

- Cambiar el motor TTS o el flujo de síntesis interna (MotorTts no se toca)
- Modificar la pantalla Biblioteca (ya escanea la carpeta de salida)
- Soporte multi-usuario o permisos de archivo
- Reproductor de audio en la pantalla de pendientes

## Capabilities

### New Capabilities

- `audio-pending-management`: Listado de audios sintetizados pendientes de guardado, con acciones (elegir carpeta, renombrar, confirmar). Incluye limpieza de temporales.
- `memory-estimation`: Estimación pre-procesamiento de RAM requerida vs disponible, con warning dialog.

### Modified Capabilities

None. `biblioteca-audiolibros` y `dashboard` no cambian a nivel de spec.

## Approach

**Paso 1: Exponer el WAV temporal.** `ProcesarArchivo` ya crea `rutaWavTrabajo` y lo destruye en el `finally`. Cambio mínimo: devolver la ruta en `ProcesarResultado` y NO borrarla en el finally. El caller decide cuándo eliminar.

**Paso 2: Nuevo módulo `audio_manager`.** Sigue la estructura de features existente (Clean Architecture, identificadores en español). El `AudioStore` (contrato) gestiona la carpeta `_temp/` y la limpieza. El controller mantiene la lista de `AudioPendiente` en memoria.

**Paso 3: Separar en `HomeController`.** `procesar()` pasa a devolver `List<AudioPendiente>` en vez de auto-exportar. La navegación lleva a la pantalla de pendientes. El guardado es un flujo independiente: usuario elige destino → `ExportarPendiente` ejecuta `ExportadorAudio.convertirDesdeWav()` o rename para WAV.

**Paso 4: Memory estimation.** Función pura que estima `chars × factor → segundos → bytes (sampleRate × 4)`. Se llama antes de procesar; si excede 70% de RAM disponible, muestra dialog con la estimación y opción de continuar/cancelar.

### Decisión técnica clave

El WAV temporal vive en `_temp/` bajo `carpetaOut`. Esto:
- Evita cruzar puntos de montaje (mismo filesystem = rename = rename atómico)
- Facilita limpieza (una sola carpeta, scan al inicio)
- No mezcla temporales con audios terminados

## Affected Areas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | Modified | `ProcesarResultado` gana `rutaWavTemp`; finally NO borra el WAV de trabajo |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modified | `procesar()` retorna pendientes en vez de auto-exportar; agrega pre-check de memoria |
| `lib/features/audio_manager/` (nuevo) | New | Domain + data + presentation del módulo completo |
| `lib/shared/domain/contracts/repositorio_archivos.dart` | Modified | Agrega `moverArchivo()` para reubicar temporales |
| `lib/presentation/controllers/providers.dart` | Modified | Providers nuevos para audio_manager |
| `lib/presentation/l10n/app_es.arb` + `app_en.arb` | Modified | Strings de la nueva pantalla y dialogs |

## Risks

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Temporales huérfanos acumulándose | Media | Limpieza al inicio (archivos >24h en `_temp/`). Test unitario de la lógica de limpieza. |
| Renombrado falla (archivo en uso) | Baja | `ExportadorAudio` ya maneja esto — reintentar una vez, mostrar error si persiste. |
| Conflicto de nombre al guardar | Media | Antes de mover, verificar existencia. Si existe → dialog "reemplazar / renombrar / cancelar". |
| RAM insuficiente para WAVs grandes | Baja | Pre-check con `EstimarMemoria` antes de procesar. WAV se vuelca a disco periódicamente (ya existe el patrón en `procesar_archivo.dart`). |
| Regresión en flujo actual de un solo paso | Baja | El flujo anterior se mantiene como fallback: si no hay pendientes, navegación directa a biblioteca. Tests del use case existentes siguen pasando. |

## Rollback Plan

1. Revertir `procesar_archivo.dart`: `ProcesarResultado` vuelve a no tener `rutaWavTemp`, finally vuelve a borrar todos los temporales.
2. Revertir `home_controller.dart`: `procesar()` vuelve a auto-exportar.
3. Eliminar `lib/features/audio_manager/` completo.
4. Quitar providers nuevos de `providers.dart`.
5. `flutter test` debe pasar sin cambios (tests existentes no dependen de esta feature).

## Dependencies

- Ninguna dependencia nueva. Se reutiliza `ExportadorAudio` (contrato existente) para la conversión final.
- Se usa `FileSystemContract` (ya inyectado) para mover/renombrar archivos.

## Success Criteria

- [ ] Sintetizar un archivo genera WAV temporal en `_temp/`, sin publicar destino final
- [ ] La pantalla de pendientes lista los audios procesados con nombre, duración y formato
- [ ] El usuario puede elegir carpeta destino antes de guardar
- [ ] El usuario puede renombrar el audio antes de confirmar
- [ ] Guardar convierte WAV al formato elegido y lo mueve al destino, luego borra el temporal
- [ ] Al cerrar/reabrir la app, los temporales huérfanos (>24h) se eliminan
- [ ] Si RAM estimada >70% disponible, se muestra warning antes de procesar
- [ ] Tests existentes de `ProcesarArchivo` pasan sin modificación
- [ ] Flujo actual (procesar → auto-guardar) sigue funcionando si el usuario no abre pendientes
