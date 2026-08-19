/// Barrel file for Supertonic TTS helpers.
///
/// This file re-exports all public APIs from the helper modules,
/// maintaining backward compatibility with the original monolithic file.
library;

export 'package:supertonic_audiobook/features/convert/data/helpers/unicode_constants.dart'
    show
        hangulSyllableBase,
        hangulSyllableEnd,
        leadingJamoBase,
        vowelJamoBase,
        trailingJamoBase,
        vowelCount,
        trailingCount,
        decomposeHangulSyllable,
        latinDecompositions,
        applyNfkdDecomposition;

export 'package:supertonic_audiobook/features/convert/data/helpers/text_preprocessor.dart'
    show availableLangs, isValidLang, preprocessText;

export 'package:supertonic_audiobook/features/convert/data/helpers/unicode_processor.dart'
    show UnicodeProcessor;

export 'package:supertonic_audiobook/features/convert/data/helpers/model_loader.dart'
    show logger, copyModelToFile, loadCfgs, loadOnnxAll;

export 'package:supertonic_audiobook/features/convert/data/helpers/text_to_speech.dart'
    show
        Style,
        TextToSpeech,
        loadTextToSpeech,
        flattenToDouble,
        loadVoiceStyle;

export 'package:supertonic_audiobook/features/convert/data/helpers/wav_writer.dart'
    show writeWavFile;
