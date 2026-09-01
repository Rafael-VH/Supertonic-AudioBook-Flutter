# 🔍 Auditoría Complementaria — Skills Locales (2026-09-01)

> Complemento a `audit-2026-09-01-comprehensive.md` (Buffy). Enfocada en áreas que
> esa auditoría no cubrió, aplicando las skills locales de Flutter del repo
> (`skills/`): `flutter-build-responsive-layout`, `flutter-fix-layout-issues`,
> `flutter-add-widget-test`, `flutter-add-widget-preview`,
> `flutter-add-integration-test`, `flutter-setup-localization`,
> `flutter-setup-declarative-routing`, `flutter-apply-architecture-best-practices`.
> Excluye TestMan/ArquiMan/RefactoryMan (otra tanda de auditoría).

## 1. Verificación de hallazgos previos (Buffy → realidad)

| Hallazgo de Buffy | Veredicto | Evidencia |
| --- | --- | --- |
| "Sin tests de routing" | ❌ Falso | `test/presentation/routing/app_router_test.dart` existe (198 líneas, commitado) |
| "Solo `widget_test.dart` a nivel raíz" | ❌ Falso | Suites de screens: dashboard, settings, modelo, convert, biblioteca, metadata_editor |
| "Ruta de modelo hardcodeada" | ❌ Falso | `modelo_manager.dart:96` resuelve en runtime (`getApplicationSupportDirectory()/modelo`) |
| "Sin validación de .md" | ⚠️ Débil | Existe use case `limpiar_markdown` con tests (sanitiza el contenido) |
| "Cobertura i18n baja (50/205)" | ⚠️ Matiz | Paridad de claves **264 = 264** (es/en). Lo que falta son TESTS de l10n, no traducciones |
| "Versiones fijas" | ✅ Real | `pubspec.yaml:19-20` (`flutter_riverpod 3.4.2`, `intl 0.20.2`) |
| "Logger imprime en prod" | ✅ Real | `PrintLogger` + `package:logger` sin nivel en 3 archivos de `data/convert` |

## 2. Nuevos hallazgos (lente de skills locales)

### 2.1 Responsive tablet — ⚠️ Parcial (`flutter-build-responsive-layout`)

> **Alcance de producto (decisión 2026-09-01):** la app es SOLO móvil (iOS/Android),
> incluyendo tabletas. Desktop queda fuera de alcance; el branch de memoria desktop
> (`configTts`, `main.dart:74`) queda solo como ruta de dev en Windows.

- ✅ **Convert** tiene breakpoint: `convert_screen.dart:56` (`MediaQuery.sizeOf >= 900` →
  paneles lado a lado). Correcto según la skill (usa tamaño de ventana, no orientación ni
  hardware). Cubre tablets en landscape.
- ⚠️ **Biblioteca**: lista de una columna que estira en tablet. Debería usar grid adaptativo
  (`GridView.builder` + `SliverGridDelegateWithMaxCrossAxisExtent`) para mostrar más
  columnas según ancho disponible.
- ⚠️ **Benchmark**: tabla fija de 6 columnas (commit `75d981d`) — riesgo de overflow en
  tablet **portrait** (ancho < 900). Requiere verificación de fit/scroll.
- ⚠️ **Dashboard y settings**: mobile-first; verificar en tablet portrait que no queden
  estirados de forma incómoda (máx. `ConstrainedBox` si hace falta).
- ✅ No hay lock de orientación (`SystemChrome.setPreferredOrientations` ausente) — cumple
  la skill y los requisitos de Android large-format (portrait + landscape).

**Riesgo**: Medio (visual/UX en tabletas, no funcional).

### 2.2 Layout errors — ✅ Sin patrones de riesgo estáticos (`flutter-fix-layout-issues`)

- Scroll vertical bien resuelto: `SingleChildScrollView` en los 4 cuerpos (tablet x2, móvil, home). No se detectan `ListView` sin constraint vertical estáticos.

**Riesgo**: Bajo. Requiere validación runtime (fdb) para confirmar overflow en pantallas chicas.

### 2.3 Widget tests — ⚠️ Gaps en features recientes (`flutter-add-widget-test`)

| Screen | Widget test | Nota |
| --- | --- | --- |
| `convert_screen` + tablets/móvil | ✅ `convert_screen_test` | Bien cubierto |
| `dashboard_screen` | ✅ | |
| `settings_screen` / `modelo_screen` / `biblioteca_screen` | ✅ | |
| `metadata_editor_screen` | ✅ | |
| `benchmark_screen` | ❌ | Solo `benchmark_controller_test`; la **tabla** (cambio reciente) sin test de widget |
| `audio_manager_screen` + `memory_warning_dialog` | ❌ | Feature nueva; tests solo de use cases (`guardar_audio`, `limpiar_temporales`, `estimar_memoria`) |
| `onboarding_screen` / `splash_screen` | ❌ | Splash tiene timer 1.2s (testeable con fake async) |
| `home_screen` | ⚠️ | Solo `home_movil_diag_test` (diagnóstico, no suite) |

**Riesgo**: Medio — las 2 features más recientes (benchmark, audio_manager) no tienen tests de UI.

### 2.4 Widget previews — ❌ Ausente (`flutter-add-widget-preview`)

- **Cero archivos `previews.dart`** en el repo. El proyecto no usa el sistema de previews interactivos. Dev feedback lento para el rediseño móvil/tablet en curso.

**Riesgo**: Bajo (productividad, no correctitud).

### 2.5 Integration tests — ❌ Ausente (`flutter-add-integration-test`)

- **No existe `integration_test/`** — coincide con `openspec/config.yaml` ("e2e: no disponible").
- El flujo crítico (md → limpieza → TTS → WAV → export) solo se prueba con mocks de FFmpeg.

**Riesgo**: Medio — el error CRITICAL histórico (export sin `-y`, plan-correcciones Fase 1) se habría detectado antes con un E2E real.

### 2.6 Localización — ✅ Config completa; ❌ sin tests (`flutter-setup-localization`)

- Config correcta: `l10n.yaml`, `generate: true`, `flutter_localizations`, `supportedLocales [es, en]`.
- Paridad de claves **264 = 264** (verificado por diff de `ConvertFrom-Json`): no faltan traducciones en inglés.
- **No existe `test/presentation/l10n/`** → las cadenas traducidas no tienen tests (de ahí el 50/205 "de cobertura" que reportó Buffy: es cobertura de *ejecución* en tests).

**Riesgo**: Bajo.

### 2.7 Routing — ✅ Correcto (`flutter-setup-declarative-routing`)

- `MaterialApp.router` con `go_router` 17.5, rutas declaradas en `app_router.dart`, con tests (`app_router_test.dart`) y redirect del gate de modelo.
- Sin deep-links/web paths — coherente con target móvil/desktop local.

**Riesgo**: Ninguno.

### 2.8 Arquitectura Flutter — ✅ Alineado (`flutter-apply-architecture-best-practices`)

- UI/Logic/Data por feature: controllers Riverpod (≈ViewModels), use cases (lógica), repositorios `data/` (datos). Equivalente funcional del patrón MVVM que propone la skill, con Riverpod en lugar de `ChangeNotifier`.
- `dart:convert` y `dart:io` confinados a `data/` (verificado por grep) — las sutilezas de presentación (`Platform.pathSeparator`) son convención documentada (`providers.dart:29`).

**Riesgo**: Ninguno.

### 2.9 Skills N/A

- `supabase` / `supabase-postgres-best-practices`: el proyecto no usa Supabase. `flutter-use-http-package`: usa `dio`, no `http`. `flutter-implement-json-serialization`: el `jsonDecode` vive solo en `data/` (correcto).

## 3. Priorización

| # | Hallazgo | Severidad | Dónde |
| --- | --- | --- | --- |
| C1 | Widget tests faltantes (benchmark tabla, audio_manager, onboarding, splash) | 🟠 Media | `test/features/...`, `test/presentation/screens/` |
| C2 | Responsive tablet parcial (biblioteca monocolumna, benchmark tabla fija) | 🟠 Media | `lib/features/*/presentation/screens/` |
| C3 | Sin integration tests (E2E md→audio) | 🟠 Media | repo root |
| C4 | Sin widget previews | 🟡 Baja | `lib/features/*/presentation/` |
| C5 | Sin tests de l10n | 🟡 Baja | `test/presentation/l10n/` |

## 4. Conclusión

La base de Buffy es sólida en arquitectura/seguridad. Este complemento agrega la
dimensión **UI + testing de features nuevas** que faltaba: los huecos reales están
en cobertura de widget tests de las features recientes (benchmark, audio_manager)
y en la adaptación **tablet** (grid en biblioteca, fit de la tabla de benchmark).
No hay hallazgos bloqueantes nuevos.