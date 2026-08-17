# Pantallas

Las 8 pantallas de la aplicación, con responsabilidades, estado y navegación.

## Flujo de Navegación

```
Splash
  └─→ Onboarding (primera ejecución)
       └─→ Modelo (descargar modelo)
            └─→ Dashboard (centro principal)
                 ├─→ Home (conversión por lotes)
                 │    └─→ Settings
                 ├─→ Selección (archivos sueltos)
                 │    └─→ Settings
                 ├─→ Biblioteca (escuchar audiolibros)
                 └─→ Settings
```

## Pantallas

### Splash (`/splash`)

**Archivo**: `lib/presentation/screens/splash/splash_screen.dart`

Pantalla de carga inicial que se muestra mientras la app se inicializa.

| Estado | Visualización |
|--------|---------------|
| Por defecto | Logo centrado + nombre de la app |

**Navegación**: Navega automáticamente a onboarding o dashboard según la detección de primera ejecución.

---

### Onboarding (`/onboarding`)

**Archivo**: `lib/presentation/screens/onboarding/onboarding_screen.dart`

Guía interactiva de 5 pasos para usuarios nuevos.

| Paso | Contenido |
|------|-----------|
| 1 | Descargar modelo TTS |
| 2 | Seleccionar archivos Markdown |
| 3 | Elegir voz |
| 4 | Procesar audio |
| 5 | **Seleccionar carpeta de salida** (nuevo) |

**Controller**: `OnboardingController` (maneja navegación de pasos y descarga del modelo)

**Comportamientos clave**:
- El paso 5 usa `FilePicker.getDirectoryPath()` para configurar la carpeta de salida
- Completar el onboarding marca la primera ejecución como hecha
- Se puede saltar con el botón "Saltar" (va al dashboard)

---

### Dashboard (`/dashboard`)

**Archivo**: `lib/presentation/screens/dashboard/dashboard_screen.dart`

Centro principal después del onboarding. Muestra hero de bienvenida y tres cards de función.

| Card | Acción | Destino |
|------|--------|---------|
| Convertir archivos | Procesar por lotes carpeta `.md` | `/home` |
| Procesar archivos sueltos | Elegir archivos individuales | `/seleccion` |
| Biblioteca | Escuchar audiolibros generados | `/biblioteca` |

**Layout**:
- **Móvil** (< 600px): Columna única apilada
- **Tablet** (≥ 600px): Grid de 2 columnas

**Características**:
- Sección hero con descripción de la app (DASH-8)
- Card de estado del modelo (aislado, DASH-7)
- Engranaje de ajustes en AppBar
- Cards usan `cardTheme` global con acentos `PaletaExt` (DASH-3)

---

### Home (`/home`)

**Archivo**: `lib/presentation/screens/home/home_screen.dart`

Pantalla de procesamiento por lotes — el corazón de la app.

**Controller**: `HomeController` → `HomeEstado`

#### Estado (`HomeEstado`)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `carpetaIn` | `String` | Ruta de carpeta de entrada |
| `carpetaOut` | `String` | Ruta de carpeta de salida |
| `archivos` | `List<Archivo>` | Archivos `.md` encontrados |
| `seleccion` | `Set<String>` | Rutas marcadas (vacío = todos) |
| `voz` | `String` | Voz seleccionada |
| `steps` | `int` | Pasos TTS (5–12) |
| `speed` | `double` | Velocidad de voz (0.7–2.0) |
| `langVoz` | `String` | Idioma de la voz |
| `formatos` | `Set<String>` | Formatos de salida (wav/mp3/flac/ogg) |
| `ejecutando` | `bool` | Procesamiento en curso |
| `progresoActual` | `int` | Segmento actual |
| `progresoTotal` | `int` | Total de segmentos |
| `lineasLog` | `List<String>` | Registro de procesamiento (máx 2500 líneas) |

#### Secciones

1. **Selección de carpetas**: Selectores de carpeta entrada/salida
2. **Lista de archivos**: Archivos `.md` con checkboxes, seleccionar todo/nada/refrescar
3. **Opciones de síntesis**: Voz, pasos, velocidad, idioma, formatos de salida
4. **Vista previa de voz**: Botón "Escuchar" para probar la voz
5. **Procesamiento**: Barra de progreso, registro, botones procesar/cancelar

#### Comportamientos clave

- Persiste preferencias antes de procesar (`_guardarPreferencias`)
- Throttle del registro: `paso = max(1, total ~/ 20)`
- Cancelación elegante: exporta audio parcial, preserva archivos existentes
- Bloquea ejecuciones concurrentes (motor TTS es de un solo hilo)

---

### Selección (`/seleccion`)

**Archivo**: `lib/presentation/screens/seleccion/seleccion_screen.dart`

Procesar archivos `.md` individuales desde cualquier ubicación.

**Controller**: `SeleccionController` (extiende `HomeController`)

| Diferencia con Home | Descripción |
|---------------------|-------------|
| `archivos: []` | Comienza vacío — sin escaneo de carpeta |
| Selector de archivos | Abre el selector del sistema para elegir `.md` |
| Mismo procesamiento | Usa la misma lógica de `HomeController` |

**Comportamientos clave**:
- Archivos agregados con el selector del sistema (`FilePicker.getMultipleFiles`)
- Mismas opciones de síntesis que Home
- Mismo pipeline de procesamiento

---

### Modelo (`/modelo`)

**Archivo**: `lib/presentation/screens/modelo/modelo_screen.dart`

Pantalla de descarga y verificación del modelo.

**Controller**: `ModeloController` → `ModeloEstado`

| Estado | Visualización |
|--------|---------------|
| Verificando | Spinner mientras verifica el disco |
| Descargando | Barra de progreso + MB + archivo actual + Botón Cancelar |
| Error | Mensaje + Botón Reintentar |
| Pendiente | Aviso del tamaño + Botón Descargar modelo |

**Comportamientos clave**:
- Descargas resumibles
- Verificación SHA-256 en Isolate
- Modelo almacenado en `<app_support>/modelo/`

---

### Settings (`/settings`)

**Archivo**: `lib/presentation/screens/settings/settings_screen.dart`

Pantalla de preferencias de la app.

**Controller**: `SettingsController` → `SettingsEstado`

| Ajuste | Widget | Opciones |
|--------|--------|----------|
| Tema | `SegmentedButton` | Claro / Oscuro |
| Estilo | `SegmentedButton` | 3 variantes visuales |
| Idioma | `SegmentedButton` | Español / English |
| Carpeta de salida | Botón Examinar | Selector de archivos |

**Comportamientos clave**:
- Los cambios se persisten inmediatamente
- Cambios de tema/estilo se aplican al instante via `AppTheme`
- La carpeta de salida afecta la ruta por defecto de Home

---

### Biblioteca (`/biblioteca`)

**Archivo**: `lib/presentation/screens/biblioteca/biblioteca_screen.dart`

Escuchar audiolibros generados.

**Controller**: `BibliotecaController` → `BibliotecaEstado`

| Característica | Descripción |
|----------------|-------------|
| Agrupación de libros | Audios agrupados por stem (nombre sin extensión) |
| Prioridad de formato | `mp3 > ogg > flac > wav` (BIB-2) |
| Play/pausa | Controles por tile via contrato `ReproductorAudio` |
| Estado vacío | Mensaje + CTA para ir a conversión |
| Estado de error | Mensaje + botón reintentar (BIB-5) |

**Comportamientos clave**:
- Reproduce solo via contrato `ReproductorAudio` (nunca `just_audio` directamente, BIB-6)
- Cards heredan `cardTheme` global (DASH-3)
- Snackbar de error usa color de error de la paleta

---

## Layout Responsive

### Móvil (< 900px)

- **Home**: Acordeón apilado (una sección abierta a la vez)
  - Secciones de carpetas abiertas por defecto
  - Transiciones animadas (fade + slide, 250ms)
- **Dashboard**: Cards en columna única

### Tablet (≥ 900px)

- **Home**: Layout de dos columnas (`Row` 50/50)
- **Dashboard**: Grid de 2 columnas (≥ 600px)

### Breakpoints

| Pantalla | Móvil | Tablet |
|----------|-------|--------|
| Home | `< 900px` | `≥ 900px` |
| Dashboard | `< 600px` | `≥ 600px` |
