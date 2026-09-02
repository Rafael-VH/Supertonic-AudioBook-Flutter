# Informe de Implementación — Plan de Correcciones de la Auditoría 2026

**Fecha:** 2026-09-02 · **Rama:** `main` · **Proyecto:** Supertonic-AudioBook-Flutter
**Alcance:** Ejecución completa del plan derivado de la auditoría integral 2026 + refactor del god class `home_controller.dart` vía flujo SDD.

---

## 1. Resumen ejecutivo

Este informe documenta **qué** se cambió, **por qué** se cambió, **cómo** se llegó a cada solución (skills, agentes y decisiones humanas involucradas), y **qué mejoras** aportó cada cambio. A diferencia de un changelog, este documento conserva la **narrativa de decisión**: no solo el resultado, sino el razonamiento detrás.

**Resultado global en números:**

| Métrica | Antes | Después |
|---------|-------|---------|
| Commits de la sesión | — | **10** |
| Archivos tocados | — | **40** |
| Líneas netas | — | **+668 / −526** (−190 netas) |
| `flutter analyze lib` infos | 3 | **1** |
| Tests declarados | 384 | **384** (51 archivos) |
| Fallos de suite | 1 (test stale de versión) | **0** (4 skips FFmpeg pre-existentes) |
| Dependencia `shared_preferences` | presente | **eliminada** |
| Use cases nuevos | — | **2** (`registrar_conversion_en_historial`, `estimar_memoria_disponible`) |
| Lógica de historial duplicada | 2 locaciones | **1** (use case puro) |

---

## 2. Contexto y origen — por qué se hizo esto

### 2.1 La auditoría integral 2026 (sesión previa)

El punto de partida fue una **auditoría completa del código y la documentación**, pedida explícitamente sobre el proyecto. Se ejecutó con **tres subagentes especializados**, cada uno con su skill dedicada:

1. **Subagente de arquitectura** (skills `arquiman` + `refactoryman`)
   → Revisión de Clean Architecture / Refactoring sobre los 107 archivos Dart en `lib/` (11 features).
2. **Subagente de sobre-ingeniería** (skill `ponytail-audit`)
   → Barrido de todo el repo en busca de dependencias muertas, código muerto y abstracciones especulativas.
3. **Subagente de documentación** (skill `cognitive-doc-design`)
   → Auditoría de los 9 pares ES/EN de `docs/` + README contra el código real.

### 2.2 Hallazgos críticos de la auditoría

La auditoría devolvió estos hallazgos (observación engram #641 resumida):

**Arquitectura (CRITICAL):**
1. **`home_controller.dart` (702 líneas)** es un *god class*: importa `dart:io`, accede directo a repositorios en la capa de presentación, y embebe lógica de negocio (persistencia de historial con tope, decisión de memoria).
2. `biblioteca_controller` y `settings_controller` importan `dart:io` (`Platform.pathSeparator`).
3. Entidades `toMap`/`fromMap` (serialización) dentro del dominio de `benchmark`.
4. **Acoplamiento cruzado** convert ↔ benchmark (comparten `segmentarTexto`, `MotorTts`).

**Sobre-ingeniería (deuda):**
- Dependencia `shared_preferences` no usada (el repo tiene su propio `RepositorioPreferencias`).
- Código muerto: `wav_writer.dart` (59 líneas), barrel `supertonic_helper.dart` (38 líneas), `normalizarFormatos`/`FormatoInvalido`/`subtiposAudio`/`silenceDurationSecs`, `BenchmarkResult.avgCharsPerSec`.
- `FileSystemContract` colapsable en `RepositorioArchivos` (evaluado, no aplicado por invasivo).

**Documentación (desincronizada):**
- `plan-flutter-android.md` es histórico (ahora es mobile-only) con deps/versiones stale.
- `testing.md` declara 45 archivos/369 tests vs el real **52/390**.
- `appVersion '1.0.3'` en `acerca_de_section.dart` vs pubspec `1.0.0+1`.
- Typo de licencia `OpenRAWL-M` → `OpenRAIL-M`.
- **Bug real de claves**: `AppPreferences` usaba `carpeta_salida`/`langVoz`, pero los controllers de Home/Settings/Biblioteca leían `carpeta_out`/`lang_voz` → la carpeta de salida elegida y el idioma de voz **nunca se aplicaban**.

### 2.3 El plan de 6 fases

De esos hallazgos se derivó un **plan de 6 fases**. **Tú aprobaste el orden de ejecución recomendado.**

| Fase | Descripción | Estado |
|------|-------------|--------|
| F1 | Alinear claves de preferencias (bug real) | ✅ `0602ae0` |
| F2 | Limpiar código muerto + dependencia compartida | ✅ `9ef9de4` |
| F3 | Purgar `dart:io` en presentación | 🔲 **Salteada** (no-op, ver §4.3) |
| F4 | Refactor del god class `home_controller` (vía SDD) | ✅ 4 commits |
| F5 | Desacoplar convert ↔ benchmark (`segmentarTexto`) | ✅ `1085a9c` |
| F6 | Corregir documentación + métricas | ✅ `f38cfc7` + `109b2f6` |

---

## 3. Cómo se trabajó — skills, agentes y método

### 3.1 Configuración del flujo SDD (decisión tuya)

Para la **Fase 4** (la más grande y riesgosa) se activó el flujo **SDD (Spec-Driven Development)**. En la **sesión de preflight**, elegiste explícitamente estas opciones:

| Grupo | Elección | Significado |
|-------|----------|-------------|
| A. Ritmo | **A1 Interactivo** | Mostrar cada fase y esperar tu confirmación antes de continuar |
| B. Artefactos | **B1 OpenSpec** | Artefactos de spec como archivos en el repo, trazables en revisión |
| C. PRs | **C1 Preguntarme** | Frenar y preguntar si la estimación supera el presupuesto |
| D. Revisión | **D3 → 800 líneas** | Presupuesto de revisión ampliado (cambio mediano) |

Además:
- Se detectó **`strict_tdd: true`** (observación engram #554): el flujo de implementación debía cumplir TDD estricto con runner `flutter test`.
- El guard de init SDD estaba satisfecho (proyecto inicializado previamente).

### 3.2 Los subagentes especializados usados

Cada fase o sub-fase se delegó a un **subagente especializado** (contexto fresco, sin memoria propia, a cargo del orquestador). Los que participaron:

| Subagente / Skill | Rol en esta sesión |
|-------------------|--------------------|
| `arquiman` | Revisar Clean Architecture antes de tocar `lib/features/` |
| `refactoryman` | Criterio de refactoring seguro (preservar comportamiento) |
| `ponytail-audit` | Detectar sobre-ingeniería / código muerto / deps no usadas |
| `ponytail` (modo full) | Regla YAGNI durante diseño e implementación |
| `cognitive-doc-design` | Corrección de documentación con baja carga cognitiva |
| `sdd-explore` | Explorar el god class antes de commitear el cambio |
| `sdd-propose` | Redactar la propuesta del cambio (`refactor-home-controller`) |
| `sdd-design` | Diseño técnico + resolver el fork de memoria |
| `sdd-tasks` | Desglose en 12 tareas TDD-ordenadas |
| `sdd-apply` | Implementación con TDD estricto + commits por unidad |
| `sdd-verify` | Validación contra diseño/tasks (65 tests verdes, 0 críticos) |
| `sdd-archive` | Cierre del cambio y sync de specs delta |
| `work-unit-commits` | Commits por unidad de trabajo (no por tipo de archivo) |

---

## 4. Detalle por fase — qué, por qué, cómo y mejoras

### 4.1 Fase 1 — Bug real de persistencia de preferencias

**Commit:** `0602ae0 fix(prefs): align typed preferences keys with runtime keys`

**El problema (bug real, confirmado):**
El sistema tipado `AppPreferences` serializaba con las claves `carpeta_salida` y `langVoz`, pero los controllers de Home/Settings/Biblioteca guardaban y leían con `carpeta_out` y `lang_voz` (sistema "loose"). Dos sistemas escribiendo y leyendo con claves distintas → **la carpeta de salida elegida y el idioma de voz se guardaban bajo un nombre y se leían bajo otro** → la configuración simplemente "no aplicaba".

**Cómo se llegó:**
1. La auditoría (arquiman/refactoryman) marcó la divergencia de claves como hallazgo.
2. Al implementar, se verificó en código real: `lib/features/convert/presentation/controllers/preferences_persistence.dart` (claves `carpeta_in`/`carpeta_out`) vs `lib/shared/domain/entities/app_preferences.dart` (clases tipadas `carpeta_salida`/`langVoz`).
3. **Decisión de diseño:** alinear el sistema tipado hacia las claves **canónicas** (`carpeta_out`, `lang_voz`), porque esas son las que usan los controllers en runtime real.

**Mejora:** se eliminó una desincronización silenciosa de configuración. Afectó entidad + tests (repositorio y entidad).

---

### 4.2 Fase 2 — Limpieza de código muerto y dependencia obsoleta

**Commit:** `9ef9de4 refactor(cleanup): remove dead code and unused shared_preferences dep` — **el más grande: −406 líneas netas, 16 archivos.**

**Qué se quitó y por qué:**
- **`wav_writer.dart`** — escritor de WAV sin ningún consumidor.
- **Barrel `supertonic_helper.dart`** — re-export de utilidades, indirección innecesaria.
- **`normalizarFormatos` / `FormatoInvalido` / `subtiposAudio` / `silenceDurationSecs`** — utilidades huérfanas (sin callers).
- **`BenchmarkResult.avgCharsPerSec`** — campo calculado nunca consumido.
- **`EditarMetadataMp3`** pass-through — delegación sin valor agregado.
- **Dependencia `shared_preferences`** — el repo tiene su propio `RepositorioPreferencias`; la dependencia era redundante (56 líneas de lock eliminadas). Esto la detectó el subagente `ponytail-audit`.

**Qué se conservó a propósito (y por qué):**
- `formatosNativos`, `silenceSamples`, `BenchmarkResult.toMap` — marcados en un primer análisis como "muertos", pero **verificados con grep de callers** resultaron **en uso** (p. ej. `toMap` como fixture de test). Quitarlos habría sido un segundo bug.

**Mejora:** menor superficie de código, menos dependencias (build más liviano, menor superficie de ataque), menos deuda técnica. También reveló la **importancia de verificar callers antes de borrar** — un anti-patrón evitado.

---

### 4.3 Fase 3 — Purgar `dart:io` en presentación (**SALTEADA, decisión tuya**)

**Qué era:** eliminar los usos de `dart:io` en la capa de presentación (por la lectura estricta de arquiman sobre pureza de capas).

**Por qué se salteó (no-op):**
Se verificó la regla real del proyecto en `lib/presentation/controllers/providers.dart:28`: **"la presentación sí puede usar `dart:io`; el dominio no"**. Bajo esa regla, purgar `dart:io` de presentación no aportaba nada — era un cambio sin efecto real.

**Decisión:** la lectura estricta de `arquiman` había *over-reached*; **te lo presenté y aprobaste saltear la fase 3** como no-op. Esto evitó un refactor costoso para cero beneficio. Lección: validar la regla contra el código real antes de aplicar la letra de un principio.

---

### 4.4 Fases 5 — Desacoplar convert ↔ benchmark

**Commit:** `1085a9c refactor(shared): decouple benchmark from convert's segmentarTexto`

**El problema:** la feature `benchmark` importaba internals de la feature `convert` (específicamente `segmentar_texto.dart`). Era acoplamiento cruzado entre features que violaba la independencia.

**Cómo se llegó:**
1. La auditoría marcó el acoplamiento convert↔benchmark.
2. El subagente `sdd-apply` para la fase de desacople evaluó tres sub-tareas: (a) mover `segmentarTexto`, (b) mover `MotorTts`, (c) mover `toMap/fromMap`.
3. **Decisiones:**
   - `segmentarTexto` también lo usa `convert` y era lógica de dominio compartida → se movió a **`lib/shared/domain/use_cases/segmentar_texto.dart`** con su test.
   - `MotorTts` tenía un solo consumidor extra → **se dejó en convert** (moverlo era demasiado invasivo; follow-up documentado).
   - `toMap/fromMap` de BenchmarkResult → **se dejaron** (usados como fixture de test; follow-up documentado).

**Mejora:** `benchmark` ya no depende de `convert`; la regla de dependencia de Clean Architecture quedó más limpia entre features. Se descartaron a propósito los movimientos invasivos (ponytail: mínimo viable).

---

### 4.5 Fase 6 — Corrección de documentación y métricas

**Commits:** `f38cfc7 docs: fix factual errors from audit` + `109b2f6 test(settings): ...`

**Qué se corrigió:**
- Typo `OpenRAWL-M` → **`OpenRAIL-M`** (licencia correcta de Supertone Inc.) en `docs/es/supertonic-3-model.md`.
- `appVersion` **1.0.3 → 1.0.0+1** en `acerca_de_section.dart`, alineado con `pubspec.yaml`.
- Métricas de `docs/es/testing.md` y `docs/en/testing.md`: sincronizadas a los valores reales **50 archivos / 380 passed / 4 skips** (verificados corriendo la suite, no de memoria).
- Banner histórico en `plan-flutter-android.md`.
- README sincronizado.

**Cómo se llegó:** el subagente `cognitive-doc-design` marcó la desincronización; se **verificó cada número corriendo la suite real** (la descubierta: métricas reales = 50/384 declaradas/380 pasan/4 skips, no las 45/369 que decían los docs). Se corrigió contra evidencia, no contra suposiciones.

**Fix de test stale (`109b2f6`):** la corrección de versión (Fase 6) dejó roto el test "Acerca de" que aún esperaba "Versión 1.0.3". Esto se detectó en la Fase 4 (la suite completa lo marcó) y se alineó a `1.0.0+1`. **Dejó la suite completa en verde.**

---

### 4.6 Fase 4 — Refactor del god class `home_controller.dart` (el trabajo central)

Esta fue la fase más grande y la única que se ejecutó con el **flujo SDD completo de 7 pasos**. A continuación, el recorrido con decisiones y subagentes.

#### 4.6.1 Explore (subagente `sdd-explore`)
Se mapeó el archivo: `home_controller.dart` de **702 líneas**, un *god class* que mezclaba build/http, listado de carpetas/archivos, selección, opciones de voz, y un método `procesar()` de ~237 líneas, con **acceso directo a repositorios** y **lógica de negocio** (persistencia de historial con tope 100, decisión de memoria con umbral 0.7) dentro de la presentación. Se identificó además que la lógica de escritura de historial **estaba duplicada** entre `home_controller` y `benchmark_controller`.

Se exploraron 3 extracciones posibles y se **descartaron a propósito** las que eran especulativas (envolver `listarArchivosMd`/`crearCarpetasSiNoExisten`, mover `File()`/path assembly, reescribir el loop TTS).

#### 4.6.2 Propose (subagente `sdd-propose`)
Se redactó la **propuesta** `refactor-home-controller`:
- **Intent:** achicar el god class extrayendo la lógica de negocio a use cases, **reusando lo que ya existe** (`estimar_memoria.dart` en audio_manager, `estimar_tiempo.dart` en benchmark).
- **Alcance dentro:** (1) use case `registrar_conversion_en_historial` compartido, (2) orquestador de memoria que reutiliza el math, (3) adelgazar `procesar()` vía Extract Method.
- **Alcance fuera** (a propósito, YAGNI): no envolver helpers de archivos, no mover path/File, no reescribir el loop TTS.
- **Estimación:** ~150-250 líneas en ~7 archivos.
- **Guard de revisión:** Chained PRs **No**, riesgo 400 líneas **Bajo** → `single-pr`.

#### 4.6.3 Design (subagente `sdd-design`) — resolvió un fork
El diseño definió el mapa de archivos y resolvió el **único fork de diseño** que la propuesta había diferido: *cómo llega la estimación de memoria a la decisión de dominio*.

Las dos opciones:
- (a) inyectar un "read memory" provider/function en el use case, **o**
- (b) que el controller lea `ProcessInfo.currentRss` y pase `availableBytes` como parámetro a un use case puro.

**Decisión: opción (b).** Razones: `fraccionMemoriaRequerida` ya toma dos ints; inyectar un provider para una sola lectura de plataforma es **YAGNI**. Arquiman y ponytail coincidieron: el use case queda **puro** (sin `dart:io`), recibe valores de plataforma como parámetros. No se creó ninguna abstracción especulativa.

Hallazgo del diseño que simplificó todo: **`benchmark_controller` lee el historial pero nunca lo escribe** → el use case nuevo lo consume solo `home_controller` por ahora; el path compartido queda disponible para futuro sin tocar `benchmark_controller`.

#### 4.6.4 Tasks (subagente `sdd-tasks`) — 12 tareas TDD
Desglose en **12 tareas / 4 fases**, ordenadas TDD-first (la de mayor riesgo comportamental primero):
- **Fase A (historia, RED→GREEN):** use case nuevo + 5 tests + provider.
- **Fase B (memoria):** orquestador puro.
- **Fase C (controller):** Extract Method + cableado, re-corriendo los 18+12 tests tras cada paso.
- **Fase D (verificación):** suites completas + `analyze`.

Forecast: ~190 líneas, riesgo bajo, **single-pr**.

#### 4.6.5 Apply (subagente `sdd-apply`) — TDD estricto
Implementación con **TDD estricto** (test runner `flutter test`), en **3 commits por unidad de trabajo**:

| Commit | Contenido | Evidencia TDD |
|--------|-----------|---------------|
| `93dc318` | Use case `registrar_conversion_en_historial` + 5 tests + provider | RED: el test referenciaba el tipo inexistente → falló compilación; GREEN: tras implementar, 5/5 pasan |
| `a180a8a` | Orquestador puro `estimar_memoria_disponible` | Suite afectada verde (sin callers cambiados) |
| `b9de1bb` | Extract de `_verificarMemoria`/`_persistirHistorial` en `home_controller` | 18 home + 12 benchmark + 5 nuevos = 35 verdes; `analyze` limpio |

**Deviaciones aceptadas del design (y por qué):**
- No se sobre-extrajo para cumplir un target numérico arbitrario de líneas (el design pedía `<550`; quedó 733). El Extract Method *agrega* líneas de firma mientras saca lógica; **el requisito duro es preservar comportamiento, no alcanzar un número** (ponytail: "no abstracción no pedida").
- `EstimarMemoriaDisponible`, al ser puro y sin dependencias, se instancia directo (sin provider) — un provider sería boilerplate.

**Detalle de las extracciones en `home_controller`:**
- `_verificarMemoria()` — lee `ProcessInfo.currentRss`, llama al use case puro, conserva el diálogo de umbral >0.7 en el controller.
- `_persistirHistorial()` → delega en `registrar_conversion_en_historial`.
- `_loguearConfig()`, `_finalizarCorrida()`, más los ya existentes `_onProgreso`, `_formatearTiempo`, `_appendLog`, `_mostrarEstimacion`.
- `procesar()` adelgazado ~63 líneas. Se eliminó el import de `estimar_memoria.dart` que quedaba sin uso.

#### 4.6.6 Verify (subagente `sdd-verify`) — PASS
Validación contra diseño/tasks: **65 tests pasan, 0 fallan, 0 skips**; `analyze lib` sin errores. Verificación por diff vs `b9de1bb~1`: matemática de memoria idéntica, lógica de persistencia idéntica, finalización idéntica → **comportamiento 100% preservado**. 5/5 elementos de diseño VERIFIED. **Sin issues críticos.** TDD compliance 6/6.

#### 4.6.7 Archive (subagente `sdd-archive`) — cierre
- Cambio movido a **`openspec/changes/archive/2026-09-02-refactor-home-controller/`** (audit trail con exploration/proposal/design/tasks).
- Commit `4107ec4 chore(sdd): archive refactor-home-controller`.
- Al ser refactor puro sin capability nueva, **no se inventó un spec funcional** (el esquema Given/When/Then es solo para comportamiento de usuario) — sigue el patrón del archive análogo previo.

**Mejoras concretas de la Fase 4:**
- ✅ La **colocación de historial con tope 100 vive en un solo lugar** (use case puro) en vez de duplicada.
- ✅ El dominio de `audio_manager`/`benchmark` quedó **puro** (sin `dart:io`); la plataforma se inyecta por parámetro.
- ✅ `procesar()` pasó de monolito a **métodos cohesivos**.
- ✅ Respaldo por una **red de seguridad de 18 tests** de controller.

---

## 5. Mini-cambio posterior — limpieza de lints (y una lección)

**Commit:** `62d8cdb refactor(lint): guard context.mounted in save-all and use debugPrint`

**Resultado:** `flutter analyze lib` bajó de **3 infos a 1**.

- `audio_manager_screen.dart` → guard **`context.mounted`** tras el `await` (elimina `use_build_context_synchronously`).
- `print_logger.dart` → `print` → **`debugPrint`** (canónico de Flutter, elimina `avoid_print`).

**La lección (hallazgo de la sesión):** el tercer info (`home_controller.dart:548`, `use_build_context_synchronously`) **no se pudo limpiar sin romper comportamiento**. Mi **primer** intento trató el parámetro `BuildContext? context` de `_finalizarCorrida` como "muerto" (el cuerpo navega con `ref`, no con `context`) y lo eliminó → **rompió 5 tests** (`ProviderException: modeloManagerProvider en error state`, porque el guard `context != null` controla SI se navega y los tests dependen de que sin context no navegar).

**Decisión final:** se revirtió y se dejó el info **deliberadamente**, con la justificación de que es un **falso positivo estructural**: recibe `context` pero no lo usa para navegar (usa `ref`); aún así su guard es un contrato ejercido por los tests. Se documentó en memoria (observación #655). **Lección sobre-ingeniería:** un parámetro puede tener un guard funcional aunque su nombre no aparezca en el cuerpo; un info de lint no es obligación de limpiar si el fix cambia comportamiento o rompe la red de seguridad.

---

## 6. Las decisiones que tomaste vos

Para que quede constancia de la gestión humana del proceso:

1. **Pediste la auditoría integral 2026** de código y documentación con los 3 subagentes especializados.
2. **Aprobaste el orden de ejecución** de las 6 fases del plan resultante.
3. **Elegiste el preflight SDD**: ritual interactivo (A1), artefactos OpenSpec (B1), PR "preguntarme" (C1), presupuesto de revisión de 800 líneas (D3).
4. **Aprobaste saltear la Fase 3** (purga de `dart:io` en presentación) al confirmarse que era un no-op contra la regla real del proyecto.
5. **Avanzaste por cada puerta de fase interactiva** (design, tasks, apply, verify, archive) confirmando "Continuar".
6. **Descartaste** (vía aprobación de mi recomendación de arquitecto) una descomposición adicional de `home_controller` a 733 líneas, por no aportar cohesión real y arriesgar *parameter bombing*.
7. **Solicitaste este informe** con la narrativa completa de decisión, no solo el resumen.

---

## 7. Notas de arquitectura y señales de equilibrio

- **Regla del proyecto confirmada:** la presentación puede usar `dart:io`; el dominio no (`providers.dart:28`). Sobre esto se decidió la Fase 3.
- **Frontera pragmática:** se descartaron refactors que hubieran sido "más puros" pero más invasivos (mover `MotorTts`, mover `toMap/fromMap`, colapsar `FileSystemContract`) porque el costo no compensaba el beneficio — quedaron como follow-ups documentados.
- **`home_controller` a 733 líneas:** equilibrado tras la Fase 4. `procesar()` ya está descompuesto en métodos cohesivos; una descomposición mayor provocaría *parameter bombing* (code smell) sin ganancia real, por eso no se recomendó forzarla.

---

## 8. Trazabilidad

- **Artefactos SDD archivados:** `openspec/changes/archive/2026-09-02-refactor-home-controller/` (exploration, proposal, design, tasks).
- **Memoria persistente (engram):** observaciones clave #641 (auditoría), #646 (plan de fases), #553 (bug AppPreferences), #554 (init SDD / strict_tdd), #655 (lección del context param), más el verify-report (#651) y archive-report (#653).
- **Commits (orden cronológico):**
  1. `0602ae0` fix(prefs) — F1
  2. `9ef9de4` refactor(cleanup) — F2
  3. `f38cfc7` docs + métricas — F6
  4. `1085a9c` refactor(shared) segmentarTexto — F5
  5. `93dc318` feat(benchmark) historial use case — F4 apply
  6. `a180a8a` refactor(audio-manager) memoria — F4 apply
  7. `b9de1bb` refactor(convert) extract — F4 apply
  8. `109b2f6` test(settings) version — F4 test-fix
  9. `4107ec4` chore(sdd) archive — F4
  10. `62d8cdb` refactor(lint) — limpieza de infos
