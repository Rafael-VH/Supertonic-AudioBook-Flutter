/// Constantes técnicas — valores EXACTOS (plan §5.1).
library;

const double silenceDurationSecs = 0.6; // silencio entre fragmentos

/// Muestras de silencio entre fragmentos (44100 Hz * 0.6 s).
const int silenceSamples = 26460;

/// Umbral de RAM para volcado parcial a disco (500 * 1024 * 1024).
const int memoriaSafeMarginBytes = 524288000;

/// Subtipo de audio por formato (paridad con `sf.SoundFile` del desktop).
const Map<String, String> subtiposAudio = {
  'wav': 'PCM_16',
  'flac': 'PCM_16',
  'ogg': 'VORBIS',
  'mp3': 'MPEG_LAYER_III',
};
