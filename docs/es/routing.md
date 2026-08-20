# Navegación (Routing)

Flujo de navegación de la aplicación con go_router.

## Resumen

```
┌─────────┐     ┌─────────────┐     ┌──────────────────────────────────┐
│ Splash  │ ──→ │ Onboarding  │ ──→ │           Dashboard              │
│ (1.2s)  │     │ (5 pasos,   │     │   NavigationBar · IndexedStack   │
└─────────┘     │  1ª vez)    │     │  ┌──────┬────────────┬─────────┐ │
                └─────────────┘     │  │ Home │ Biblioteca │ Settings│ │
                                    │  └──────┴────────────┴─────────┘ │
                                    └───────┬──────────────────────────┘
                                            │ hub Home
                     ┌──────────────────────┼──────────────────────┐
                     ▼                      ▼                      ▼
               /home (Convert)      /editor-metadata         /benchmark
                     │
                     ▼
             /audio-manager (audios pendientes)

  Gate del modelo: /home sin modelo → /modelo → vuelve al origen
```

## Definición de Rutas

Centralizado en `lib/presentation/routing/app_router.dart`:

```dart
abstract final class Rutas {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const home = '/home';           // → ConvertScreen
  static const modelo = '/modelo';
  static const settings = '/settings';
  static const biblioteca = '/biblioteca';
  static const editorMetadata = '/editor-metadata';
  static const benchmark = '/benchmark';
  static const audioManager = '/audio-manager';
}
```

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/splash` | SplashScreen | Carga inicial (mín. 1.2 s), decide destino |
| `/onboarding` | OnboardingScreen | Guía de 5 pasos para nuevos usuarios |
| `/dashboard` | DashboardScreen | Shell con NavigationBar (3 tabs) |
| `/home` | ConvertScreen | Conversión por lotes de archivos `.md` |
| `/modelo` | ModeloScreen | Descarga/verificación del modelo |
| `/biblioteca` | BibliotecaScreen | Audiolibros generados |
| `/settings` | SettingsScreen | Preferencias de la aplicación |
| `/editor-metadata` | MetadataEditorScreen | Editor de metadatos ID3 |
| `/benchmark` | BenchmarkScreen | Benchmark del motor TTS |
| `/audio-manager` | AudioManagerScreen | Audios pendientes de guardar |

## Flujo de Navegación Inicial

### Primera Ejecución

```
Splash → Onboarding → Dashboard → (gate del modelo en /home)
```

### Ejecuciones Posteriores

```
Splash → Dashboard
```

El flag `onboardingVisto` vive en `preferencias.json` (no en `shared_preferences`). Completar o saltar el onboarding lo marca en ambos casos.

## Model Gate

Si el modelo no está listo, `/home` redirige a `/modelo`. Al quedar listo, vuelve al origen que pidió el modelo (`/home` gate normal o `/dashboard` CTA de la card); origen desconocido → fallback `/home`.

```dart
redirect: (context, state) {
  final destino = state.matchedLocation;
  final listo = ref.read(modeloControllerProvider).listo;
  if (destino == Rutas.home && !listo) return Rutas.modelo;
  if (destino == Rutas.modelo && listo) {
    final origen = state.extra;
    if (origen is String && _origenesValidos.contains(origen)) {
      return origen;                       // /home o /dashboard
    }
    return Rutas.home;                     // fallback
  }
  return null;
}
```

Los orígenes válidos están centralizados:

```dart
const _origenesValidos = {Rutas.home, Rutas.dashboard};
```

### Refresco del Router

go_router solo re-evalúa redirects al re-parsear la URI. El router usa dos mecanismos complementarios cuando el modelo queda listo:

1. **`refreshListenable`** (`_RefrescoModelo`): notifica al router para re-evaluar redirects.
2. **`ref.listen`** en `modeloControllerProvider.select((s) => s.listo)`: si la ruta tope es `/modelo` (llegada por push imperativo, que no cambia la URI), re-navega a `/modelo` con su `extra` para que el redirect resuelva el destino.

## Navegación con Extra Tipado

`/audio-manager` recibe los audios pendientes como `extra`:

```dart
GoRoute(
  path: Rutas.audioManager,
  builder: (_, state) {
    final audios = state.extra as List<AudioPendiente>? ?? const [];
    return AudioManagerScreen(pendientes: audios);
  },
),
```

Convert hace `push(Rutas.audioManager, extra: acumulados)` al completar un lote sin errores.

## Convención push() vs go()

- **`push()`**: navegación desde el dashboard/hub — mantiene historial y botón atrás.
- **`go()`**: splash, onboarding y redirects — reemplazan la pila.

## Tests de Navegación

Los tests de routing verifican:

1. **Splash → Onboarding**: primera ejecución
2. **Splash → Dashboard**: ejecuciones posteriores
3. **Model Gate**: redirección a `/modelo` y regreso al origen correcto
4. **Audio Manager**: recepción del `extra` con pendientes
5. **Dashboard tabs**: alternancia Home/Biblioteca/Settings

Ver `test/presentation/routing/app_router_test.dart`.
