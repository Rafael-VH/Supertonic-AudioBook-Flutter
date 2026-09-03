# Design: Estimación de tiempo en vivo durante conversión

## Technical Approach

Capacidad `estimacion-viva-conversion`: durante `HomeController.procesar()` mostrar
dos números en vivo — la **estimación por archivo** (chars × tasa del benchmark) y el
**tiempo restante auto-corregido** (promedio real × archivos restantes).

Un campo `HomeEstado.tiempoEstimado` (`String?`) preformateado → los widgets renderizan
con cero lógica. Sin benchmark → `null` → silencio total. Cálculo inline en el controller
(presentation, `dart:io` permitido); el dominio permanece puro (`estimarTiempo` se reutiliza).

## Architecture Decisions

### Decision: Composición de `tiempoEstimado`
| Opción | Tradeoff | Decisión |
|--------|----------|----------|
| Ambos valores en un campo | 2 keys o string multilinea | ✗ |
| `tiempoEstimado` = solo restante; por-archivo en `estado` | restante no lo pisa `_onProgreso`; 1 key | ✅ |

**Decisión**: `tiempoEstimado` solo lleva la línea **restante** (`restante_estimado`): es el valor
durable auto-corregido, mapea a la única key nueva, y `_onProgreso` (que sobrescribe `estado`
con "N/M segmentos") no lo pisa. La **estimación por archivo** (EVC-1) va compuesta en la línea
`estado` de ese archivo, avisada antes del primer `onProgreso` — ventana aceptable; el progreso
la reemplaza, cubriendo EVC-1 "mientras se procesa".

### Decision: `_cargarBenchmark()` — guard raíz
**Choice**: helper privado `BenchmarkResult? _cargarBenchmark()` que lee
`repositorioBenchmarkProvider`, parsea y devuelve null si no hay `benchmark_results` o está vacío.
**Alternativa**: leer el benchmark inline en cada caller.
**Rationale**: root-cause fix — un guard, dos callers (path vivo + `_mostrarEstimacion`). El path
vivo lo llama UNA vez antes del loop.

### Decision: Math del restante inline (sin use case de dominio)
**Choice**: `remainingSec = avgRealSec * filesRemaining` inline en el controller.
**Alternativa**: nuevo use case de dominio.
**Rationale**: multiplicación aritmética de wall-clock, no regla de negocio; aritmética
presentation-permitida (`dart:io/DateTime`). YAGNI: sin razón pura-matemática para un use case de una línea.

### Decision: `chars==0` y fallo de lectura silenciosos
**Choice**: `chars == 0` → skip estimación por archivo (nunca "0 s"); `leerArchivo` en try/catch →
fallo silencioso, conversión continúa, sin estimación. Cubre EVC-1 "Archivo vacío" y "Fallo de lectura".

## Data Flow

```
procesar()
  │  _cargarBenchmark() → BenchmarkResult? (null → toda la ruta viva inerte)
  │
  ├─ loop i in seleccion
  │    ├─ preleer chars (try/catch): limpiarMarkdown(leerArchivo(ruta)).length
  │    │     chars>0 y benchmark → estado = "Archivo i de n: X · ~{tiempo}"   (EVC-1)
  │    ├─ useCase.procesar(...)  (onProgreso pisa estado con "N/M segmentos")
  │    └─ tras completar: avgRealSec = elapsedSec / iProcesados
  │          si iProcesados>0 y restantes>0
  │             tiempoEstimado = restante_estimado(formatear(avgRealSec*restantes)) (EVC-2)
  │
  └─ fin/cancel → tiempoEstimado = null (EVC-4)
        │
        ▼
   widgets (barra_accion / contenido_registro / card_registro)
        if tiempoEstimado != null → render línea Text (0 lógica)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modify | `HomeEstado.tiempoEstimado`, `_cargarBenchmark()`, math vivo en `procesar()`, limpieza |
| `lib/features/convert/presentation/widgets/barra_accion.dart` | Modify | Render línea `tiempoEstimado` |
| `lib/features/convert/presentation/widgets/contenido_registro.dart` | Modify | Render línea `tiempoEstimado` |
| `lib/features/convert/presentation/screens/tablet/card_registro.dart` | Modify | Render línea `tiempoEstimado` |
| `lib/presentation/l10n/app_es.arb` | Modify | key `restante_estimado` |
| `lib/presentation/l10n/app_en.arb` | Modify | key `restante_estimado` |
| `test/presentation/controllers/home_controller_test.dart` | Modify | unit tests EVC-2/3/4 |
| `test/presentation/widgets/*_test.dart` (o inline) | New | widget test render `tiempoEstimado` |

## Interfaces / Contracts

Nuevo campo en `HomeEstado` (preformateado, 0 lógica en widgets):

```dart
// constructor
HomeEstado({ ..., this.tiempoEstimado });
final String? tiempoEstimado;   // null = silencio (sin benchmark / fuera del loop)

// copyWith
String? tiempoEstimado,        // param
tiempoEstimado: tiempoEstimado ?? this.tiempoEstimado,
```

Helper privado:

```dart
/// Benchmark guardado no vacío, o null si no hay (path vivo + estimación post).
BenchmarkResult? _cargarBenchmark() {
  final data = ref.read(repositorioBenchmarkProvider).cargar()['benchmark_results'];
  if (data is! Map<String, Object?>) return null;
  final b = BenchmarkResult.fromMap(data);
  return b.tamanios.isEmpty ? null : b;
}
```

i18n (1 key, placeholder String):
- es: `"restante_estimado": "Restante estimado: {tiempo}"`
- en: `"restante_estimado": "Estimated remaining: {tiempo}"`
- `@restante_estimado` placeholder `{"tiempo": {"type": "String"}}` en ambos.

Composición `tiempoEstimado`: `t.restante_estimado(_formatearTiempo(t, remainingSec))`.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | EVC-2 restante tras 1º | seed `benchmark_results`; `procesar` 2 archivos; `tiempoEstimado == t.restante_estimado(t.tiempo_seg(0))` |
| Unit | EVC-3 sin benchmark → null | sin `benchmark_results`; `procesar`; `tiempoEstimado` isNull |
| Unit | EVC-4 limpieza al cancelar | benchmark + `espera`; cancelar; `tiempoEstimado` isNull |
| Widget | `tiempoEstimado` renderiza | pump `ContenidoRegistro` con estado set → Text; null → no visible |

Cero tests de dominio: `estimarTiempo` ya cubierto; la aritmética `remaining*avg` se prueba
vía el efecto observable en `tiempoEstimado`. Los 18 test de home_controller existentes
quedan inertes (fake `leerArchivo`→'' y sin benchmark → `tiempoEstimado` null) y no se rompen.

## Migration / Rollout

No migration. Aditivo; rollback = revertir `tiempoEstimado`, `_cargarBenchmark`, key,
líneas de widgets. `benchmark_results` intacto.

## Open Questions

- [ ] ¿La ventana de visibilidad del por-archivo en `estado` (antes de `onProgreso`) basta para
  EVC-1, o queremos una 2ª key para persistirlo en `tiempoEstimado`? (decisión actual: basta con 1 key)
