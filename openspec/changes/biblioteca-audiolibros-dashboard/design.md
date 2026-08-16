# Design: Biblioteca de audiolibros + rediseño del dashboard

## Technical Approach

Se extienden los contratos de dominio (sin romper los existentes), se agrega un caso de uso puro que agrupa por stem y prioriza formato, y la UI (controller + screen) consume solo contratos — nunca `just_audio`. El dashboard se refactoriza a `_CardFuncion`/`_CardEstadoModelo` (cards del `cardTheme` global + acentos `PaletaExt`), el watch del modelo se aísla en la Card de estado (W-3), el redirect se generaliza por `state.extra` (W-1) y la l10n se renombra (W-5). Verificado en código: los audios generados se escriben como `$carpetaOut/${titulo}.$formato` (ProcesarArchivo, `rutaBase` = `archivo.titulo`), o sea stem = nombre sin última extensión, **sin** sufijos `_M1_`/`_ES` (esos son voces/idiomas; la muestra de voz va a temp, nunca a `carpeta_out`).

## Architecture Decisions

| # | Decisión | Alternativas | Rationale |
|---|----------|--------------|-----------|
| D1 | `listarAudios(String) → List<String>` (rutas completas, orden natural) | `List<Archivo>` | `Archivo` es la entidad ".md por convertir"; reusarla para audio mezcla semántica. El caso de uso deriva nombre/stem puro (misma lógica que `Archivo.nombre/titulo`). |
| D2 | Contrato `ReproductorAudio`: `pausar()`, `reanudar()`, `detener()`, `Stream<EstadoReproduccion> estado` | Solo play/pausa sin stream | BIB-5 (error) y el fin natural del audio (`completed`) exigen notificar a la UI; sin stream el tile quedaría con icono pausa eterno. |
| D3 | `BibliotecaController` sin estado `cargando` (carga síncrona en `build()`) | Estado async con spinner | Paridad con `HomeController` (todo síncrono en `build()`); el listado del FS ya es síncrono (`listSync`). Estado cubre lista/vacío/error/reproducción. |
| D4 | `LibroGenerado` guarda `titulo + archivos + formatoPrioritario`; orden preservado del repo (primer encuentro por stem) | Re-ordenar títulos en el use case | `naturalSortKey(nombre)` ordena por stem igual que por nombre (la extensión solo desempata intra-stem): el orden del repo ya es el orden natural de títulos. |
| D5 | Redirect W-1 con whitelist `{/home, /dashboard, /seleccion}` | Cualquier String de `extra` | Un `extra` arbitrario rompería go_router; whitelist explícita y testeable, sin tocar la rama `home→modelo` del gate. |
| D6 | `_CardEstadoModelo` como `ConsumerWidget` con su propio `ref.watch(...select(...))` | Watch del modelo en `DashboardScreen` (actual) | W-3/DASH-7: los ticks no marcan el elemento del dashboard → hero y cards no se reconstruyen. |
| D7 | CTA de descarga usa `context.push(Rutas.modelo, extra: Rutas.dashboard)` | CTA que dispara `descargar()` directo | W-4/DASH-4: el progreso veraz ya vive en `ModeloScreen`; el CTA solo navega (con origen para el redirect). |

## Data Flow

```
BibliotecaScreen ──watch──► bibliotecaControllerProvider (Notifier)
                                 │ build(): prefs.carpeta_out ?? $base/audio
                                 │          listarAudiosProvider.ejecutar(carpeta)
                                 │          reproductor.estado.listen(_onEstado)
                                 ▼
                        ListarAudiosGenerados (domain, puro)
                                 │ List<LibroGenerado> (stem + prioridad mp3>ogg>flac>wav)
                                 ▼
                        RepositorioArchivos.listarAudios(carpeta) → List<String>
                                 │           │
                    RepositorioArchivosLocal      ReproductorAudio (contrato)
                    (filtra wav/flac/ogg/mp3,      reproducir/pausar/reanudar/detener/estado
                     naturalSort)                        │
                                              ReproductorJustAudio (just_audio)
```

## File Changes

| Archivo | Acción | Descripción |
|---------|--------|-------------|
| `lib/domain/contracts/repositorio_archivos.dart` | Modificar | + `List<String> listarAudios(String carpeta)` |
| `lib/domain/contracts/reproductor_audio.dart` | Modificar | + `pausar()`, `reanudar()`, `detener()`, `estado` stream, enum `EstadoReproduccion` |
| `lib/domain/entities/libro_generado.dart` | Crear | `LibroGenerado(titulo, archivos, formatoPrioritario)` + getter `rutaPrioritaria` |
| `lib/domain/use_cases/listar_audios_generados.dart` | Crear | Agrupa por stem, prioridad `mp3 > ogg > flac > wav` |
| `lib/data/repositories/repositorio_archivos.dart` | Modificar | Implementa `listarAudios` (reusa `_stem` + `naturalSortKey`, como `listarArchivosMd`) |
| `lib/data/repositories/reproductor_just_audio.dart` | Modificar | Implementa pausa/detención/estado mapeando `playerStateStream` |
| `lib/presentation/controllers/providers.dart` | Modificar | + `listarAudiosProvider` |
| `lib/presentation/controllers/biblioteca_controller.dart` | Crear | `BibliotecaEstado` + `BibliotecaController` + `bibliotecaControllerProvider` |
| `lib/presentation/screens/biblioteca/biblioteca_screen.dart` | Crear | Lista, play/pausa, vacío, error |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | Modificar | Hero, `_CardFuncion`, `_CardEstadoModelo`, grid, CTA |
| `lib/presentation/routing/app_router.dart` | Modificar | + `Rutas.biblioteca` + `GoRoute` + redirect W-1 |
| `lib/presentation/l10n/app_{es,en}.arb` | Modificar | Renombres dashboard + claves biblioteca |
| `test/support/fakes.dart` | Modificar | `RepositorioArchivosFake` (+`listarAudios`), `ReproductorFake` (estado con `StreamController`) |
| `test/presentation/controllers/providers_test.dart` | Modificar | `RepositorioArchivosFalso` (+`listarAudios`) |
| `test/widget_test.dart` | Modificar | `_ArchivosVacios` (+`listarAudios`) |
| `test/domain/use_cases/procesar_archivo_integration_test.dart` | Modificar | `_FakeRepositorio` (+`listarAudios`) |
| `test/domain/use_cases/listar_audios_generados_test.dart` | Crear | Agrupación y prioridad |
| `test/data/repositories/repositorio_archivos_test.dart` | Modificar | + grupo `listarAudios` |
| `test/presentation/controllers/biblioteca_controller_test.dart` | Crear | Toggle, error, dispose |
| `test/presentation/screens/biblioteca/biblioteca_screen_test.dart` | Crear | Estados UI |
| `test/presentation/screens/dashboard_screen_test.dart` | Modificar | Renombres + CTA/progreso/grid/hit targets/rebuilds |
| `test/presentation/routing/app_router_test.dart` | Crear | Redirect W-1 + ruta biblioteca |

## Interfaces / Contracts

```dart
// domain/contracts/reproductor_audio.dart
enum EstadoReproduccion { detenido, reproduciendo, pausado }

abstract class ReproductorAudio {
  Future<void> reproducir(String ruta);          // reemplaza: setFilePath + play
  Future<void> pausar();
  Future<void> reanudar();                        // play() sin recargar fuente
  Future<void> detener();                         // stop() → idle
  Stream<EstadoReproduccion> get estado;
}

// domain/contracts/repositorio_archivos.dart  (+ en el abstract)
List<String> listarAudios(String carpeta);        // rutas wav|flac|ogg|mp3, orden natural

// domain/entities/libro_generado.dart
class LibroGenerado extends Equatable {
  const LibroGenerado({required this.titulo, required this.archivos, required this.formatoPrioritario});
  final String titulo;
  final List<String> archivos;                    // rutas completas, orden natural
  final String formatoPrioritario;                // 'mp3' | 'ogg' | 'flac' | 'wav'
  String get rutaPrioritaria;                     // primera ruta con ese formato
}

// domain/use_cases/listar_audios_generados.dart
class ListarAudiosGenerados {
  ListarAudiosGenerados({required RepositorioArchivos archivos});
  List<LibroGenerado> ejecutar({required String carpeta});
  // const _prioridad = ['mp3', 'ogg', 'flac', 'wav']; índice menor gana.
  // Stem = nombre sin última extensión (port de _stem/Archivo.titulo, sin dart:io).
}
```

Impl `data/`:
- `listarAudios`: `Directory(carpeta).listSync().whereType<File>()` filtrando extensiones (case-insensitive) `wav|flac|ogg|mp3`; ordenar por `naturalSortKey(_stem(nombre))`; devolver `f.path`. Carpeta inexistente → `[]` (paridad con `listarArchivosMd`).
- `ReproductorJustAudio`: `pausar → _player.pause()`, `reanudar → _player.play()`, `detener → _player.stop()`. `estado` mapea `_player.playerStateStream`: `processingState` en `idle|completed` → `detenido`; si no, `playing ? reproduciendo : pausado`. `reproducir` ya reemplaza la fuente (`setFilePath` + `play`).

## BibliotecaController

```dart
class BibliotecaEstado {
  final List<LibroGenerado> libros;
  final String? error;
  final String? reproduciendoRuta;   // ruta del tile que suena (null = idle)
  final bool pausado;
  bool get vacio => libros.isEmpty && error == null;
  // copyWith estándar (patrón HomeEstado/ModeloEstado)
}

class BibliotecaController extends Notifier<BibliotecaEstado> {
  @override
  BibliotecaEstado build() {
    final prefs = ref.watch(repositorioPreferenciasProvider).cargar();
    final base = ref.watch(carpetaBaseProvider);
    final sep = Platform.pathSeparator;
    final carpeta = prefs['carpeta_out'] as String? ?? '$base${sep}audio';
    final sub = ref.watch(reproductorAudioProvider).estado.listen(_onEstado);
    ref.onDispose(() { sub.cancel(); detener(); });   // BIB-3 "detener al salir" + sin leaks
    try {
      return BibliotecaEstado(libros: ref.read(listarAudiosProvider).ejecutar(carpeta: carpeta));
    } catch (e) {
      return BibliotecaEstado(libros: const [], error: '$e');
    }
  }
  Future<void> alternarReproduccion(LibroGenerado libro); // toggle BIB-3
  Future<void> reproducir(LibroGenerado libro); // try/catch: error → idle + error (BIB-5)
  Future<void> pausar();  Future<void> reanudar();
  void _onEstado(EstadoReproduccion e); // detenido → limpia; reproduciendo → pausado:false
}
```

- `alternarReproduccion`: misma `rutaPrioritaria` que el tile sonando → `pausado ? reanudar() : pausar()`; otra ruta o idle → `reproducir()`. `reproducir` setea `reproduciendoRuta`/`pausado:false` y en `catch` deja `error` + idle (BIB-5).
- El error se muestra vía `ref.listen` en la pantalla (patrón `seleccion_screen.dart` + `PaletaExt.paleta.error`).

## BibliotecaScreen

`ConsumerWidget` (patrón seleccion): `Scaffold` + `AppBar(t.biblioteca_titulo)`. `ref.listen(bibliotecaControllerProvider.select((s) => s.error))` → SnackBar (solo al emitir nuevo error). Cuerpo por estado:
- `error != null` → icono + texto + botón reintentar (`recargar()`).
- `vacio` → icono + `t.biblioteca_vacio` + `FilledButton.icon` → `context.push(Rutas.home)` (BIB-4).
- lista → `ListView.builder` de `Card(child: ListTile(...))` (hereda `cardTheme` global, coherencia DASH-3): `leading` icono play/pausa según `reproduciendoRuta == libro.rutaPrioritaria && !pausado`, `title` = `libro.titulo`, `subtitle` = `libro.formatoPrioritario.toUpperCase()`, `trailing` `IconButton` (tooltip `biblioteca_pausa`/`biblioteca_play`, `constraints` ≥ 48×48) y `onTap` del tile → `alternarReproduccion`. Sin imports de `just_audio` (BIB-6).

## Dashboard refactorizado

- **Hero (DASH-8)**: al tope, `dashboard_bienvenida` (título) + `dashboard_bienvenida_sub` (nuevo).
- **`_CardFuncion`** (renombra `_BotonFuncion`): `Card(margin: ...)` **sin** `color`/`shape` propios (hereda `cardTheme`: superficie + radio 12 + `side` de `p.borde`); `InkWell` + `Padding`; círculo del icono con `PaletaExt.of(context)!.paleta.primarioClaro`/`primarioLuz` según estilo y `onPrimaryContainer`/`primarioSombra` (acentos y biseles por `PaletaExt`, W-2). Card #3: `Icons.library_books_outlined`, `t.dashboard_biblioteca(_desc)`, `onTap: () => context.push(Rutas.biblioteca)` (DASH-1).
- **`_CardEstadoModelo`** (renombra `_FilaEstadoModelo`, ahora `ConsumerWidget`): **aquí vive el único watch del modelo** (D3/W-3). Estados (DASH-5): `descargando` → `LinearProgressIndicator` + `t.modelo_progreso(bytesMb, totalMb)` (nunca "sin descargar"); `verificando && !listo` → spinner chico + `verificando…`; `listo` → "descargado"; `error != null` → `t.modelo_error(...)`. CTA (DASH-6): `!listo && !descargando && error == null` → `FilledButton.icon` "Descargar modelo" → `context.push(Rutas.modelo, extra: Rutas.dashboard)`; durante descarga el CTA desaparece. Refresh: `IconButton` tooltip `t.refrescar`, `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` (hoy 24). Texto compuesto en el widget: `'${t.dashboard_modelos}: $estadoTexto'` (W-5, sin espacio embebido — el ARB lleva `"Modelos"`).
- **Grid (DASH-9)**: `LayoutBuilder` → `GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), crossAxisCount: constraints.maxWidth >= 600 ? 2 : 1)` dentro del `SingleChildScrollView` existente.
- `DashboardScreen.build` **deja de watch** `modeloControllerProvider` (solo `_CardEstadoModelo` lo hace) → DASH-7.

## Router

```dart
abstract final class Rutas { ... static const biblioteca = '/biblioteca'; }

// redirect (W-1):
if (destino == Rutas.modelo && listo) {
  final origen = state.extra;
  if (origen is String && _origenesValidos.contains(origen)) return origen;
  return Rutas.home;                                  // gate normal sin regresión
}
const _origenesValidos = {Rutas.home, Rutas.dashboard, Rutas.seleccion};
// + GoRoute(path: Rutas.biblioteca, builder: (_, __) => const BibliotecaScreen())
```

## l10n (es / en)

| Clave nueva | es | en | Reemplaza |
|---|---|---|---|
| `dashboard_biblioteca` | Biblioteca | Library | `dashboard_opcion3` |
| `dashboard_biblioteca_desc` | Volvé a escuchar los audiolibros que ya generaste. | Listen again to the audiobooks you've already generated. | `dashboard_opcion3_desc` |
| `dashboard_procesar_sueltos` | Procesar archivos sueltos | Process loose files | `dashboard_opcion2` |
| `dashboard_procesar_sueltos_desc` | Elegí uno o más archivos .md de cualquier lugar y convertilos en audio. | Pick one or more .md files from anywhere and convert them to audio. | `dashboard_opcion2_desc` |
| `dashboard_modelos` | Modelos (sin `": "` final) | Models | `dashboard_modelos` (quitaba espacio) |
| `dashboard_modelo_descargar` | Descargar modelo | Download model | — (CTA) |
| `dashboard_bienvenida_sub` | Elegí una función y empezá. | Pick an option and get started. | — (hero) |
| `biblioteca_titulo` | Biblioteca | Library | — |
| `biblioteca_vacio` | Todavía no generaste ningún audiolibro. | You haven't generated any audiobooks yet. | — |
| `biblioteca_vacio_accion` | Ir a convertir | Go convert | — |
| `biblioteca_play` | Reproducir | Play | — |
| `biblioteca_pausa` | Pausar | Pause | — |
| `biblioteca_error` | No se pudo reproducir: {error} | Could not play: {error} | — |

Se mantienen `dashboard_modelo_descargado/sin_descargar/verificando` (los usa la Card). **Tests rotos por renombres**: ninguno usa las claves directamente — `dashboard_screen_test` usa strings literales `'Modelos: descargado'` etc.; al componer el texto en el widget de forma idéntica (`'Modelos: $estadoTexto'`) los asserts sobreviven; se actualizan solo por estructura (Card, hit target, CTA). Tras tocar el ARB corre `flutter gen-l10n` (generate: true) — los getters regenerados rompen la compilación hasta renombrar el widget en la misma unidad de trabajo.

## Testing Strategy (strict_tdd: tests RED primero en sdd-apply)

| Capa | Qué | Cómo |
|---|---|---|
| Unit — use case | Agrupación por stem, prioridad mp3>ogg>flac>wav, orden | `listar_audios_generados_test.dart` con `RepositorioArchivosFake` |
| Unit — data | `listarAudios`: filtro extensiones, orden natural, carpeta inexistente → `[]` | Grupo nuevo en `repositorio_archivos_test.dart` (temp dir real, patrón existente) |
| Unit — controller | Build (carpeta_out/fallback), toggle play→pausa→reanudar, cambio de tile, error de reproducción → idle+error, `detener()` en dispose, sub cancelada | `biblioteca_controller_test.dart` + `ReproductorFake` con `StreamController` y flags `pausado/detenido/reanudado` |
| Widget — biblioteca | Lista, vacío + acción a `/home`, iconos play/pausa por tile, error en SnackBar, tooltips | `biblioteca_screen_test.dart` (harness sin router, patrón dashboard_screen_test) |
| Widget — dashboard | Renombres actualizados; CTA navega con origen; progreso durante descarga; error; refresh ≥ 48×48 (medir `tester.getSize`); grid 2 col a 800dp / 1 col a 400dp; DASH-7 con contador de builds envolviendo `DashboardScreen` (no se reconstruye en ticks) | `dashboard_screen_test.dart` + harness router para navegación |
| Widget — router | Gate `home→modelo` intacto; `extra` dashboard/seleccion vuelve al origen; sin extra → `/home`; ruta `/biblioteca` lista la screen | `app_router_test.dart` nuevo (GoRouter real con overrides) |
| Fakes | Contratos extendidos | `ReproductorFake` (estado), `RepositorioArchivosFake.listarAudios`; `RepositorioArchivosFalso`, `_ArchivosVacios`, `_FakeRepositorio` (stub `[]`) |

## Orden de implementación (work units / commits)

1. **WO-1 Dominio + data + fakes**: contratos extendidos, `LibroGenerado`, `ListarAudiosGenerados`, impls `data/`, `listarAudiosProvider`, fakes actualizados; tests: use case + repo (+RED primero). Mantiene la suite verde (fakes al día con los contratos).
2. **WO-2 BibliotecaController**: estado + toggle + stream + dispose; tests unit del controller.
3. **WO-3 BibliotecaScreen + ruta + claves `biblioteca_*`**: screen, `Rutas.biblioteca`, `GoRoute`, ARB (solo claves nuevas, no rompen); tests de widget.
4. **WO-4 Dashboard + renombres l10n**: hero, `_CardFuncion`, `_CardEstadoModelo` (CTA/progreso/refresh 48), grid, ARB renombres + widget en el mismo commit (compila por gen-l10n); actualizar `dashboard_screen_test` + nuevos (CTA, progreso, grid, hit targets, DASH-7).
5. **WO-5 Router W-1**: redirect generalizado + `app_router_test.dart`; cierra el retorno del CTA.

## Migration / Rollout

No aplica (sin esquema persistente; `preferencias.json` no cambia claves). Rollback: revert de commits de la rama.

## Open Questions

- Ninguna que bloquee. Nota: `reproducir()` lanza con archivo faltante y el catch del controller reporta el error crudo (`'$e'`) dentro de `biblioteca_error` — aceptable para BIB-5 (mensaje localizable + detalle técnico).
