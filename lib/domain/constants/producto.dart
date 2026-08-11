/// Constantes de producto — valores EXACTOS (paridad con `domain/repositories/motor_tts.py`).
library;

const defaultVoice = 'M1';

/// Idioma de síntesis por defecto (código ISO del modelo supertonic-3).
const defaultLang = 'es';

/// Pasos de inferencia del modelo TTS (más = mejor calidad, más lento).
const defaultTtsSteps = 5;

/// Velocidad de habla (1.0 = normal).
const defaultSpeed = 1.1;

/// Idiomas soportados por supertonic-3 (31 + "na" para texto sin idioma).
const languagesVoz = [
  'es', 'en', 'ar', 'bg', 'cs', 'da', 'de', 'el', 'et', 'fi', 'fr',
  'hi', 'hr', 'hu', 'id', 'it', 'ja', 'ko', 'lt', 'lv', 'nl', 'pl',
  'pt', 'ro', 'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'vi', 'na',
];

/// Voces integradas del modelo (M1-M5, F1-F5).
const voces = ['M1', 'M2', 'M3', 'M4', 'M5', 'F1', 'F2', 'F3', 'F4', 'F5'];
