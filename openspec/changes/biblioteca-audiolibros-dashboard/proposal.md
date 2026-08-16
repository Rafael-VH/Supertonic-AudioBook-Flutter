# Proposal: Biblioteca de audiolibros + rediseño del dashboard

## Intent

El dashboard tiene un botón inerte ("Próximamente", `onTap: null`) mientras la app ya genera audios en `carpetaBase/audio` que el usuario no puede volver a escuchar. Además, el dashboard degrada visualmente respecto de Settings (cards que ignoran el `cardTheme` global) y acumula deuda de la auditoría (W-1..W-5). Se agrega la Biblioteca de audiolibros (lista + reproducción con play/pausa) y se rediseña el dashboard como hub coherente con el tema global, cerrando los fixes de la auditoría.

## Scope

### In Scope
- **Biblioteca de audiolibros**: pantalla nueva que lista los audios de la carpeta de salida (preferencia `carpeta_out` ?? `$base/audio`), estado vacío ("nada generado todavía"), reproducción play/pausa con `reproductorAudioProvider` (just_audio), detener al salir.
- **Rediseño dashboard**: hero de bienvenida, cards consistentes con `cardTheme` global + biseles de `PaletaExt`, botón biblioteca activo (icono a definir, propongo `Icons.library_books_outlined`), fila de estado del modelo elevada a Card con CTA de descarga.
- **Fixes W-1..W-5**: redirect del gate `/modelo` devuelve al dashboard (generalizar `extra`); cards sin hardcodear color/shape; `select()`/watch movido a la Card de estado; estado "descargando" veraz + CTA descarga + refresh ≥ 48dp; l10n renombrada (sin "Modelos: " con espacio, sin `dashboard_opcion2/3`).

### Out of Scope
- Acceso directo a la pantalla de modelo desde el dashboard **excepto** el CTA de descarga de W-4 (el gate existente ya cubre la navegación forzada).
- Historial de conversiones, favoritos, borrado/renombrado de audios.
- Barra de progreso/seek de reproducción (solo play/pausa por tile).
- Exportación por capítulos: se listan los archivos generados tal cual (un libro exportado en N formatos = 1 tile, ver Approach).

## Capabilities

> No existen `openspec/specs/` previas: todo el comportamiento especificado por primera vez.

### New Capabilities
- `biblioteca-audiolibros`: listado de audios generados (agrupados por libro), reproducción play/pausa/detener, estado vacío.
- `dashboard`: hub con hero, cards con `cardTheme`/`PaletaExt`, botón biblioteca, Card de estado del modelo con CTA de descarga y verificación ≥ 48dp.

### Modified Capabilities
None (no hay specs previas; `reproductor_audio.dart` y `repositorio_archivos.dart` se extienden sin cambiar contrato existente).

## Approach

- **Dominio**: extender `RepositorioArchivos` con `listarAudios(String carpeta)` (filtra wav/flac/ogg/mp3, orden natural, reusa `_stem`/`naturalSort`); extender `ReproductorAudio` con `pausar()`, `detener()` y stream de estado de reproducción (just_audio lo expone); nuevo caso de uso `ListarAudiosGenerados` que agrupa por stem (libro) priorizando formato `mp3 > ogg > flac > wav` (peso en móvil).
- **Presentación**: `BibliotecaController` (Notifier, replica el patrón `build()` de `HomeController`: preferencia `carpeta_out` ?? `$base/audio`); `BibliotecaScreen` con tiles-Card y estado vacío; `Rutas.biblioteca` + `GoRoute`.
- **Dashboard**: refactor a widgets `_CardFuncion` (Card default del theme + `PaletaExt`) y `_CardEstadoModelo` (contiene el `ref.watch(...select(...))`, CTA descarga, progreso, refresh ≥ 48dp); hero de bienvenida; botón #3 → biblioteca.
- **Router (W-1)**: generalizar `state.extra` como ruta de origen (seleccion ya lo usa): `extra` conocido → volver a él, fallback `/home`.
- **l10n (W-5)**: `dashboard_biblioteca(_desc)`, `dashboard_procesar_sueltos`, `dashboard_modelo_*` con prefijo en el widget (sin espacio embebido). Actualizar `dashboard_screen_test.dart` (textos y estructura) y agregar tests de biblioteca (strict_tdd: red primero).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/domain/contracts/repositorio_archivos.dart` | Modified | + `listarAudios()` |
| `lib/domain/contracts/reproductor_audio.dart` | Modified | + pausa/detener/estado |
| `lib/data/repositories/repositorio_archivos.dart` | Modified | implementa `listarAudios` |
| `lib/data/repositories/reproductor_just_audio.dart` | Modified | implementa pausa/detener/estado |
| `lib/domain/use_cases/listar_audios.dart` | New | agrupación por libro + prioridad formato |
| `lib/presentation/controllers/biblioteca_controller.dart` | New | estado de biblioteca + reproducción |
| `lib/presentation/screens/biblioteca/biblioteca_screen.dart` | New | lista, play/pausa, vacío |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | Modified | hub, cards, Card de estado (W-2..W-4) |
| `lib/presentation/routing/app_router.dart` | Modified | `Rutas.biblioteca`, redirect W-1 |
| `lib/presentation/l10n/app_{es,en}.arb` | Modified | claves biblioteca + renombres W-5 |
| `test/...` (dashboard_screen_test, nuevos controller/screen tests) | Modified/New | actualizar + cubrir biblioteca |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Tocar el redirect rompe el gate de `/home` | Med | Tests de router; generalizar `extra` sin tocar la rama `home→modelo` |
| just_audio no disponible en test env | High | Fakes del contrato (`test/support/fakes.dart`), patrón existente |
| WAV grandes pesan al reproducir en móvil | Med | Prioridad de formato mp3/ogg en el caso de uso |
| Renombres l10n rompen tests existentes | High | Actualizar asserts en la misma unidad de trabajo |
| W-3 incompleto (rebuild de hero en ticks) | Med | `select()` + mover watch a la Card de estado |

## Rollback Plan

Revert del/los commits de la rama (sin migraciones ni esquema de datos persistente; `preferencias.json` no cambia de claves). El redirect vuelve al código anterior intacto.

## Dependencies

- `just_audio` (ya presente) para pausa/estado; `reproductorAudioProvider`, `carpetaBaseProvider`, `repositorioArchivosProvider` ya inyectados en `main.dart`.

## Success Criteria

- [ ] `Rutas.biblioteca` lista los libros de `carpeta_out` con play/pausa funcional y estado vacío correcto; detener al salir de la pantalla.
- [ ] Dashboard: cards usan `cardTheme` + `PaletaExt`; CTA de descarga navega a `/modelo` y el redirect devuelve al dashboard; refresh ≥ 48dp; texto veraz durante descarga; sin re-render de botones en ticks del modelo.
- [ ] l10n sin claves genéricas ni espacio embebido; `flutter analyze` limpio; suite completa verde (179 + nuevos tests de biblioteca y dashboard).
