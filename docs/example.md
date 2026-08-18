Aquí tienes un archivo Markdown con instrucciones claras y detalladas para que tú o una IA puedan guiarte en la mezcla de voces de Supertonic 3.

```markdown
# Guía para Mezclar Voces en Supertonic 3 (Interpolación Esférica)

Este documento describe el proceso técnico para combinar las voces predefinidas de Supertonic 3 y crear nuevos estilos de voz mediante interpolación esférica (slerp). Está diseñado para ser interpretado por un agente de IA o un desarrollador.

## 1. Fundamento Técnico

- **Espacio de Estilos**: Las 10 voces predeterminadas (F1-F5, M1-M5) son puntos en un espacio vectorial de alta dimensión que representa características acústicas y prosódicas.
- **Interpolación Esférica (Slerp)**: Es el método utilizado para navegar suavemente entre estos puntos, generando combinaciones lineales que producen voces intermedias con características mixtas.
- **Restricción**: La suma de los pesos en una mezcla debe ser igual a 1.0 (100%).

## 2. Voces Predefinidas (Puntos de Anclaje)

Las voces base disponibles en el modelo son:

| Código | Tipo      | Descripción (referencia) |
| :----- | :-------- | :----------------------- |
| F1     | Femenina  | Estilo 1                 |
| F2     | Femenina  | Estilo 2                 |
| F3     | Femenina  | Estilo 3                 |
| F4     | Femenina  | Estilo 4                 |
| F5     | Femenina  | Estilo 5                 |
| M1     | Masculina | Estilo 1                 |
| M2     | Masculina | Estilo 2                 |
| M3     | Masculina | Estilo 3                 |
| M4     | Masculina | Estilo 4                 |
| M5     | Masculina | Estilo 5                 |

## 3. Implementación Técnica (Ejemplo con Python y MLX)

Este es el flujo de trabajo estándar para generar una voz mezclada usando la librería `supertonic-3-mlx`.

### 3.1. Instalación
```bash
pip install supertonic-3-mlx
```

3.2. Código de Mezcla

El siguiente script crea una voz mezclando un 70% de la voz F2 y un 30% de la voz M1, y genera un audio de prueba.

```python
from supertonic_3_mlx import Pipeline
import soundfile as sf

# 1. Cargar el pipeline del modelo
pipe = Pipeline.from_pretrained("ambassadia/supertonic-3-mlx")

# 2. Crear la voz mezclada usando slerp
#    Los pesos se definen en un diccionario: {código_de_voz: peso}
#    La suma de los pesos debe ser 1.0
pesos_mezcla = {
    "F2": 0.7,  # 70% de la voz F2
    "M1": 0.3   # 30% de la voz M1
}
voz_personalizada = pipe.create_voice(pesos_mezcla)

# 3. Generar un audio con la voz creada
texto = "Esta es una demostración de una voz mezclada con interpolación esférica."
audio, frecuencia_muestreo = pipe.generate(
    text=texto,
    voice=voz_personalizada,
    lang="es"  # Cambiar según el idioma deseado
)

# 4. Guardar el resultado
sf.write("voz_mezclada.wav", audio, frecuencia_muestreo)
print("Audio generado y guardado como 'voz_mezclada.wav'")
```

3.3. Uso con el SDK Estándar

Si usas el SDK estándar (supertonic), necesitas crear el vector manualmente:

```python
import supertonic
import numpy as np
# ... (código para cargar estilos F2 y M1 y calcular slerp)
# Nota: La librería estándar no expone slerp directamente, 
# por lo que se recomienda usar la versión MLX o implementar la función manualmente.
```

4. Guía para Experimentación (Prompt para Agente IA)

Si un agente IA te asiste, debe seguir esta lógica para ayudarte a encontrar la voz deseada:

1. Preguntar: ¿Qué tono buscas? (ej. "más grave que F1 pero más suave que M3").
2. Seleccionar base: Elegir 2 o 3 voces base que se aproximen al objetivo.
3. Proponer pesos: Sugerir una combinación inicial (ej. {"F1": 0.6, "M3": 0.4}).
4. Iterar: Basado en la retroalimentación del audio generado, ajustar los pesos (ej. "aumentar un 10% el peso de M3 para darle más cuerpo").
5. Restricción: Asegurarse que sum(pesos) == 1.0.

5. Consideraciones y Limitaciones

· Calidad de la Mezcla: La interpolación funciona mejor entre voces del mismo género o con características similares. Mezclar voces muy dispares (ej. F1 y M5) puede resultar en una voz artificial o con artefactos.
· Rendimiento: La generación con voz mezclada tiene la misma velocidad y huella de memoria que la generación con voces predefinidas.
· Compatibilidad: Los archivos voice_style.json generados por el servicio Voice Builder de pago no se pueden crear con este método; solo se pueden usar los vectores descargados.
· Documentación Adicional: Revisa el repositorio oficial para más ejemplos: Supertone/supertonic-3-mlx

6. Ejemplo de Prompt para Iteración Rápida

Para una interacción rápida, puedes pedirle al agente:

"Quiero una voz intermedia entre F1 (más aguda) y M1 (más grave), pero con un toque más jovial. Dame 3 opciones de combinación de pesos para probar."

Posible respuesta del agente:

1. {"F1": 0.6, "M1": 0.4} (Balance neutro)
2. {"F1": 0.4, "M1": 0.6} (Más grave y seria)
3. {"F1": 0.7, "M1": 0.2, "F3": 0.1} (Mantiene agudez pero añade calidez)

```

Este archivo proporciona una base sólida para que cualquier agente de IA entienda el proceso y pueda guiarte en la creación de nuevas voces para tu proyecto.