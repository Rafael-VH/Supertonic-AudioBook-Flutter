/// Constantes técnicas — valores EXACTOS (plan §5.1).
library;

const double silenceDurationSecs = 0.6; // silencio entre fragmentos

/// Muestras de silencio entre fragmentos (44100 Hz * 0.6 s).
const int silenceSamples = 26460;

/// Umbral de RAM para volcado parcial a disco (500 * 1024 * 1024).
const int memoriaSafeMarginBytes = 524288000;

/// Presupuesto de RAM para retener fragmentos en móvil: el heap de una app
/// Android/iOS es chico y 500 MiB de Float32 acumulados provocan OOM.
const int memoriaSafeMarginBytesMovil = 67108864; // 64 * 1024 * 1024

/// Subtipo de audio por formato (paridad con `sf.SoundFile`).
const Map<String, String> subtiposAudio = {
  'wav': 'PCM_16',
  'flac': 'PCM_16',
  'ogg': 'VORBIS',
  'mp3': 'MPEG_LAYER_III',
};
