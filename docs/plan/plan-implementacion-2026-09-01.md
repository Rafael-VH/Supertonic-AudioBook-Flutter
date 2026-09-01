# 📋 Plan de Implementación — Post-Auditorías (2026-09-01)

> Fuentes:
> - `docs/audits/audit-2026-09-01-comprehensive.md` (Buffy)
> - `docs/audits/audit-2026-09-01-complementaria-local-skills.md` (complemento con skills locales)
>
> Alcance: hallazgos **confirmados** de ambas. Los hallazgos falsos de Buffy
> (routing tests, widget tests, ruta de modelo, validación .md) **no** se planifican.
>
> **Alcance de producto (decisión 2026-09-01):** SOLO móvil (iOS/Android),
> **incluyendo tabletas**. Desktop fuera de alcance: no se optimiza responsive de
> escritorio; el branch de memoria desktop de `configTts` queda como ruta de dev
> (Windows) sin tocar.
>
> Convenciones: TDD estricto (`openspec/config.yaml`), conventional commits,
> commits por unidad de trabajo (`work-unit-commits`), `flutter analyze` + tests
> verdes al cierre de cada unidad.

## Hallazgos confirmados (con evidencia)

| ID | Hallazgo | Fuente | Severidad |
| --- | --- | --- | --- |
| H1 | Versiones fijas `flutter_riverpod 3.4.2`, `intl 0.20.2` | Buffy | 🟡 Baja |
| H2 | Logger imprime consola en release (`PrintLogger` + `package:logger` sin nivel) | Buffy | 🟡 Baja |
| H3 | Sin tests de l10n (paridad 264=264 OK, pero 0 tests) | Buffy + Local | 🟡 Baja |
| H4 | Widget tests faltantes: benchmark table, audio_manager (+memory_warning), onboarding, splash | Local | 🟠 Media |
| H5 | Tablet responsive parcial: biblioteca monocolumna, tabla benchmark sin fit en portrait | Local | 🟠 Media |
| H6 | Sin integration tests (E2E md→audio) | Local | 🟠 Media |
| H7 | `dart:io` en presentation — **no-cambio** (decisión de arquitectura, ver U0) | Buffy | ⚪ Cerrado |
| H8 | Propuesta openspec obsoleta `fix-clean-architecture-criticals` (ya aplicada en `22030d4`) | Contexto | 🟡 Baja |

## U0 — Decisión de arquitectura: `dart:io` en presentation (cerrado)

**Decisión: NO-CAMBIO**, documentada. Evidencia:

- La Regla de Dependencia (arquiman / Clean Architecture) prohíbe `dart:io` en
  **domain**, no en presentation. Domain está 100% puro (verificado por grep).
- El único uso real es `Platform.pathSeparator` (4 controllers) y `Platform.isAndroid`
  (1 controller) — constantes de plataforma, no infraestructura.
- Convención documentada en `providers.dart:29`: *"la presentación puede usar `dart:io`"*.
- Si algún día hace falta I/O real, el escape hatch ya existe: `RepositorioArchivos.pathSeparator`
  (`repositorio_archivos.dart:86`).

**Acción**: registrar esta decisión en el ADR/README de docs (1 línea) y cerrar el hallazgo U4.

## Fases de implementación

### Fase A — Cambios mínimos de higiene (riesgo ~0)

**A1 — Version ranges** (H1)
- Archivo: `pubspec.yaml` (L19-20): `flutter_riverpod: ^3.4.2`, `intl: ^0.20.2`
- Verificación: `flutter pub get` → `flutter analyze` → `flutter test` (suite completa)
- Commit: `chore(deps): use caret ranges for riverpod and intl`

**A2 — Logger condicional a release** (H2)
- Archivos: `lib/shared/data/repositories/print_logger.dart` (+ 3 usos `package:logger` en
  `data/convert`: `motor_tts.dart`, `model_loader.dart`, `text_to_speech.dart`)
- Fix: guard `kDebugMode` en `PrintLogger`; nivel `Level.warning` (o no-op) en release
  para los `logger` de data. **mantener** logs de error siempre visibles en debug.
- Tests: unit del PrintLogger que verifique silencio en release (inyectar flag booleano).
- Commit: `fix(log): silence console logs in release builds`

**A3 — Archivar propuesta openspec obsoleta** (H8)
- Flujo: `sdd-verify` (estado real) → `sdd-archive` para `fix-clean-architecture-criticals`
- Commit: `chore(sdd): archive superseded clean-architecture proposal`

### Fase B — Testing (Media: cubre H3, H4)

**B1 — Tests de l10n** (H3) — skill `flutter-setup-localization` como referencia
- Nuevo: `test/presentation/l10n/app_localizations_test.dart`
- Cubrir: paridad es/en de claves usadas por la UI, `supportedLocales`, delegates en `app.dart`
- Commit: `test(l10n): cover es/en localization keys`

**B2 — Widget tests de features nuevas** (H4) — skill `flutter-add-widget-test`
- `benchmark_screen_test.dart`: tabla fija de 6 filas (regresión del `75d981d`), botón ejecutar
- `audio_manager_screen_test.dart` + `memory_warning_dialog_test.dart`: lista de pendientes,
  guardar/cancelar, diálogo de advertencia de memoria
- `onboarding_screen_test.dart`, `splash_screen_test.dart`: navegación y timer (fake async)
- Commit por screen: `test(feature): add widget tests for <screen>`

**B3 — Primer integration test E2E** (H6) — skill `flutter-add-integration-test`
- Setup: `integration_test/` + rutina md→limpieza→WAV→export (con fake de FFmpeg si sigue
  indisponible, o `ffmpeg_kit` mockeado)
- Gate: habilita el `e2e` de `openspec/config.yaml`
- Commit: `test(e2e): add md-to-audio end-to-end flow`

### Fase C — Tablet responsive (H5) — skill `flutter-build-responsive-layout`

**C1 — Grid adaptativo en biblioteca**
- `biblioteca_screen.dart`: reemplazar lista de una columna por `GridView.builder` con
  `SliverGridDelegateWithMaxCrossAxisExtent` (más columnas en tablet, 1-2 en móvil).
- Verificación: widget test con ancho de tablet (p.ej. `tester.view.physicalSize` 1024x768)
  que verifique múltiples columnas; tests existentes verdes.

**C2 — Tabla benchmark con fit en tablet portrait**
- `benchmark_screen.dart`: envolver la tabla fija de 6 columnas en scroll horizontal
  (`SingleChildScrollView(scrollDirection: horizontal)`) o compactar columnas; verificar
  en 800px de ancho (tablet portrait) que no haya overflow.
- Verificación: widget test de la tabla en ancho tablet + `flutter-fix-layout-issues`
  (ausencia de RenderFlex overflow).

**C3 — Verificación convert + dashboard/settings en tablet**
- `convert_screen.dart`: el breakpoint 900 ya cubre tablets landscape (paneles lado a
  lado) — confirmar comportamiento, sin cambios salvo evidencia de problema.
- `dashboard_screen.dart` / `settings_screen.dart`: revisar stretch en tablet portrait
  (agregar `ConstrainedBox(maxWidth)` solo si molesta).
- Verificación: manual en tablet portrait/landscape + tests verdes.
- Commit(s): `feat(ui): adapt library grid and benchmark table for tablets`

### Diferido (explotado, no hacer ahora)

- Widget previews (`flutter-add-widget-preview`): cero impacto funcional → cuando toque
  rediseñar, se agregan con las skills del repo
- Responsive desktop: fuera de alcance por decisión de producto (2026-09-01)
- Cache / paralelo / streaming (Buffy): features de rendimiento, no deuda → requieren
  cambio SDD propio (`sdd-new`) si se piden
- Supabase skills: N/A (no usa Supabase)

## Orden de ejecución

```
Fase A (A1→A2→A3) → Fase B (B1→B2→B3) → Fase C (C1→C2→C3) → cierre
```

Reglas:
1. Cada unidad: `flutter analyze` + tests verdes antes del commit
2. Una unidad por commit, conventional commit, sin atribución AI
3. Si una unidad supera ~400 líneas, se parte en chained PRs (skill `chained-pr`)
4. Al final: re-correr `flutter test` completo y `flutter analyze` para el cierre

<!--
Estado: formulado por el orquestador tras las 2 auditorías. Aprobación pendiente del usuario.
-->