# Funcionalidades Recomendadas — Supertonic-AudioBook-Flutter

> Documento de referencia. Generado el 2026-08-18.
> El foco de la app es **generar audio desde archivos Markdown**, no reproducir. La reproducción es solo para previsualizar.

---

## 🥇 Directamente ligadas al flujo de generación

### 1. Previsualización antes de generar completo
- Generar solo el primer párrafo o los primeros 30 segundos
- Permitir al usuario elegir voz, velocidad y pasos antes de procesar todo el libro
- Ahorra tiempo si la configuración no es la correcta
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — reduce regeneraciones innecesarias

### 2. Comparador de voces
- Seleccionar un fragmento de texto y generarlo con 2-3 voces diferentes
- Escuchar y elegir la que mejor suene antes del procesamiento completo
- Muy valioso porque elegir voz es Trial & Error
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — resuelve el problema de "¿qué voz suena mejor?"

### 3. Presets de generación
- Guardar configuraciones favoritas (voz + velocidad + pasos + formato)
- "Narración rápida", "Calidad premium", "Podcast"
- Reutilizar sin reconfigurar cada vez
- **Esfuerzo estimado:** Bajo-Medio
- **Impacto:** Medio — mejora la reutilización

---

## 🥈 Mejoras en el pipeline de generación

### 4. Reanudar generación interrumpida
- Si la app se cierra o falla, retomar desde el archivo donde quedó
- Ya procesaste los archivos que están en la carpeta de salida — skip automático
- **Esfuerzo estimado:** Medio
- **Impacto:** Alto — evita reprocesamiento completo

### 5. Detección automática de capítulos
- Parsear el Markdown para identificar capítulos (`#`, `##`)
- Generar un archivo de audio por capítulo (en vez de uno solo largo)
- Facilita navegar y reorganizar después
- **Esfuerzo estimado:** Medio-Alto
- **Impacto:** Alto — mejora la estructura del output

### 6. Pre-procesamiento de texto
- Limpiar Markdown antes de enviar al TTS: quitar footnotes, links, código
- Expandir abreviaturas, corregir pronunciación de siglas
- Mejora la calidad del audio generado
- **Esfuerzo estimado:** Medio
- **Impacto:** Medio-Alto — mejora calidad del output

---

## 🥉 Experiencia de usuario

### 7. Estadísticas antes de generar
- Mostrar: cant. de palabras, tiempo estimado de generación, tamaño de salida
- "Tu libro tiene 45.000 palabras, estimado: ~12 minutos de generación"
- **Esfuerzo estimado:** Bajo
- **Impacto:** Medio — transparencia para el usuario

### 8. Post-procesamiento de audio
- Insertar silencios entre capítulos
- Normalizar volumen entre archivos
- FFmpeg ya está en el proyecto — es lógica, no dependencia nueva
- **Esfuerzo estimado:** Bajo-Medio
- **Impacto:** Medio — calidad profesional del output

---

## Resumen de factibilidad

| # | Funcionalidad | Esfuerzo | Impacto | Dependencias nuevas |
|---|--------------|----------|---------|---------------------|
| 1 | Previsualización | Medio | Alto | Ninguna |
| 2 | Comparador de voces | Medio | Alto | Ninguna |
| 3 | Presets | Bajo-Medio | Medio | Ninguna |
| 4 | Reanudar generación | Medio | Alto | Ninguna |
| 5 | Detección de capítulos | Medio-Alto | Alto | Ninguna |
| 6 | Pre-procesamiento texto | Medio | Medio-Alto | Ninguna |
| 7 | Estadísticas pre-gen | Bajo | Medio | Ninguna |
| 8 | Post-procesamiento audio | Bajo-Medio | Medio | Ninguna |

**Todas son viables sin dependencias externas nuevas.** El proyecto ya tiene FFmpeg, file_picker, y todas las herramientas necesarias.

---

## Recomendación de implementación

**Empezar por 1 + 2 (Previsualización + Comparador).** Atacan el dolor principal: configurar la generación es ciego. Con preview y comparador, el flujo pasa de "generar → escuchar → reconfigurar → regenerar" a "previsualizar → elegir → generar una vez".
