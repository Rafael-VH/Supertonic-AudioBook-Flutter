# Supertonic 3 Model

Text-to-speech (TTS) synthesis model used by the application.

## Overview

Supertonic 3 is a TTS model that generates high-quality audio from text, with style-conditioned voices. It runs on-device via ONNX Runtime — no cloud, no GPU.

- **Official repo**: [Supertone/supertonic-3 on Hugging Face](https://huggingface.co/Supertone/supertonic-3)
- **License**: OpenRAIL-M (credits in the app's About section)

## Specifications

| Property | Value |
|-----------|-------|
| Total size | ~400 MB (15 files) |
| Format | ONNX |
| Audio output | Float32 PCM |
| Sample rate | 44100 Hz |
| Channels | Mono |
| Inference steps | 5–12 (more = better quality) |

## Model Files

Downloaded to `<app_support>/modelo/` by `ModeloManager` (`features/modelo/data/repositories/modelo_manager.dart`):

| File | Size | Verification |
|---------|--------|--------------|
| `onnx/duration_predictor.onnx` | ~3.7 MB | SHA-256 |
| `onnx/text_encoder.onnx` | ~36.4 MB | SHA-256 |
| `onnx/vector_estimator.onnx` | ~256.5 MB | SHA-256 |
| `onnx/vocoder.onnx` | ~101.4 MB | SHA-256 |
| `onnx/tts.json` | ~8 KB | Size + parsing |
| `onnx/unicode_indexer.json` | ~278 KB | Size + parsing |
| `voice_styles/F1–F5.json`, `M1–M5.json` | ~290 KB each | Size + parsing |

The ONNX SHA-256 hashes are the `lfs.oid` values published by Hugging Face. If a file is still corrupt after retries, the download fails visibly (`ModeloCorruptoException`) — `listo` is never reported with an incomplete model.

## Voices

### Available Voices (`voces`)

| Code | Type |
|--------|------|
| `M1`–`M5` | Male |
| `F1`–`F5` | Female |

Each voice has its own style JSON in `voice_styles/` with prosody/pitch/rhythm parameters.

### Synthesis Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `voz` | M1–M5 / F1–F5 | `M1` | Voice style |
| `steps` | 5–12 | `5` | Decoding steps |
| `speed` | 0.7–2.0 | `1.1` | Speech speed |
| `lang` | 31 codes + `na` | `es` | Synthesis language |

Configuration lives in `VoiceConfig` and is applied with `MotorTts.cambiarVoz(voz)` before the batch.

## Supported Languages (31 + auto)

See the full table in [configuration.md](configuration.md#supported-languages-31--auto).

## Download Strategy

### Flow

```
1. Verify disk → files exist + correct size
2. Verify hash → SHA-256 in Isolate (ONNX only)
3. Download → https://huggingface.co/Supertone/supertonic-3
4. Save → <app_support>/modelo/onnx/ and voice_styles/
```

### Resumability

Resumable downloads with `Dio`: `Range` header + append mode over a `.part` file.

### State Management

**Controller**: `ModeloController` → `ModeloEstado`

| Field | Description |
|-------|-------------|
| `listo` | Is the model downloaded and verified? (router gate) |
| `progreso` | 0.0 – 1.0 |
| `error` | Error message |
| `verificando` | Verification in progress |

### Integrity Verification

The SHA-256 hash is computed in an Isolate to avoid blocking the UI. JSONs are validated by exact size + parsing.

## Inference

### Synthesis Pipeline

```
1. Tokenize text (unicode_indexer.json)
2. Encode style → voice embedding (voice_styles/*.json)
3. Predict duration + estimate vectors
4. Vocoder → Float32 samples
5. Insert silence between fragments (26460 samples)
```

### Quality vs Speed

| Steps | Quality | Speed |
|-------|---------|-----------|
| 5 | Good | Fast |
| 8 | Very good | Moderate |
| 12 | Excellent | Slow |

### Model Output

- **Format**: Float32 PCM · **Sample rate**: 44100 Hz · **Mono** · Range -1.0 to 1.0

## Common Errors

| Error | Cause | Solution |
|-------|-------|---------|
| `OutOfMemory` | Model + audio in memory | Reduce steps; flushing to `_temp/` is automatic |
| `InvalidGraph` | Corrupt or incompatible model | Re-download from the Model screen |
| `FileNotFound` | Model not downloaded | Download from the Model screen |
| `ModeloCorruptoException` | Invalid hash/size after retries | Re-download; check connection |

## References

- [ONNX Runtime](https://onnxruntime.ai/)
- [Supertone/supertonic-3](https://huggingface.co/Supertone/supertonic-3)
- [flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)
