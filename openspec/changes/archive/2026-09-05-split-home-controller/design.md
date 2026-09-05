# Design: split-home-controller

## Executive Summary

Refactor behavior-preserving del `HomeController` (779 líneas) que ataca A1/A2 de la
auditoría 2026-09-05: (1) el diálogo de memoria, 100% genérico, se reloca a
`lib/core/widgets/`; (2) el loop de conversión de `procesar()` se extrae a un método
cohesivo `_procesarLote`; (3) la decisión de mostrar el diálogo pasa del controller a
la vista mediante el patrón evento-estado `ref.listen` (igual que `MensajeSnackbar`).
Se añade un seam mínimo `rssProcesoProvider` para que el umbral >0.7 sea testeable.
Cero abstracciones especulativas; los 18+ tests del controller + widget tests de
convert son la red de seguridad.

## Architecture Decisions

### Decision: Hogar del diálogo de memoria (el fork A2)

**Choice**: `lib/core/widgets/memory_warning_dialog.dart`.

**Alternatives considered**:
- (a) `lib/shared/presentation/widgets/` (crear directorio nuevo en shared).
- (b) Dejarlo en `audio_manager` (status quo — cruce de feature, auditado).
- (c) `lib/core/presentation/widgets/`.

**Rationale**: Arquitectura del repo: `lib/core/` ya existe para utilidades
transversales (hoy `audio/wav_io.dart`, `utils/natural_sort.dart`) y es el hogar de
widgets genéricos sin feature. `core/widgets/` es el estándar Flutter para widgets
reutilizables; `shared/` en este repo aloja domain puro (`shared/domain/`) y data, no
presentation. El diálogo solo depende de material + l10n — es transversal puro.

### Decision: Vista propietaria del diálogo (MVVM)

**Choice**: El controller expone `HomeEstado.advertenciaMemoria` (un valor tipado
`AdvertenciaMemoria?` con `estimatedBytes`/`availableBytes`) y `ConvertBody` lo
escucha con `ref.listen` — idéntico al patrón `snackbar`/`MensajeSnackbar` que ya
existe. El controller elimina `showMemoryWarningDialog` de su cuerpo; la vista lo
importa desde `core/widgets/`.

**Alternatives considered**:
- (a) Pasar `AppLocalizations t` + `BuildContext` a cada método (como hoy) y que el
  controller siga mostrando el diálogo.
- (b) La pantalla hace el pre-check de memoria antes de llamar `procesar()`.

**Rationale**: (b) duplicaría el cálculo de memoria en la vista y rompería la
separación actual; (a) perpetúa el cruce de feature y el threading de `BuildContext`.
El patrón evento-estado ya está validado con `MensajeSnackbar` (misma pantalla, mismo
`ref.listen`); reutilizarlo es consistente y deja los tests de controller (sin
context) intactos. La vista mapea estado → UI (skill arquitectura del proyecto).

### Decision: Pausa y reanudación del lote

**Choice**: `procesar()` se parte en un orquestador + `_ejecutarLote(...)`. El path
con diálogo hace: `_verificarMemoria` (solo calcula) → si hay advertencia y vista,
setea `advertenciaMemoria` y RETORNA (dejando `ejecutando: true`); la vista responde
y llama `reanudarProcesamiento(t, context:)` (confirma) o `cancelarAdvertencia(t)`
(cancela → snackbar cancelado). `reanudarProcesamiento` re-ejecuta
`_ejecutarLote` (sin volver a preguntar).

**Alternatives considered**:
- (a) `procesar()` espera un `Completer` que la vista completa — acoplamiento
  temporal frágil y difícil de testear.
- (b) Reescanear el estado al reanudar (guardar `seleccion` etc. en el estado).

**Rationale**: (a) crea un acoplamiento con ciclo de vida de la vista difícil de
razonar en tests; el pause-and-resume con estado transitorio `ejecutando: true` es el
patrón Riverpod idiomático. Para no re-escanear ni duplicar configuración, el
orquestador calcula una sola vez los parámetros y los pasa a `_ejecutarLote`; el
resume del diálogo necesita re-obtener esos parámetros: se conservan en un campo
privado transitorio `_lotePendiente` (solo poblado durante la ventana de pausa) que
se limpia al reanudar o cancelar. Alternativa más simple (re-calcular de `state`) es
posible porque `procesar()` ya re-lee todo de `state`, pero conserva los mismos
parámetros → `_lotePendiente` evita derivar estado duplicado.

### Decision: Seam de bytes disponibles

**Choice**: Nuevo provider `rssProcesoProvider = Provider<int>(...)` en
`providers.dart` que en producción devuelve `ProcessInfo.currentRss`, y el controller
lo lee con `ref.read(rssProcesoProvider)`.

**Alternatives considered**:
- (a) Seguir leyendo `ProcessInfo.currentRss` directo y testear el diálogo solo vía
  widget test con archivos enormes.
- (b) Inyectar `EstimarMemoriaDisponible` como provider.

**Rationale**: El provider es el seam de composición del repo (todo lo inyectable vive
en `providers.dart`); leer RSS directo es ilegal en domain y ya está permitido en
presentation, pero impide forzar `fraccion > 0.7` determinísticamente. Con el provider
un test overrides `rssProcesoProvider.overrideWithValue(bytesBajos)` y el diálogo
aparece sin depender del RSS real de la máquina CI. (b) no aporta: el use case ya es
puro y no necesita provider. Sin especulación: el provider es trivial (1 línea).

## Data Flow

```
procesar(t, {context})
  ├─ guards (formato, selección) → snackbar + return
  ├─ reset state (ejecutando: true, ...)
  ├─ _verificarMemoria(seleccion, t, context)          // cálculo puro
  │    stubs ← seleccion
  │    availableBytes ← ref.read(rssProcesoProvider)   // seam
  │    estimacion ← EstimarMemoriaDisponible()(...)
  │    if fraccion > 0.7 && context != null && mounted:
  │         state.advertenciaMemoria = (estimated, available)
  │         _lotePendiente = parametros                 // ventana de pausa
  │         return (sin ejecutar el lote)
  │    else → continua
  └─ _ejecutarLote(parametros, context)
       ├─ cambiarVoz + crearCarpetas + _loguearConfig
       ├─ _procesarLote(...)  → (exitos, errores, procesados)   // loop extraído
       ├─ EVC-4 clear tiempoEstimado
       ├─ persistir historial si finalizadoOk
       ├─ limpiar WAVs si cancelado
       └─ _finalizarCorrida(...) + navegación a AudioManager

Vista (ConvertBody)
  └─ ref.listen(homeControllerProvider.select((s) => s.advertenciaMemoria), ...)
       ├─ si != null → showMemoryWarningDialog(core/widgets)
       │     true  → controller.reanudarProcesamiento(t, context: context)
       │     false → controller.cancelarAdvertencia(t)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/core/widgets/memory_warning_dialog.dart` | **Create** | `git mv` del diálogo (sin cambios de lógica) |
| `lib/features/audio_manager/presentation/screens/memory_warning_dialog.dart` | **Delete** | Origen del diálogo |
| `lib/features/convert/presentation/controllers/home_controller.dart` | **Modify** | Quita import del diálogo; extrae `_procesarLote`; añade `advertenciaMemoria` + `reanudarProcesamiento` + `cancelarAdvertencia`; usa `rssProcesoProvider` |
| `lib/features/convert/presentation/screens/convert_screen.dart` | **Modify** | `ref.listen` de `advertenciaMemoria` y muestra el diálogo |
| `lib/presentation/controllers/providers.dart` | **Modify** | Añade `rssProcesoProvider` |
| `test/core/widgets/memory_warning_dialog_test.dart` | **Create** | Test movido |
| `test/features/audio_manager/presentation/screens/memory_warning_dialog_test.dart` | **Delete** | Se mueve a `test/core/widgets/` |
| `test/presentation/controllers/home_controller_test.dart` | **Modify** | Sin cambios de asserts; quizá wiring |
| `test/presentation/screens/convert_screen_test.dart` | **Modify** | Nuevo test del diálogo desde la vista (rss override) |

## Interfaces / Contracts

### Estado nuevo en `HomeEstado`

```dart
/// Solicitud de confirmación de memoria. `null` = sin advertencia.
final AdvertenciaMemoria? advertenciaMemoria;

class AdvertenciaMemoria {
  const AdvertenciaMemoria({
    required this.estimatedBytes,
    required this.availableBytes,
  });
  final int estimatedBytes;
  final int availableBytes;
}
```

### Métodos nuevos del controller

```dart
/// Reanuda el lote tras confirmar la advertencia de memoria.
Future<void> reanudarProcesamiento(AppLocalizations t, {BuildContext? context});

/// Cancela la corrida tras la advertencia (snackbar cancelado).
void cancelarAdvertencia(AppLocalizations t);
```

### Provider nuevo

```dart
/// Bytes en uso por el proceso actual (RSS). Seam para probar el umbral de
/// memoria; en producción devuelve `ProcessInfo.currentRss`.
final rssProcesoProvider = Provider<int>(
  (_) => throw UnimplementedError('rssProcesoProvider se inyecta en main.dart'),
);
```

## What Stays in the Controller (per proposal)

- Lectura del RSS vía `rssProcesoProvider` (presentation-legal, ahora inyectable)
- Umbral `>0.7` (decisión de presentación sobre cuándo advertir)
- Temp-WAV file checks (`File(...).existsSync()`)
- Path assembly (`Platform.pathSeparator`)
- `_loguearConfig()` / `_finalizarCorrida()` / `_mostrarEstimacion()` (helpers de presentación)

## Testing Strategy

### Red de seguridad existente (sin cambios de asserts)

- `test/presentation/controllers/home_controller_test.dart` — 18+ tests. Todos llaman
  `procesar(t)` sin `context` → `_verificarMemoria` nunca pausa → asserts intactos.
- `test/presentation/screens/convert_screen_test.dart` — widget tests del layout.
- `test/features/audio_manager/presentation/screens/memory_warning_dialog_test.dart`
  → se mueve a `test/core/widgets/` sin cambios.

### Tests nuevos

| Test | Qué cubre | Cómo |
|------|-----------|------|
| `convert_screen_test.dart` (nuevo) | La pantalla muestra el diálogo cuando `fraccion > 0.7` y reanuda/cancela | `rssProcesoProvider.overrideWithValue(1)` (RSS mínimo → fracción altísima); tap Procesar; `expect(find.byType(AlertDialog), findsOneWidget)`; tap confirmar → lote corre; cancelar → snackbar cancelado |
| `home_controller_test.dart` (nuevo) | `procesar` con `context: null` NO pausa ni setea `advertenciaMemoria`; `reanudarProcesamiento` sin advertencia no-op | Sigue sin contexto, asserts sobre `state.advertenciaMemoria == null` |

**TDD order**: F3.1 RED (widget test del diálogo) → F3.2 GREEN (evento + vista).

## Migration / Rollout

Sin migración de datos ni feature flags. Fases commit-eables: F1 (relocación), F2
(extract), F3 (vista). Cada fase deja la suite verde.

## Out of Scope (per proposal)

- UC `ProcesarLote` de dominio — follow-up evaluado, no ahora.
- Dividir el controller en varios — rechazado en 2026-09-02.
- A3/A4/A5 del plan — diferidos.
- Cambiar el contrato compartido de cancelación de `run_benchmark`.

## Open Questions

- Ninguna bloqueante. El nombre `AdvertenciaMemoria` vs `MemoryWarningSolicitud` es
  cosmético; se usa el español (convención del repo).

## Changed-Line Estimate + Risk

| Metric | Estimate |
|--------|----------|
| New lines (dialog move + provider + evento) | ~60 |
| New test lines | ~60 |
| Modified lines (controller + convert_screen) | ~120 net |
| **Total changed lines** | **~240** |
| 400-line PR budget risk | **Low** |
| Risk | **Low** — refactor puro por fases, tests existentes como red de seguridad |
