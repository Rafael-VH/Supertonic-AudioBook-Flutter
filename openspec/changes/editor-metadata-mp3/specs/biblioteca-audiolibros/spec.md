# Delta for Biblioteca de Audiolibros

## MODIFIED Requirements

### Requirement: Agrupar por libro con prioridad de formato (BIB-2) — Prioridad: must

La lista MUST agrupar los audios por libro (stem: nombre sin la última extensión) y MOSTRAR un tile por libro, eligiendo el formato de mayor prioridad `mp3 > ogg > flac > wav`. Tiles cuyo `formatoPrioritario` sea `mp3` SHALL incluir una acción "Editar metadata" que navegue al editor ID3.
(Previously: solo agrupaba por prioridad de formato sin acciones de edición)

#### Scenario: Un libro en varios formatos

- GIVEN existen `milibro.mp3` y `milibro.wav`
- WHEN se abre la biblioteca
- THEN se muestra un único tile "milibro" que reproduce el `.mp3`
- AND el tile incluye icono de editar (acción "Editar metadata")

#### Scenario: Solo formatos pesados

- GIVEN un libro existe solo como `milibro.wav`
- WHEN se abre la biblioteca
- THEN el tile usa el `.wav` (no hay prioridad superior disponible)
- AND el tile NO muestra icono de editar

#### Scenario: Acción editar navega al editor

- GIVEN un tile MP3 en la biblioteca
- WHEN se toca la acción "Editar metadata"
- THEN se navega a `/editor-metadata?ruta=<ruta_archivo_mp3>`
- AND la ruta se pasa como query parameter
