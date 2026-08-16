# Biblioteca de Audiolibros Specification

## Purpose

Pantalla que lista los audios generados (carpeta de salida) agrupados por libro y los reproduce con play/pausa/reanudar/detener a través del contrato `ReproductorAudio`. El dominio define el listado, la agrupación y la prioridad de formato; la UI no toca `just_audio`.

## Requirements

### Requirement: Listar audios de la carpeta de salida (BIB-1) — Prioridad: must

La biblioteca MUST listar los audios de la carpeta `carpeta_out` de preferencias (fallback `<carpeta_base>/audio`), filtrando las extensiones de audio `wav`, `flac`, `ogg` y `mp3`, con orden natural.

#### Scenario: Carpeta con audios generados

- GIVEN `carpeta_out` contiene `libro1.mp3` y `libro2.wav`
- WHEN se abre la pantalla Biblioteca
- THEN se listan ambos audios en orden natural

#### Scenario: Carpeta inexistente o sin audios

- GIVEN `carpeta_out` no existe o está vacía
- WHEN se abre la pantalla Biblioteca
- THEN se muestra el estado vacío (BIB-4), sin error ni crash

### Requirement: Agrupar por libro con prioridad de formato (BIB-2) — Prioridad: must

La lista MUST agrupar los audios por libro (stem: nombre sin la última extensión) y MOSTRAR un tile por libro, eligiendo el formato de mayor prioridad `mp3 > ogg > flac > wav`.

#### Scenario: Un libro en varios formatos

- GIVEN existen `milibro.mp3` y `milibro.wav`
- WHEN se abre la biblioteca
- THEN se muestra un único tile "milibro" que reproduce el `.mp3`

#### Scenario: Solo formatos pesados

- GIVEN un libro existe solo como `milibro.wav`
- WHEN se abre la biblioteca
- THEN el tile usa el `.wav` (no hay prioridad superior disponible)

### Requirement: Reproducir, pausar, reanudar y detener (BIB-3) — Prioridad: must

El tap en un tile MUST reproducir ese libro vía `ReproductorAudio`; un segundo tap MUST pausar y un tercero MUST reanudar. Tocar otro tile MUST cambiar la reproducción a ese tile, y al salir de la pantalla la reproducción MUST detenerse.

#### Scenario: Play → pausa → reanudar

- GIVEN un libro listado
- WHEN se toca el tile dos veces
- THEN el audio pausa
- AND un tercer tap lo reanuda

#### Scenario: Cambio de tile y detener al salir

- GIVEN "libro1" reproduciéndose
- WHEN se toca "libro2" y luego se navega fuera de la pantalla
- THEN "libro2" reemplaza la reproducción
- AND al salir el audio se detiene (no sigue en segundo plano)

### Requirement: Estado vacío (BIB-4) — Prioridad: must

Sin audios en la carpeta, la pantalla MUST mostrar un mensaje de estado vacío ("nada generado todavía") con una acción para ir a la conversión.

#### Scenario: Sin audios

- GIVEN la carpeta de salida no tiene archivos de audio
- WHEN se abre la biblioteca
- THEN se muestra el mensaje de estado vacío
- AND la acción lleva a la pantalla de conversión

### Requirement: Estados de error de reproducción (BIB-5) — Prioridad: should

Si la reproducción falla (archivo faltante o corrupto), la app MUST mostrar un error al usuario y quedar en estado idle, sin crashear.

#### Scenario: Audio borrado del disco

- GIVEN un tile cuyo archivo fue eliminado
- WHEN se toca el tile
- THEN se muestra un mensaje de error
- AND el estado de reproducción vuelve a idle

### Requirement: Capas limpias (BIB-6) — Prioridad: must

La UI MUST reproducir solo vía el contrato `ReproductorAudio` (ningún import de `just_audio` en `presentation/`), y el listado, la agrupación y la prioridad MUST definirse en dominio (`RepositorioArchivos.listarAudios` + caso de uso `ListarAudiosGenerados`).

#### Scenario: Sin dependencia de just_audio en presentación

- GIVEN la base de código actual
- WHEN se inspeccionan los imports de `presentation/`
- THEN ningún widget ni controller de la biblioteca importa `just_audio`

#### Scenario: Agrupación testeable en dominio

- GIVEN un repositorio fake con audios mixtos
- WHEN se ejecuta `ListarAudiosGenerados`
- THEN devuelve un libro por stem con la ruta del formato ganador, sin UI
