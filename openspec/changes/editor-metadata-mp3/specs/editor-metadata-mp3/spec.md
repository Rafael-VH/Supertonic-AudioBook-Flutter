# Editor Metadata MP3 — Specification

## Purpose

Módulo para leer y escribir tags ID3v2 en archivos MP3 individuales. Proporciona una UI de formulario que permite al usuario modificar título, artista, álbum, pista, disco, año, género, comentario y portada. La escritura es atómica (temp→rename) y no re-codifica el audio. Domain puro sin dependencias de Flutter.

## Requirements

### Requirement: Leer tags ID3 del archivo MP3 (MET-1)

El sistema SHALL leer los tags ID3v2.3/v2.4 de un archivo MP3 dado y devolver una entidad `MetadatosMp3` con todos los campos disponibles (nulos si ausentes).

#### Scenario: Archivo MP3 con tags completos

- GIVEN un archivo `libro.mp3` con tags ID3 (título, artista, álbum, año, género, portada)
- WHEN se invoca `leer("libro.mp3")`
- THEN se devuelve `MetadatosMp3` con todos los campos poblados
- AND `coverArtBytes` contiene los bytes JPEG de la portada

#### Scenario: Archivo MP3 sin tags

- GIVEN un archivo `sin_tags.mp3` sin tags ID3
- WHEN se invoca `leer("sin_tags.mp3")`
- THEN se devuelve `MetadatosMp3` con todos los campos nulos
- AND NO se lanza excepción

#### Scenario: Archivo inexistente

- GIVEN no existe el archivo en la ruta dada
- WHEN se invoca `leer("no_existe.mp3")`
- THEN se lanza `MetadataReadException` con la ruta del archivo

### Requirement: Escribir tags ID3 al archivo MP3 (MET-2)

El sistema SHALL escribir los tags ID3 en un archivo MP3 de forma atómica: escribir a `<original>.tmp` y renombrar al path original. NO SHALL re-codificar ni modificar datos de audio.

#### Scenario: Escritura atómica exitosa

- GIVEN un archivo `libro.mp3` y una entidad `MetadatosMp3` con tags actualizados
- WHEN se invoca `guardar("libro.mp3", metadata)`
- THEN se crea `libro.mp3.tmp` con los tags escritos
- AND se renombra a `libro.mp3` (sobrescribe el original)
- AND el archivo resultante contiene los tags actualizados

#### Scenario: Escritura fallida — archivo original intacto

- GIVEN un archivo `libro.mp3` en directorio de solo lectura
- WHEN se invoca `guardar("libro.mp3", metadata)`
- THEN se lanza `MetadataWriteException`
- AND el archivo `libro.mp3` NO fue modificado
- AND el archivo temporal `.tmp` fue eliminado (limpieza)

#### Scenario: NO re-codificación de audio

- GIVEN un archivo `libro.mp3` de 3:20 minutos
- WHEN se guardan tags actualizados
- THEN la duración del audio resultante es idéntica
- AND el bitrate del audio resultante es idéntico

### Requirement: Formulario de edición con campos ID3 (MET-3)

La pantalla de editor SHALL mostrar un formulario con campos de texto para: título, artista, álbum, número de pista, número de disco, año, género y comentario. Cada campo SHALL estar pre-cargado con el valor actual del tag.

#### Scenario: Formulario pre-cargado

- GIVEN un archivo `libro.mp3` con título "Mi Libro" y artista "Autor"
- WHEN se abre el editor para ese archivo
- THEN el campo título muestra "Mi Libro"
- AND el campo artista muestra "Autor"
- AND los campos vacíos muestran placeholder descriptivo

#### Scenario: Campos opcionales vacíos

- GIVEN un archivo con tags mínimos (solo título)
- WHEN se abre el editor
- THEN los campos sin valor (artista, álbum, etc.) están vacíos
- AND NO se muestran errores de validación

### Requirement: Selección de portada JPEG (MET-4)

El editor SHALL permitir seleccionar una imagen de portada desde el dispositivo. La imagen MUST ser JPEG y NO debe exceder 500KB. Si excede, SHALL comprimirse antes de embeber.

#### Scenario: Portada nueva seleccionada

- GIVEN el editor abierto para un archivo MP3
- WHEN se selecciona un archivo JPEG de 200KB
- THEN la portada se muestra como preview en el formulario
- AND al guardar, la portada se embebe en los tags ID3

#### Scenario: Portada excede 500KB

- GIVEN el editor abierto
- WHEN se selecciona un archivo JPEG de 800KB
- THEN la imagen se comprime a ≤500KB antes de embeber
- AND se muestra preview de la imagen comprimida

#### Scenario: Portada no-JPEG rechazada

- GIVEN el editor abierto
- WHEN se selecciona un archivo PNG o BMP
- THEN se muestra error de validación
- AND la imagen NO se carga

### Requirement: Navegación desde biblioteca (MET-5)

La pantalla de biblioteca SHALL mostrar una acción "Editar metadata" en tiles de archivos MP3. WAV, FLAC y OGG NO SHALL mostrar esta acción.

#### Scenario: Tile MP3 muestra opción editar

- GIVEN un tile de biblioteca con `formatoPrioritario == "mp3"`
- WHEN se realiza long-press o se toca el icono de editar
- THEN se navega a `/editor-metadata?ruta=<ruta_archivo>`

#### Scenario: Tile WAV/FLAC/OGG sin opción editar

- GIVEN un tile de biblioteca con `formatoPrioritario == "wav"`
- WHEN se inspeccionan las acciones del tile
- THEN NO existe opción "Editar metadata"

### Requirement: Manejo de errores (MET-6)

Si la lectura o escritura falla, el sistema SHALL mostrar un snackbar de error sin crashear la app. El usuario SHALL poder reintentar o cancelar.

#### Scenario: Error de lectura

- GIVEN un archivo MP3 corrupto o ilegible
- WHEN se abre el editor para ese archivo
- THEN se muestra snackbar con mensaje de error
- AND se ofrece opción de cerrar el editor

#### Scenario: Error de escritura

- GIVEN el editor con metadata modificada
- WHEN se presiona "Guardar" y la escritura falla
- THEN se muestra snackbar con mensaje de error
- AND los cambios del formulario NO se pierden (estado preservado)

### Requirement: Capas limpias (MET-7)

El dominio SHALL ser puro: sin imports de `dart:io`, `flutter`, ni paquetes externos (excepto `equatable`). La capa de datos SHALL implementar el contrato `EditorMetadata`. La presentación SHALL consumir solo contratos vía providers.

#### Scenario: Domain sin dependencias externas

- GIVEN los archivos en `lib/features/editor_metadata/domain/`
- WHEN se inspeccionan sus imports
- THEN NO hay imports de `dart:io`, `flutter/*`, ni paquetes de tercero
- AND solo se importa `equatable` (si se usa)

#### Scenario: Presentación no importa data

- GIVEN los archivos en `lib/features/editor_metadata/presentation/`
- WHEN se inspeccionan sus imports
- THEN NO hay imports de `data/repositories/`
- AND se usa el contrato `EditorMetadata` vía provider
