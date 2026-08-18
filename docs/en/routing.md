# Routing

Declarative routing with go_router, including model gate and redirect logic.

## Route Definitions

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
}
```

## Navigation Flow

```
                    ┌─────────────┐
                    │   Splash    │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
    ┌─────────────────┐       ┌─────────────────┐
    │   Onboarding    │       │    Dashboard     │
    │   (first run)   │       │    (main hub)    │
    └────────┬────────┘       └────────┬────────┘
             │                         │
             └────────────┬────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Convert  │    │Biblioteca│    │ Metadata │
    └────┬─────┘    └──────────┘    │ Editor   │
         │                          └──────────┘
         │
         ▼
    ┌─────────────────┐
    │     Modelo      │ (if model not ready)
    └────────┬────────┘
             │
             └────→ back to origin
```

## Model Gate

The central redirect logic that ensures the TTS model is available before processing.

### Redirect Rules

```dart
redirect: (context, state) {
  final destino = state.matchedLocation;
  final listo = ref.read(modeloControllerProvider).listo;

  // Rule 1: Home requires model
  if (destino == Rutas.home && !listo) return Rutas.modelo;

  // Rule 2: Model → back to origin when ready
  if (destino == Rutas.modelo && listo) {
    final origen = state.extra;
    if (origen is String && _origenesValidos.contains(origen)) {
      return origen;
    }
    return Rutas.home; // fallback
  }

  return null; // no redirect
}
```

### Valid Origins

Only these routes can redirect to `/modelo`:

```dart
const _origenesValidos = {Rutas.home, Rutas.dashboard};
```

| Origin | Trigger |
|--------|---------|
| `/home` | Normal gate — user navigates to Convert |
| `/dashboard` | CTA card — "Convert files" button |

### Model Ready Listener

When model becomes ready while on `/modelo`:

```dart
ref.listen(
  modeloControllerProvider.select((s) => s.listo),
  (previo, listo) {
    if (!listo) return;
    final estado = router.routerDelegate.state;
    if (estado.matchedLocation == Rutas.modelo) {
      // Re-navigate to trigger redirect
      router.go(Rutas.modelo, extra: estado.extra);
    } else {
      // Just refresh redirects
      refresco.refrescar();
    }
  },
);
```

**Why re-navigate?** go_router only re-evaluates redirects when re-parsing the URI. An imperative `push()` doesn't change the URI, so we must `go()` to trigger the redirect.

## Route Details

### `/splash`

- **Screen**: `SplashScreen`
- **Purpose**: Initial loading, decides first-run vs normal
- **Navigation**: Auto-navigates to onboarding or dashboard

### `/onboarding`

- **Screen**: `OnboardingScreen`
- **Purpose**: 5-step guide for new users
- **Navigation**: Completes → dashboard

### `/dashboard`

- **Screen**: `DashboardScreen`
- **Purpose**: Main hub with function cards
- **Actions**: Navigate to home, biblioteca, editorMetadata, settings

### `/home`

- **Screen**: `ConvertScreen`
- **Purpose**: Batch file processing
- **Gate**: Requires model (redirects to `/modelo` if not ready)

### `/modelo`

- **Screen**: `ModeloScreen`
- **Purpose**: Model download and verification
- **Exit**: Redirects to origin when model is ready

### `/biblioteca`

- **Screen**: `BibliotecaScreen`
- **Purpose**: Listen to generated audiobooks
- **Gate**: None — reads from output folder

### `/editor-metadata`

- **Screen**: `MetadataEditorScreen`
- **Purpose**: Edit ID3 metadata of MP3 files
- **Gate**: None

### `/settings`

- **Screen**: `SettingsScreen`
- **Purpose**: App preferences
- **Gate**: None

## Imperative Navigation

Used in screens via `context.go()` or `context.push()`:

```dart
// From Dashboard
context.push(Rutas.home);
context.push(Rutas.settings);
context.push(Rutas.editorMetadata);

// From Convert
context.push(Rutas.settings);
context.push(Rutas.modelo, extra: Rutas.home);

// From Biblioteca
context.push(Rutas.home);
```

## Refresh Mechanism

`_RefrescoModelo` extends `ChangeNotifier` to force router re-evaluation:

```dart
class _RefrescoModelo extends ChangeNotifier {
  void refrescar() => notifyListeners();
}
```

Used when:
1. Model becomes ready (listener calls `refrescar()`)
2. Any state change that affects redirects

## Testing Routes

```dart
testWidgets('redirects to /modelo when model not ready', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        modeloControllerProvider.overrideWithValue(
          MockModeloController(listo: false),
        ),
      ],
      child: const MaterialApp.router.routerConfig(appRouter),
    ),
  );
  expect(find.byType(ModeloScreen), findsOneWidget);
});
```
