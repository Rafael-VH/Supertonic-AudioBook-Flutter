# Tasks: Biblioteca de audiolibros + rediseño del dashboard

## Review Workload Forecast

| Campo | Valor |
|-------|-------|
| Líneas cambiadas estimadas | ~1.850 (rango 1.600–2.000) |
| 400-line budget risk | High (nominal: el usuario fijó review_budget_lines SIN LÍMITE) |
| Chained PRs recommended | Yes |
| Split sugerido | 6 PRs: WO-1 → WO-2 → WO-3 → WO-4a → WO-4b → WO-5 |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Work Units Sugeridas

| Unit | Goal | PR |
|------|------|----|
| WO-1 | Contratos extendidos + impls data + fakes al día + use case | PR 1 |
| WO-2 | BibliotecaController (toggle, error, dispose) | PR 2 |
| WO-3 | BibliotecaScreen + ruta /biblioteca + claves `biblioteca_*` | PR 3 |
| WO-4a | Dashboard: hero + cards + grid + renombres l10n de cards | PR 4 |
| WO-4b | Dashboard: Card de estado del modelo (CTA/progreso/refresh/DASH-7) | PR 5 |
| WO-5 | Router: redirect generalizado W-1 + `app_router_test.dart` | PR 6 |

## Cobertura de Specs

| Spec | WOs |
|------|-----|
| BIB-1 listar audios | WO-1 |
| BIB-2 agrupar/prioridad | WO-1 |
| BIB-3 play/pausa/reanudar/detener | WO-2 (lógica) + WO-3 (tile) |
| BIB-4 estado vacío | WO-3 |
| BIB-5 error reproducción | WO-2 (idle+error) + WO-3 (SnackBar) |
| BIB-6 capas limpias | WO-1 (dominio) + WO-2/3 (sin just_audio en presentation) |
| DASH-1 botón biblioteca | WO-3 (ruta) + WO-4a (card activa) |
| DASH-2 claves descriptivas | WO-4a (opcion2/3) + WO-4b (`modelos` sin ": ") |
| DASH-3 cardTheme + PaletaExt | WO-4a |
| DASH-4 redirect a origen | WO-4b (CTA con extra) + WO-5 (redirect) |
| DASH-5 estado veraz | WO-4b |
| DASH-6 CTA + refresh 48dp | WO-4b |
| DASH-7 rebuilds aislados | WO-4b |
| DASH-8 hero | WO-4a |
| DASH-9 grid responsive | WO-4a |
| DASH-10 accesibilidad | WO-3 (tooltips) + WO-4b (refresh ≥48) |

## Decisiones de Ruptura (arreglos donde rompen)

- **Fakes/stubs** (`RepositorioArchivosFake`, `RepositorioArchivosFalso`, `_ArchivosVacios`, `_FakeRepositorio`): se acomodan DENTRO de WO-1, en el mismo commit que el cambio de contrato — un método nuevo rompe la compilación de los 4 sitios que implementan el abstract; un WO separado dejaría un commit que no compila.
- **Renombres l10n**: van junto al widget que consume la clave (WO-4a: `dashboard_opcion2/3`; WO-4b: `dashboard_modelos`) — `gen-l10n` regenera getters y rompe la compilación hasta renombrar el widget.
- **`dashboard_screen_test.dart`**: los asserts `'Modelos: …'` sobreviven (el widget compone el mismo string); se actualiza por estructura en WO-4a/4b (incluye harness router para navegación).
- **`widget_test.dart`**: solo recibe el stub de WO-1; los textos literales sobreviven (los valores es/en de las claves que usa no cambian).
- **openspec**: los specs viven en el change dir hasta archive; en apply solo se marcan los checkboxes de este archivo.

## WO-1 — Dominio + data + fakes (~370 líneas)

**Objetivo**: contratos extendidos e implementados; agrupación por libro en dominio (D1/D2/BIB-1/BIB-2/BIB-6); suite compila y verde.

- [x] WO-1.1 RED: `test/domain/use_cases/listar_audios_generados_test.dart` — BIB-2: 1 stem → 1 libro, prioridad mp3>ogg>flac>wav, solo formato pesado, orden — con `RepositorioArchivosFake`.
- [x] WO-1.2 RED: grupo `listarAudios` en `test/data/repositories/repositorio_archivos_test.dart` — BIB-1: filtro extensiones case-insensitive, orden natural, carpeta inexistente → `[]` — con temp dir real.
- [x] WO-1.3 GREEN: `lib/domain/contracts/repositorio_archivos.dart` (+`List<String> listarAudios(String)`); `lib/domain/contracts/reproductor_audio.dart` (+enum `EstadoReproduccion`, `pausar/reanudar/detener`, `Stream<EstadoReproduccion> estado`).
- [x] WO-1.4 GREEN: `lib/domain/entities/libro_generado.dart` (nuevo, `rutaPrioritaria`) + `lib/domain/use_cases/listar_audios_generados.dart` (nuevo, port de `_stem` sin `dart:io`).
- [x] WO-1.5 GREEN: `lib/data/repositories/repositorio_archivos.dart` (impl `listarAudios`, reusa `naturalSortKey`/`_stem`); `lib/data/repositories/reproductor_just_audio.dart` (estado vía `playerStateStream`); `lib/presentation/controllers/providers.dart` (+`listarAudiosProvider`).
- [x] WO-1.6 GREEN (mismo commit que WO-1.3): `test/support/fakes.dart` (`RepositorioArchivosFake.listarAudios`, `ReproductorFake` con `StreamController` + flags `pausado/detenido/reanudado`); stubs `listarAudios` en `test/presentation/controllers/providers_test.dart`, `test/widget_test.dart`, `test/domain/use_cases/procesar_archivo_integration_test.dart`.
- [x] Done: `flutter test` verde + `flutter analyze` limpio.

## WO-2 — BibliotecaController (~350 líneas)

**Objetivo**: estado de biblioteca con toggle play/pausa/reanudar, cambio de tile, error → idle y detener al salir (D3/BIB-3/BIB-5).

- [x] WO-2.1 RED: `test/presentation/controllers/biblioteca_controller_test.dart` — build `carpeta_out`/fallback; toggle pausa→reanuda; cambio de tile; error de `reproducir` → idle+error; dispose cancela sub y llama `detener`.
- [x] WO-2.2 GREEN: `lib/presentation/controllers/biblioteca_controller.dart` (nuevo: `BibliotecaEstado` + copyWith, `BibliotecaController`, `bibliotecaControllerProvider`; `ref.listen` del stream; `ref.onDispose` cancela sub + `detener`).
- [x] Done: tests verdes + analyze limpio + grep sin `just_audio` en `lib/presentation` (BIB-6).

## WO-3 — BibliotecaScreen + ruta + claves biblioteca_* (~310 líneas)

**Objetivo**: pantalla lista/vacío/error con reproducción por tile; ruta `/biblioteca` accesible (BIB-4/DASH-1-ruta).

- [x] WO-3.1 RED: `test/presentation/screens/biblioteca_screen_test.dart` — lista con tiles; vacío + acción → `/home`; iconos play/pausa por tile; error en SnackBar; tooltips ≥48.
- [x] WO-3.2 GREEN: `lib/presentation/screens/biblioteca/biblioteca_screen.dart` (nuevo, patrón seleccion: `ref.listen` error, `ListView.builder` de `Card(ListTile)`, estado vacío con acción).
- [x] WO-3.3 GREEN: `lib/presentation/routing/app_router.dart` (+`Rutas.biblioteca` + `GoRoute`); claves `biblioteca_*` en `lib/presentation/l10n/app_es.arb` y `app_en.arb` (gen-l10n en el commit).
- [x] Done: tests verdes + analyze limpio.

## WO-4a — Dashboard: hero + cards + grid (~350 líneas)

**Objetivo**: dashboard con hero, cards del cardTheme + `PaletaExt` (Biblioteca activa), grid responsive y renombres l10n de cards (DASH-1/2/3/8/9).

- [x] WO-4a.1 RED: en `test/presentation/screens/dashboard_screen_test.dart` (estructura + harness router): hero visible (DASH-8); card Biblioteca navega a `/biblioteca` (DASH-1); grid 2 col@800dp / 1 col@400dp (DASH-9); cards heredan cardTheme sin override local (DASH-3).
- [x] WO-4a.2 GREEN: `lib/presentation/screens/dashboard/dashboard_screen.dart` — `_BotonFuncion`→`_CardFuncion` sin `color`/`shape` propios + acentos `PaletaExt`; card #3 `Icons.library_books_outlined` → `context.push(Rutas.biblioteca)`; hero título+subtítulo; `LayoutBuilder` + `GridView.count`.
- [x] WO-4a.3 GREEN: ARB es/en — renombrar `dashboard_opcion2/3(_desc)` → `dashboard_procesar_sueltos(_desc)`/`dashboard_biblioteca(_desc)`; +`dashboard_bienvenida_sub`; renombrar el widget en el mismo commit (gen-l10n).
- [x] Done: tests verdes + analyze limpio.

## WO-4b — Dashboard: Card de estado del modelo (~290 líneas)

**Objetivo**: `_CardEstadoModelo` con watch aislado, CTA descarga, progreso veraz, refresh ≥48dp, texto compuesto sin espacio embebido (DASH-5/6/7/10).

- [x] WO-4b.1 RED: en `dashboard_screen_test.dart` — progreso durante descarga sin "sin descargar" (DASH-5); error → mensaje + CTA disponible (DASH-5); CTA navega a `/modelo` con extra y desaparece descargando (DASH-6); refresh ≥48×48 vía `tester.getSize` (DASH-6/10); contador de builds: ticks no reconstruyen hero ni cards (DASH-7).
- [x] WO-4b.2 GREEN: `lib/presentation/screens/dashboard/dashboard_screen.dart` — `_FilaEstadoModelo`→`_CardEstadoModelo` `ConsumerWidget`; `DashboardScreen` deja de watch `modeloControllerProvider`; CTA `context.push(Rutas.modelo, extra: Rutas.dashboard)`; `LinearProgressIndicator` + `modelo_progreso`; refresh `BoxConstraints(minWidth: 48, minHeight: 48)`; texto `'${t.dashboard_modelos}: $estadoTexto'`.
- [x] WO-4b.3 GREEN: ARB es/en — `dashboard_modelos` → "Modelos" (sin ": "), +`dashboard_modelo_descargar` (mismo commit que el widget).
- [x] Done: tests verdes + analyze limpio.

## WO-5 — Router: redirect generalizado (~180 líneas)

**Objetivo**: el gate de `/modelo` devuelve al origen conocido vía `state.extra` (whitelist), fallback `/home`, sin regresión (D5/DASH-4/W-1).

- [ ] WO-5.1 RED: `test/presentation/routing/app_router_test.dart` (nuevo, GoRouter real con overrides) — gate `home→modelo` intacto sin extra; extra `dashboard`/`seleccion` → vuelve al origen; extra inválido → `/home`; `/biblioteca` renderiza la screen.
- [ ] WO-5.2 GREEN: `lib/presentation/routing/app_router.dart` — `_origenesValidos = {Rutas.home, Rutas.dashboard, Rutas.seleccion}`; `state.extra is String && en whitelist → extra`, fallback `/home`.
- [ ] Done: tests verdes + analyze limpio; escenario DASH-4 completo (tap CTA de WO-4b → vuelve al dashboard).
