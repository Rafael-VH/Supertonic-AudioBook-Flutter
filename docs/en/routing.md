# Navigation (Routing)

Application navigation flow with go_router.

## Overview

```
┌─────────┐     ┌─────────────┐     ┌──────────────────────────────────┐
│ Splash  │ ──→ │ Onboarding  │ ──→ │           Dashboard              │
│ (1.2s)  │     │ (5 steps,   │     │   NavigationBar · IndexedStack   │
└─────────┘     │  1st run)   │     │  ┌──────┬────────────┬─────────┐ │
                └─────────────┘     │  │ Home │  Library   │ Settings│ │
                                    │  └──────┴────────────┴─────────┘ │
                                    └───────┬──────────────────────────┘
                                            │ Home hub
                     ┌──────────────────────┼──────────────────────┐
                     ▼                      ▼                      ▼
               /home (Convert)      /editor-metadata         /benchmark
                     │
                     ▼
             /audio-manager (pending audios)

  Model gate: /home without model → /modelo → back to origin
```

## Route Definitions

Centralized in `lib/presentation/routing/app_router.dart`:

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

| Route | Screen | Description |
|------|----------|-------------|
| `/splash` | SplashScreen | Initial loading (min. 1.2 s), decides destination |
| `/onboarding` | OnboardingScreen | 5-step guide for new users |
| `/dashboard` | DashboardScreen | Shell with NavigationBar (3 tabs) |
| `/home` | ConvertScreen | Batch conversion of `.md` files |
| `/modelo` | ModeloScreen | Model download/verification |
| `/biblioteca` | BibliotecaScreen | Generated audiobooks |
| `/settings` | SettingsScreen | App preferences |
| `/editor-metadata` | MetadataEditorScreen | ID3 metadata editor |
| `/benchmark` | BenchmarkScreen | TTS engine benchmark |
| `/audio-manager` | AudioManagerScreen | Pending audios to save |

## Initial Navigation Flow

### First Run

```
Splash → Onboarding → Dashboard → (model gate on /home)
```

### Subsequent Runs

```
Splash → Dashboard
```

The `onboardingVisto` flag lives in `preferencias.json` (not `shared_preferences`). Completing or skipping onboarding marks it either way.

## Model Gate

If the model is not ready, `/home` redirects to `/modelo`. Once ready, it returns to the origin that requested the model (`/home` normal gate or `/dashboard` card CTA); unknown origin → fallback `/home`.

```dart
redirect: (context, state) {
  final destino = state.matchedLocation;
  final listo = ref.read(modeloControllerProvider).listo;
  if (destino == Rutas.home && !listo) return Rutas.modelo;
  if (destino == Rutas.modelo && listo) {
    final origen = state.extra;
    if (origen is String && _origenesValidos.contains(origen)) {
      return origen;                       // /home or /dashboard
    }
    return Rutas.home;                     // fallback
  }
  return null;
}
```

Valid origins are centralized:

```dart
const _origenesValidos = {Rutas.home, Rutas.dashboard};
```

### Router Refresh

go_router only re-evaluates redirects when re-parsing the URI. The router uses two complementary mechanisms when the model becomes ready:

1. **`refreshListenable`** (`_RefrescoModelo`): notifies the router to re-evaluate redirects.
2. **`ref.listen`** on `modeloControllerProvider.select((s) => s.listo)`: if the top route is `/modelo` (reached via imperative push, which does not change the URI), it re-navigates to `/modelo` with its `extra` so the redirect resolves the destination.

## Typed Extra Navigation

`/audio-manager` receives the pending audios as `extra`:

```dart
GoRoute(
  path: Rutas.audioManager,
  builder: (_, state) {
    final audios = state.extra as List<AudioPendiente>? ?? const [];
    return AudioManagerScreen(pendientes: audios);
  },
),
```

Convert calls `push(Rutas.audioManager, extra: acumulados)` after completing a batch without errors.

## push() vs go() Convention

- **`push()`**: navigation from the dashboard/hub — keeps history and the back button.
- **`go()`**: splash, onboarding and redirects — replace the stack.

## Navigation Tests

Routing tests verify:

1. **Splash → Onboarding**: first run
2. **Splash → Dashboard**: subsequent runs
3. **Model Gate**: redirect to `/modelo` and return to the correct origin
4. **Audio Manager**: receiving the pendings `extra`
5. **Dashboard tabs**: Home/Library/Settings switching

See `test/presentation/routing/app_router_test.dart`.
