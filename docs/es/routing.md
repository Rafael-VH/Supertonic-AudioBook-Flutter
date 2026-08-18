# Navegación (Routing)

Flujo de navegación de la aplicación con go_router.

## Resumen

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐
│ Splash  │ ──→ │ Onboarding  │ ──→ │  Modelo     │
│ (1s)    │     │ (5 pasos)   │     │ (descarga)  │
└─────────┘     └─────────────┘     └──────┬──────┘
                                           │
                                           ▼
┌─────────────────────────────────────────────────┐
│                  Dashboard                       │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐  │
│  │ Convert  │  │Biblioteca │  │  Editor      │  │
│  │ (lotes)  │  │(escuchar) │  │  Metadatos   │  │
│  └────┬─────┘  └───────────┘  └──────────────┘  │
│       │                                          │
│       └──── Settings ◄───────────────────────    │
└─────────────────────────────────────────────────┘
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
}
```

## Configuración de rutas

El router se construye con `GoRouter` y define:

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/splash` | SplashScreen | Pantalla de carga inicial (1s) |
| `/onboarding` | OnboardingScreen | Guía de 5 pasos para nuevos usuarios |
| `/modelo` | ModeloScreen | Pantalla de descarga del modelo |
| `/dashboard` | DashboardScreen | Centro principal de la app |
| `/home` | ConvertScreen | Conversión por lotes de archivos `.md` |
| `/settings` | SettingsScreen | Preferencias de la aplicación |
| `/biblioteca` | BibliotecaScreen | Escuchar audiolibros generados |
| `/editor-metadata` | MetadataEditorScreen | Editor de metadatos ID3 |

## Flujo de Navegación Inicial

### Primera Ejecución

```
Splash → Onboarding → Modelo → Dashboard
```

### Ejecuciones Posteriores

```
Splash → Dashboard (si modelo descargado)
Splash → Modelo → Dashboard (si modelo no descargado)
```

## Model Gate

El `ModelGate` verifica si el modelo está disponible. Si no lo está, redirige a `/modelo`:

```dart
redirect: (context, state) {
  final destino = state.matchedLocation;
  final listo = ref.read(modeloControllerProvider).listo;
  if (destino == Rutas.home && !listo) return Rutas.modelo;
  if (destino == Rutas.modelo && listo) {
    final origen = state.extra;
    if (origen is String && _origenesValidos.contains(origen)) {
      return origen;
    }
    return Rutas.home;
  }
  return null;
}
```

## Dashboard Links

El Dashboard usa `GoRouter` para navegación con `push()`:

```dart
onTap: () => context.push(Rutas.home)             // Conversión por lotes
onTap: () => context.push(Rutas.biblioteca)        // Biblioteca
onTap: () => context.push(Rutas.editorMetadata)    // Editor de metadatos
```

## Configuración del Router

```dart
final router = GoRouter(
  initialLocation: Rutas.splash,
  routes: [
    GoRoute(path: Rutas.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: Rutas.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: Rutas.modelo, builder: (_, __) => const ModeloScreen()),
    GoRoute(path: Rutas.dashboard, builder: (_, __) => const DashboardScreen()),
    GoRoute(path: Rutas.home, builder: (_, __) => const ConvertScreen()),
    GoRoute(path: Rutas.biblioteca, builder: (_, __) => const BibliotecaScreen()),
    GoRoute(path: Rutas.settings, builder: (_, __) => const SettingsScreen()),
    GoRoute(path: Rutas.editorMetadata, builder: (_, __) => const MetadataEditorScreen()),
  ],
  redirect: (context, state) {
    final destino = state.matchedLocation;
    final listo = ref.read(modeloControllerProvider).listo;
    if (destino == Rutas.home && !listo) return Rutas.modelo;
    if (destino == Rutas.modelo && listo) {
      final origen = state.extra;
      if (origen is String && _origenesValidos.contains(origen)) {
        return origen;
      }
      return Rutas.home;
    }
    return null;
  },
);
```

## Tests de Navegación

Los tests de routing verifican:

1. **Splash → Onboarding**: Primera ejecución
2. **Splash → Dashboard**: Ejecuciones posteriores
3. **Model Gate**: Redirección a modelo cuando no está disponible
4. **Dashboard push**: Navegación correcta a Convert/Biblioteca/Editor
5. **Settings push**: Navegación desde cualquier pantalla

Ver `test/presentation/routing/app_router_test.dart` para tests completos.

## Decisiones de Diseño

### 1. `push()` vs `go()`

Usamos `push()` para navegación desde Dashboard porque:
- Mantiene el historial de navegación
- El botón "atrás" funciona correctamente
- Permite deep linking futuro

Usamos `go()` en el `redirect` porque:
- Redirección completa (reemplaza la pila)
- Evita que el usuario regrese a rutas no válidas

### 2. Splash Screen

La pantalla splash usa un `Future.delayed` de 1 segundo para:
- Mostrar el logo/branding de la app
- Dar tiempo para que los providers se inicialicen
- Crear una experiencia de carga más suave

### 3. Onboarding Guard

El onboarding solo se muestra en la primera ejecución:
- Se persiste en `shared_preferences` (`onboarding_completado`)
- Si el usuario ya completó el onboarding, se salta directamente a Dashboard
- Si el usuario cierra el onboarding sin completar, se marca como completado de todos modos

### 4. Settings como Ruta Separada

Settings es una ruta separada (no un dialog o bottom sheet) porque:
- Permite deep linking a settings
- Mantiene el historial de navegación
- Es consistente con el patrón de navegación del resto de la app
