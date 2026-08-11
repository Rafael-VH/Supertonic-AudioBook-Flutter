# supertonic_audiobook

Lee archivos `.md`, los limpia, los segmenta y los convierte en audios con el motor [Supertonic 3](https://huggingface.co/spaces/Supertone/supertonic-3) (TTS on-device basado en ONNX Runtime), con voces sintéticas en 31 idiomas + auto. Sin nube. Sin API. Sin GPU.

## Supertonic Flutter Example

This example demonstrates how to use Supertonic 3 in a Flutter application using ONNX Runtime.

> **Note:** This project uses the `flutter_onnxruntime` package ([https://pub.dev/packages/flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)). At the moment, only the macOS platform has been tested. Although the flutter_onnxruntime package supports several other platforms, they have not been tested in this project yet and may require additional verification.

## Multilingual Support

Supertonic 3 supports 31 languages. Select the appropriate language from the dropdown; see the main README for the full code list.

## Requirements

- Flutter SDK version ^3.5.0
