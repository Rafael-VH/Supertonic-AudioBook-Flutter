# Plan de correcciones — Auditoría Judgment Day Round 1

> Derivado de la auditoría adversarial completa de `lib/` (2 jueces ciegos en paralelo,
> skill `judgment-day`, Round 1). Estado del juicio: `ESCALATED` — 1 CRITICAL confirmado,
> 11 WARNING (real) suspect, 6 WARNING (theoretical), 3 SUGGESTION.
> Este documento es el plan de implementación por fases. Cada fase termina con tests
> verdes y `flutter analyze` sin errores.

## Resumen ejecutivo

El hallazgo crítico **no se muestra en consola ni en tests**: todo export no-WAV
(mp3/flac/ogg) falla en producción porque FFmpeg se llama sin `-y` y el destino se
pre-crea vacío. Los tests pasan porque nunca reproducen el `_nuevoTemporal` pre-creado.

| Severidad | Confirmado | Suspect | Teórico | Sugerencia |
|-----------|------------|---------|---------|------------|
| CRITICAL  | 1          | —       | —       | —          |
| WARNING   | —          | 11      | 6       | —          |
| SUGGESTION| —          | —       | —       | 3          |

## Fases

### Fase 1 — [CRITICAL] Export no-WAV siempre falla (P0)

- **Archivos**: `lib/data/repositories/exportador_audio_ffmpeg.dart` (L61-62),
  `lib/domain/use_cases/procesar_archivo.dart` (L145-146, L152-153, L208-213)
- **Causa**: `FFmpegKit.executeWithArguments` sin `-y` + `_nuevoTemporal` pre-crea el
  destino → FFmpeg aborta con "Not overwriting" (rc=1). `formatos` ordena 'mp3' antes
  que 'wav', así que el run por defecto falla todos los archivos.
- **Fix**: pasar `-y` a FFmpeg (intención: sobrescribir temporal) y/o no pre-crear el
  destino; asegurar que el WAV parcial se publique correctamente en ambos caminos.
- **Tests**: agregar test que pre-cree el destino y verifique sobrescritura exitosa;
  mantener los existentes verdes.
- **Verificación**: `flutter test test/data/repositories/exportador_audio_ffmpeg_test.dart`
  + `flutter test test/domain/use_cases/procesar_archivo_integration_test.dart`.

### Fase 2 — [WARNING real] Archivos que fallan se cuentan como éxito (P1)

- **Archivos**: `lib/domain/use_cases/procesar_archivo.dart` (L59-69),
  `lib/presentation/controllers/home_controller.dart` (L394-395)
- **Causa**: un archivo que no se puede leer o queda vacío tras limpiar retorna en
  silencio; el controller hace `exitos++` incondicional.
- **Fix**: el use case retorna un resultado (éxito/error/saltado) y el controller
  reporta errores y excluye saltados del conteo.
- **Tests**: cubrir archivo ilegible y archivo vacío en
  `procesar_archivo_integration_test.dart`; ajustar expectativas del controller.

### Fase 3 — [WARNING real] Cancelar pisa el output previo (P1)

- **Archivos**: `lib/domain/use_cases/procesar_archivo.dart` (L40-42, L126-162)
- **Causa**: cancelar a mitad de carrera publica el audio truncado y `renameSync`
  reemplaza el output completo anterior del archivo en vuelo — contradice el docstring.
- **Fix**: al cancelar, publicar solo outputs cuyo destino no existía previamente;
  documentar semántica real de cancelación.
- **Tests**: test de cancelación que verifique que el output previo queda intacto.

### Fase 4 — [WARNING real] TTS concurrente durante "Escuchar" (P1)

- **Archivos**: `lib/presentation/controllers/home_controller.dart` (L311-312),
  `lib/presentation/widgets/barra_accion.dart` (L50-52), `lib/presentation/widgets/contenido_opciones.dart`,
  `lib/data/repositories/motor_tts.dart`
- **Causa**: Procesar está habilitado mientras `probandoVoz`; dos `sintetizar`
  concurrentes sobre los mismos 4 `OrtSession` (no thread-safe) → crash/audio corrupto.
- **Fix**: deshabilitar Procesar mientras `probandoVoz` y/o serializar TTS en el motor.
- **Tests**: test del controller que pruebe que `procesar` se bloquea durante
  `probandoVoz`; test de widget de la barra deshabilitada.

### Fase 5 — [WARNING real] `.part` corrupto bloquea descarga para siempre (P1)

- **Archivos**: `lib/data/modelo/modelo_manager.dart` (L112-140, L189)
- **Causa**: un `.part` que llegó al tamaño esperado pero está corrupto nunca se borra;
  el resume pide `Range: bytes=<full>-` → 0 bytes → verificación falla → excepción
  fuera del catch de retry → stall permanente.
- **Fix**: borrar `.part` al fallar verificación y hacer el fallo de integridad
  reintentable; test que simule `.part` corrupto.
- **Tests**: `test/presentation/controllers/modelo_controller_test.dart` o nuevo test
  del manager.

### Fase 6 — [WARNING real] Hash de modelo en main isolate (P1/P2)

- **Archivos**: `lib/data/modelo/modelo_manager.dart` (L154-162, L221-224)
- **Causa**: `verificarDisponible` hashea ~400 MB en el main isolate en cada arranque →
  congelamiento multi-segundo.
- **Fix**: hashear en isolate separado (`compute`/`Isolate.run`) y/o cachear el resultado.
- **Verificación**: manual + test de widget que no bloquee; no hay assertion de timing.

### Fase 7 — [WARNING real] Verificación async pisa estado de descarga (P2)

- **Archivos**: `lib/presentation/controllers/modelo_controller.dart`
- **Causa**: `_verificar` fire-and-forget puede completar después de "Descargar" y
  sobreescribir `descargando: true` con idle.
- **Fix**: guardar los writes de verificación (ignorar si ya descargó/descargando).
- **Tests**: test del controller con verificación lenta + descarga iniciada.

### Fase 8 — [WARNING real] "Agregar" reemplaza selección en vez de fusionar (P1)

- **Archivos**: `lib/presentation/controllers/seleccion_controller.dart`,
  `lib/presentation/screens/seleccion/seleccion_screen.dart`, `home_controller.dart`
  (`cargarArchivosExternos`)
- **Fix**: fusionar los nuevos picks con la selección existente (dedupe por ruta).
- **Tests**: test de controller que agregue 2 rondas y conserve ambas.

### Fase 9 — [WARNING real] `sintetizar_muestra` traga errores (P2)

- **Archivos**: `lib/domain/use_cases/sintetizar_muestra.dart` (L26-37)
- **Fix**: relanzar error tipado; el controller reporta la causa real en "Escuchar".
- **Tests**: test de uso del use case con síntesis fallida.

### Fase 10 — [WARNING real] Umbral de flush demasiado alto para móvil (P2)

- **Archivos**: `lib/data/config.dart` (L10), `lib/domain/use_cases/procesar_archivo.dart` (L114-123)
- **Fix**: dimensionar umbral según heap runtime o flushear por cantidad de segmentos /
  presupuesto menor en móvil.
- **Tests**: unit del cálculo del umbral (sin requerir device).

### Fase 11 — Teóricos y sugerencias (P3, opcional)

- **Archivos**: `segmentar_texto.dart` (L68-72), `repositorio_archivos.dart` (L34),
  `wav_io.dart` (NaN, ByteData 2 GiB), `supertonic_helper.dart` (`copyModelToFile`
  buffer view), `natural_sort.dart` (>19 dígitos), `archivo.dart` (título `.md`),
  `formato.dart` (mensaje mp3), `seleccion_controller.dart` (build → estado vacío),
  log virtualizado (`contenido_registro.dart`, `card_registro.dart`)
- **Fix**: cada uno es un cambio puntual y localizado con su test.

## Orden de ejecución y reglas

1. **Una fase por vez**, con `flutter analyze` y tests de la fase verdes antes de pasar
   a la siguiente.
2. Los fixes se implementan con commits por unidad de trabajo (`work-unit-commits`),
   conventional commits, sin atribución AI.
3. Tras implementar (una o más fases), se relanza el juicio (Round 2) con jueces ciegos
   para verificar que no quedaron issues confirmados antes de cerrar.
4. No se tocan `.vscode/`, `$log`, ni archivos fuera del alcance de cada fase.

## Estado de implementación (2026-08-15)

| Fase | Estado | Notas |
|------|--------|-------|
| 1 (CRITICAL -y FFmpeg) | ✅ Hecha | `-y` como primer argumento + test de regresión con destino pre-creado |
| 2 (Resultado de proceso) | ✅ Hecha | `enum ResultadoProceso {ok, omitido, error}`; controller cuenta por tipo |
| 3 (Cancelar pisa output) | ✅ Hecha | Al cancelar solo se publican destinos inexistentes previamente |
| 4 (TTS concurrente) | ✅ Hecha | Procesar bloqueado durante `probandoVoz` en controller + 2 botones |
| 5 (.part corrupto) | ✅ Hecha | Se descarta el `.part` y se reintenta desde cero; `test/data/modelo/` |
| 6 (Hash en isolate) | ✅ Hecha | `Isolate.run` para el SHA-256; test con binario |
| 7 (Verificación async) | ✅ Hecha | `_verificar` ignora el write si ya hay descarga en curso; test de carrera |
| 8 (Merge de selección) | ✅ Hecha | `agregarArchivosExternos` fusiona por ruta; pantalla de selección lo usa |
| 9 (sintetizar_muestra) | ✅ Hecha | `rethrow` tras loguear; el controller reporta la causa real |
| 10 (Umbral móvil) | ✅ Hecha | `presupuestoMemoria` estático; tope 64 MiB en móvil inyectado por composición |
| 11 (Teóricos) | ✅ Parcial | Hechas: segmento largo por caracteres, natural_sort >19 dígitos, NaN WAV (wav_io + writeWavFile), `copyModelToFile` buffer view, CP1252 fallback, log virtualizado (`VistaLog`). No aplicada: `seleccion_controller` build→estado vacío (evitar I/O requiere refactor mayor, riesgo > beneficio para un teórico). |

Verificación final: `flutter analyze` sin issues; `flutter test` 160 pasados, 4 skips
(FFmpeg no disponible en entorno de test).

## Re-juicio (2026-08-16) — Rounds 2 a 4

Tras implementar las fases se relanzó el juicio con dos jueces ciegos (skill `judgment-day`)
sobre `16105c1..HEAD`. Resultado por ronda:

| Ronda | Confirmados | Fixes aplicados | Verificación |
|-------|-------------|-----------------|--------------|
| Round 2 | 4 real + 1 teórico | Batch 1: `ModeloCorruptoException` tras 3 intentos; guard `ejecutando` en merge; `catch (exc)` en escuchar; guard `listo` en `_verificar`; `BigInt.parse` en natural_sort; `esMovil` inyectado (sin `Platform` en domain) | analyze limpio; 164 pasados, 4 skips |
| Round 3 | 1 real + 2 teóricos (guard `quitarArchivoExterno`, error de descarga pisado, BigInt discriminator) + 1 suspect real (416 loop) | Batch 2: guard `ejecutando\|\|probandoVoz` en `cargarArchivosExternos`; `error != null` en `_verificar`; discriminator `is int \|\| is BigInt`; borrar `.part` con `inicio >= tamanoBytes` | analyze limpio; 169 pasados, 4 skips |
| Round 4 | 6 confirmados (real/teórico + sugerencias) | **No aplicados** (decisión del usuario: cerrar acá) | — |

Veredicto final: **JUDGMENT: APPROVED** (0 CRITICAL, 0 WARNING real con doble consenso).
Quedan como INFO/suspect sin aplicar (documentados, no bloqueantes):

- `_verificar` fire-and-forget sin try/catch → estado atascado si `verificarDisponible()` lanza
- `escuchar` sin guard `ejecutando` a nivel controller (hoy protegido solo por UI)
- X/Agregar habilitados durante run: taps descartados sin feedback
- Guard asimétrico en `agregarArchivosExternos` (no cubre `probandoVoz`)
- Log de error con punto+colon y excepción cruda sin i18n
- Run todo-omitido reporta "éxito 0 archivos"
- Cancelado cuenta como `exitos++`; `.part` completo-válido re-descarga; progreso cae a 0; `fdb_helper` en runtime deps; `_partirFraseLarga` sin `.` final; comentario pureza vs `dart:io` preexistente; docstring `cargarArchivosExternos` desactualizado; VistaLog sin selección multi-línea
