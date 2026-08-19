import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:logger/logger.dart';
import 'package:supertonic_audiobook/features/convert/data/helpers/model_loader.dart';
import 'package:supertonic_audiobook/features/convert/data/helpers/unicode_processor.dart';

final logger = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 80),
);

/// Voice style data for TTS inference.
class Style {
  final OrtValue ttl, dp;
  final List<int> ttlShape, dpShape;
  Style(this.ttl, this.dp, this.ttlShape, this.dpShape);
}

/// Core TTS inference engine.
class TextToSpeech {
  final Map<String, dynamic> cfgs;
  final UnicodeProcessor textProcessor;
  final OrtSession dpOrt, textEncOrt, vectorEstOrt, vocoderOrt;
  final int sampleRate, baseChunkSize, chunkCompressFactor, ldim;

  TextToSpeech(this.cfgs, this.textProcessor, this.dpOrt, this.textEncOrt,
      this.vectorEstOrt, this.vocoderOrt)
      : sampleRate = cfgs['ae']['sample_rate'],
        baseChunkSize = cfgs['ae']['base_chunk_size'],
        chunkCompressFactor = cfgs['ttl']['chunk_compress_factor'],
        ldim = cfgs['ttl']['latent_dim'];

  Future<Map<String, dynamic>> call(
      String text, String lang, Style style, int totalStep,
      {double speed = 1.05, double silenceDuration = 0.3}) async {
    final maxLen = (lang == 'ko' || lang == 'ja') ? 120 : 300;
    final chunks = _chunkText(text, maxLen: maxLen);
    final langList = List.filled(chunks.length, lang);
    List<double>? wavCat;
    double durCat = 0;

    for (var i = 0; i < chunks.length; i++) {
      final result = await _infer([chunks[i]], [langList[i]], style, totalStep,
          speed: speed);
      final wav = _safeCast<double>(result['wav']);
      final duration = _safeCast<double>(result['duration']);

      if (wavCat == null) {
        wavCat = wav;
        durCat = duration[0];
      } else {
        wavCat = [
          ...wavCat,
          ...List<double>.filled((silenceDuration * sampleRate).floor(), 0.0),
          ...wav
        ];
        durCat += duration[0] + silenceDuration;
      }
    }

    return {
      'wav': wavCat,
      'duration': [durCat]
    };
  }

  Future<Map<String, dynamic>> _infer(
      List<String> textList, List<String> langList, Style style, int totalStep,
      {double speed = 1.05}) async {
    final bsz = textList.length;
    final result = textProcessor.call(textList, langList);

    final textIdsRaw = result['textIds'];
    final textIds = textIdsRaw is List<List<int>>
        ? textIdsRaw
        : (textIdsRaw as List).map((row) => (row as List).cast<int>()).toList();

    final textMaskRaw = result['textMask'];
    final textMask = textMaskRaw is List<List<List<double>>>
        ? textMaskRaw
        : (textMaskRaw as List)
            .map((batch) => (batch as List)
                .map((row) => (row as List).cast<double>())
                .toList())
            .toList();

    final textIdsShape = [bsz, textIds[0].length];
    final textMaskShape = [bsz, 1, textMask[0][0].length];
    final textMaskTensor = await _toTensor(textMask, textMaskShape);

    final dpResult = await dpOrt.run({
      'text_ids': await _intToTensor(textIds, textIdsShape),
      'style_dp': style.dp,
      'text_mask': textMaskTensor,
    });
    final durOnnx = _safeCast<double>(await dpResult.values.first.asList());
    final scaledDur = durOnnx.map((d) => d / speed).toList();

    final textEncResult = await textEncOrt.run({
      'text_ids': await _intToTensor(textIds, textIdsShape),
      'style_ttl': style.ttl,
      'text_mask': textMaskTensor,
    });

    final latentData = _sampleNoisyLatent(scaledDur);
    final noisyLatentRaw = latentData['noisyLatent'];
    var noisyLatent = noisyLatentRaw is List<List<List<double>>>
        ? noisyLatentRaw
        : (noisyLatentRaw as List)
            .map((batch) => (batch as List)
                .map((row) => (row as List).cast<double>())
                .toList())
            .toList();

    final latentMaskRaw = latentData['latentMask'];
    final latentMask = latentMaskRaw is List<List<List<double>>>
        ? latentMaskRaw
        : (latentMaskRaw as List)
            .map((batch) => (batch as List)
                .map((row) => (row as List).cast<double>())
                .toList())
            .toList();

    final latentShape = [bsz, noisyLatent[0].length, noisyLatent[0][0].length];
    final latentMaskTensor =
        await _toTensor(latentMask, [bsz, 1, latentMask[0][0].length]);

    final totalStepTensor =
        await _scalarToTensor(List.filled(bsz, totalStep.toDouble()), [bsz]);

    // Denoising loop
    for (var step = 0; step < totalStep; step++) {
      final result = await vectorEstOrt.run({
        'noisy_latent': await _toTensor(noisyLatent, latentShape),
        'text_emb': textEncResult.values.first,
        'style_ttl': style.ttl,
        'text_mask': textMaskTensor,
        'latent_mask': latentMaskTensor,
        'total_step': totalStepTensor,
        'current_step':
            await _scalarToTensor(List.filled(bsz, step.toDouble()), [bsz]),
      });

      final denoisedRaw = await result.values.first.asList();
      final denoised = denoisedRaw is List<double>
          ? denoisedRaw
          : _safeCast<double>(denoisedRaw);
      var idx = 0;
      for (var b = 0; b < noisyLatent.length; b++) {
        for (var d = 0; d < noisyLatent[b].length; d++) {
          for (var t = 0; t < noisyLatent[b][d].length; t++) {
            noisyLatent[b][d][t] = denoised[idx++];
          }
        }
      }
    }

    final vocoderResult = await vocoderOrt
        .run({'latent': await _toTensor(noisyLatent, latentShape)});
    final wavRaw = await vocoderResult.values.first.asList();
    final wav = wavRaw is List<double> ? wavRaw : _safeCast<double>(wavRaw);

    return {'wav': wav, 'duration': scaledDur};
  }

  Map<String, dynamic> _sampleNoisyLatent(List<double> duration) {
    final wavLenMax = duration.reduce(math.max) * sampleRate;
    final wavLengths = duration.map((d) => (d * sampleRate).floor()).toList();
    final chunkSize = baseChunkSize * chunkCompressFactor;
    final latentLen = ((wavLenMax + chunkSize - 1) / chunkSize).floor();
    final latentDim = ldim * chunkCompressFactor;

    final random = math.Random();
    final noisyLatent = List.generate(
      duration.length,
      (_) => List.generate(
        latentDim,
        (_) => List.generate(latentLen, (_) {
          final u1 = math.max(1e-10, random.nextDouble());
          final u2 = random.nextDouble();
          return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
        }),
      ),
    );

    final latentMask = _getLatentMask(wavLengths);

    for (var b = 0; b < noisyLatent.length; b++) {
      for (var d = 0; d < noisyLatent[b].length; d++) {
        for (var t = 0; t < noisyLatent[b][d].length; t++) {
          noisyLatent[b][d][t] *= latentMask[b][0][t];
        }
      }
    }

    return {'noisyLatent': noisyLatent, 'latentMask': latentMask};
  }

  List<List<List<double>>> _getLatentMask(List<int> wavLengths) {
    final latentSize = baseChunkSize * chunkCompressFactor;
    final latentLengths = wavLengths
        .map((len) => ((len + latentSize - 1) / latentSize).floor())
        .toList();
    final maxLen = latentLengths.reduce(math.max);
    return latentLengths
        .map((len) => [List.generate(maxLen, (i) => i < len ? 1.0 : 0.0)])
        .toList();
  }

  List<String> _chunkText(String text, {int maxLen = 300}) {
    final paragraphs = text
        .trim()
        .split(RegExp(r'\n\s*\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    final chunks = <String>[];
    for (var paragraph in paragraphs) {
      paragraph = paragraph.trim();
      if (paragraph.isEmpty) continue;

      final sentences = paragraph.split(RegExp(
          r'(?<!Mr\.|Mrs\.|Ms\.|Dr\.|Prof\.)(?<!\b[A-Z]\.)(?<=[.!?])\s+'));

      var currentChunk = '';
      for (final sentence in sentences) {
        if (currentChunk.length + sentence.length + 1 <= maxLen) {
          currentChunk += (currentChunk.isNotEmpty ? ' ' : '') + sentence;
        } else {
          if (currentChunk.isNotEmpty) chunks.add(currentChunk.trim());
          currentChunk = sentence;
        }
      }
      if (currentChunk.isNotEmpty) chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  List<T> _safeCast<T>(dynamic raw) {
    if (raw is List<T>) return raw;
    if (raw is List) {
      if (raw.isNotEmpty && raw.first is List) {
        return flattenToDouble(raw) as List<T>;
      }
      if (T == double) {
        return raw
            .map((e) => e is num ? e.toDouble() : double.parse(e.toString()))
            .toList() as List<T>;
      }
      return raw.cast<T>();
    }
    throw Exception('Cannot convert $raw to List<$T>');
  }

  Future<OrtValue> _toTensor(dynamic array, List<int> dims) async {
    final flat = flattenToDouble(array);
    return await OrtValue.fromList(Float32List.fromList(flat), dims);
  }

  Future<OrtValue> _scalarToTensor(List<double> array, List<int> dims) async {
    return await OrtValue.fromList(Float32List.fromList(array), dims);
  }

  Future<OrtValue> _intToTensor(List<List<int>> array, List<int> dims) async {
    final flat = array.expand((row) => row).toList();
    return await OrtValue.fromList(Int64List.fromList(flat), dims);
  }
}

/// Load a TTS engine from a directory of ONNX models.
Future<TextToSpeech> loadTextToSpeech(String onnxDir,
    {bool useGpu = false}) async {
  if (useGpu) throw Exception('GPU mode not supported yet');

  logger.i('Loading TTS models from $onnxDir');

  final cfgs = await loadCfgs(onnxDir);
  final sessions = await loadOnnxAll(onnxDir);
  final textProcessor =
      await UnicodeProcessor.load('$onnxDir/unicode_indexer.json');

  logger.i('TTS models loaded successfully');

  return TextToSpeech(
    cfgs,
    textProcessor,
    sessions['dpOrt']!,
    sessions['textEncOrt']!,
    sessions['vectorEstOrt']!,
    sessions['vocoderOrt']!,
  );
}

/// Flatten a nested list to a flat list of doubles.
List<double> flattenToDouble(dynamic list) {
  if (list is List) return list.expand((e) => flattenToDouble(e)).toList();
  return [list is num ? list.toDouble() : double.parse(list.toString())];
}

/// Load voice style from JSON files.
Future<Style> loadVoiceStyle(List<String> paths) async {
  final bsz = paths.length;

  final firstJson = jsonDecode(
    paths[0].startsWith('assets/')
        ? await rootBundle.loadString(paths[0])
        : File(paths[0]).readAsStringSync(),
  );

  final ttlDims = List<int>.from(firstJson['style_ttl']['dims']);
  final dpDims = List<int>.from(firstJson['style_dp']['dims']);

  final ttlFlat = Float32List(bsz * ttlDims[1] * ttlDims[2]);
  final dpFlat = Float32List(bsz * dpDims[1] * dpDims[2]);

  for (var i = 0; i < bsz; i++) {
    final json = jsonDecode(
      paths[i].startsWith('assets/')
          ? await rootBundle.loadString(paths[i])
          : File(paths[i]).readAsStringSync(),
    );

    final ttlData = flattenToDouble(json['style_ttl']['data']);
    final dpData = flattenToDouble(json['style_dp']['data']);

    ttlFlat.setRange(i * ttlDims[1] * ttlDims[2],
        (i + 1) * ttlDims[1] * ttlDims[2], ttlData);
    dpFlat.setRange(
        i * dpDims[1] * dpDims[2], (i + 1) * dpDims[1] * dpDims[2], dpData);
  }

  final ttlShape = [bsz, ttlDims[1], ttlDims[2]];
  final dpShape = [bsz, dpDims[1], dpDims[2]];

  return Style(
    await OrtValue.fromList(ttlFlat, ttlShape),
    await OrtValue.fromList(dpFlat, dpShape),
    ttlShape,
    dpShape,
  );
}
