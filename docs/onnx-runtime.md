# ONNX Runtime

How ONNX Runtime powers the TTS inference engine.

## Overview

| Property | Value |
|----------|-------|
| Package | `flutter_onnxruntime: ^1.8.3` |
| Role | Run ML models for text-to-speech synthesis |
| Execution | On-device, CPU-only (no GPU) |
| Sessions | 4 ONNX models loaded in parallel |

## What is ONNX?

**Open Neural Network Exchange** — an open format for ML models. Models trained in PyTorch/TensorFlow can be exported to `.onnx` and run on any ONNX Runtime-compatible device.

**Why ONNX for this project?**
- No cloud dependency — runs 100% locally
- No GPU required — CPU inference is sufficient
- Cross-platform — same model works on Android, iOS, desktop
- Small runtime footprint via `flutter_onnxruntime`

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│                                                         │
│  ┌──────────────┐    ┌──────────────────────────────┐   │
│  │ MotorTts     │    │   supertonic_helper.dart      │   │
│  │ Supertonic   │───→│                              │   │
│  └──────────────┘    │  ┌────────────────────────┐  │   │
│                      │  │   TextToSpeech         │  │   │
│                      │  │   ┌──────────────────┐ │  │   │
│                      │  │   │ UnicodeProcessor  │ │  │   │
│                      │  │   └──────────────────┘ │  │   │
│                      │  └────────────────────────┘  │   │
│                      └──────────┬───────────────────┘   │
│                                 │                       │
└─────────────────────────────────┼───────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │   flutter_onnxruntime    │
                    │   (ONNX Runtime)         │
                    └─────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │ .onnx    │ │ .onnx    │ │ .onnx    │
              │ models   │ │ models   │ │ models   │
              └──────────┘ └──────────┘ └──────────┘
```

## ONNX Sessions

Four models are loaded as separate ONNX sessions:

| Session | Model File | Size | Purpose |
|---------|-----------|------|---------|
| `dpOrt` | `duration_predictor.onnx` | 3.7 MB | Predict phoneme durations |
| `textEncOrt` | `text_encoder.onnx` | 36.4 MB | Encode text to embeddings |
| `vectorEstOrt` | `vector_estimator.onnx` | 256.5 MB | Denoise latent vectors |
| `vocoderOrt` | `vocoder.onnx` | 101.4 MB | Convert latents to audio |

### Loading

All 4 sessions load in parallel at startup:

```dart
final ort = OnnxRuntime();
final models = ['duration_predictor', 'text_encoder', 'vector_estimator', 'vocoder'];

final sessions = await Future.wait(models.map((name) async {
  final path = '$dir/$name.onnx';
  return ort.createSession(path);
}));
```

### Session Lifecycle

- **Lazy load**: First synthesis triggers `loadTextToSpeech()`
- **Singleton**: One instance per voice change
- **No GPU**: `useGpu: false` (GPU mode throws)

## Inference Pipeline

### 1. Text Preprocessing

```dart
String preprocessText(String text, String lang) {
  // NFKD decomposition (Hangul syllables → Jamo)
  text = _applyNfkdDecomposition(text);
  
  // Remove emojis, replace symbols
  text = text.replaceAll(RegExp(r'[\u{1F600}-...]'), '');
  
  // Normalize punctuation, spacing
  text = text.replaceAll(' ,', ',');
  
  // Add language tags
  text = '<$lang>$text</$lang>';
  
  return text;
}
```

### 2. Unicode Processing

```dart
class UnicodeProcessor {
  final Map<int, int> indexer;  // Unicode codepoint → model index
  
  Map<String, dynamic> call(List<String> textList, List<String> langList) {
    // Convert text to integer IDs
    // Generate attention masks
    return {'textIds': textIds, 'textMask': mask};
  }
}
```

### 3. Duration Prediction

```dart
final dpResult = await dpOrt.run({
  'text_ids': textIdsTensor,
  'style_dp': style.dp,
  'text_mask': textMaskTensor,
});
// Output: predicted durations for each phoneme
```

### 4. Text Encoding

```dart
final textEncResult = await textEncOrt.run({
  'text_ids': textIdsTensor,
  'style_ttl': style.ttl,
  'text_mask': textMaskTensor,
});
// Output: text embeddings
```

### 5. Denoising Loop

Iterative refinement of latent vectors:

```dart
for (var step = 0; step < totalStep; step++) {
  final result = await vectorEstOrt.run({
    'noisy_latent': noisyLatent,
    'text_emb': textEncResult,
    'style_ttl': style.ttl,
    'text_mask': textMaskTensor,
    'latent_mask': latentMaskTensor,
    'total_step': totalStepTensor,
    'current_step': stepTensor,
  });
  // Update noisyLatent with denoised output
}
```

**More steps = better quality, slower inference.**

### 6. Vocoder

```dart
final vocoderResult = await vocoderOrt.run({
  'latent': noisyLatent,
});
// Output: Float32 audio samples
```

## Tensor Operations

### Creating Tensors

```dart
// Float32 tensor
Future<OrtValue> _toTensor(dynamic array, List<int> dims) async {
  final flat = _flattenList<double>(array);
  return await OrtValue.fromList(Float32List.fromList(flat), dims);
}

// Int64 tensor
Future<OrtValue> _intToTensor(List<List<int>> array, List<int> dims) async {
  final flat = array.expand((row) => row).toList();
  return await OrtValue.fromList(Int64List.fromList(flat), dims);
}

// Scalar tensor
Future<OrtValue> _scalarToTensor(List<double> array, List<int> dims) async {
  return await OrtValue.fromList(Float32List.fromList(array), dims);
}
```

### Reading Results

```dart
final result = await session.run({...inputs...});
final output = await result.values.first.asList();
// Returns List<double> or List<int>
```

## Text Chunking

Long texts are split into chunks before inference:

```dart
List<String> _chunkText(String text, {int maxLen = 300}) {
  // Split by paragraphs, then by sentences
  // Max 300 chars per chunk (120 for Korean/Japanese)
  // Each chunk processed independently, then concatenated
}
```

**Language-specific limits**:
- Latin scripts: 300 chars max
- Korean/Japanese: 120 chars max

## Audio Concatenation

Multiple chunks produce separate audio arrays. They're concatenated with silence:

```dart
if (wavCat == null) {
  wavCat = wav;
} else {
  wavCat = [
    ...wavCat,
    ...List<double>.filled((silenceDuration * sampleRate).floor(), 0.0),
    ...wav,
  ];
}
```

## Memory Management

### During Inference

- Tensors created via `OrtValue.fromList()`
- Results extracted via `.asList()`
- Intermediate tensors garbage collected after session.run()

### Batch Processing

- One chunk at a time (no batching)
- Latent vectors allocated per-chunk
- No persistent state between chunks

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Cold start | ~2-5 seconds (load 4 models) |
| Warm inference | ~1-3 seconds per chunk |
| Memory peak | ~500 MB (model + tensors) |
| CPU usage | Single-threaded |

## Error Handling

```dart
// GPU not supported
if (useGpu) throw Exception('GPU mode not supported yet');

// Invalid language
if (!isValidLang(lang)) {
  throw ArgumentError('Invalid language: $lang');
}
```

## Key Design Decisions

### 1. Lazy Loading

Models load on first synthesis, not at app start. This keeps startup fast (~200ms) while accepting a cold-start penalty on first use.

### 2. No GPU

GPU mode is explicitly disabled. The Supertonic 3 model is designed for CPU inference, and GPU support would require additional platform-specific code.

### 3. Isolate for Hashing

Model verification (SHA-256) runs in a separate isolate to avoid blocking the UI during download verification.

### 4. Fixed Chunks

Text is chunked at fixed character limits, not by sentence boundaries. This simplifies the pipeline while maintaining acceptable quality.
