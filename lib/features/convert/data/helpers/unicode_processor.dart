import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:supertonic_audiobook/features/convert/data/helpers/text_preprocessor.dart';

/// Unicode indexer for TTS text encoding.
class UnicodeProcessor {
  final Map<int, int> indexer;

  UnicodeProcessor._(this.indexer);

  /// Load Unicode processor from a JSON file or asset.
  static Future<UnicodeProcessor> load(String path) async {
    final json = jsonDecode(
      path.startsWith('assets/')
          ? await rootBundle.loadString(path)
          : File(path).readAsStringSync(),
    );

    final indexer = json is List
        ? {
            for (var i = 0; i < json.length; i++)
              if (json[i] is int && json[i] >= 0) i: json[i] as int
          }
        : (json as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int));

    return UnicodeProcessor._(indexer);
  }

  /// Encode text lists into token IDs and masks.
  Map<String, dynamic> call(List<String> textList, List<String> langList) {
    // Preprocess texts with language tags
    final processedTexts = <String>[];
    for (var i = 0; i < textList.length; i++) {
      processedTexts.add(preprocessText(textList[i], langList[i]));
    }

    final lengths = processedTexts.map((t) => t.runes.length).toList();
    final maxLen = lengths.reduce(math.max);

    final textIds = processedTexts.map((text) {
      final row = List<int>.filled(maxLen, 0);
      final runes = text.runes.toList();
      for (var i = 0; i < runes.length; i++) {
        row[i] = indexer[runes[i]] ?? 0;
      }
      return row;
    }).toList();

    return {'textIds': textIds, 'textMask': _lengthToMask(lengths)};
  }

  List<List<List<double>>> _lengthToMask(List<int> lengths, [int? maxLen]) {
    maxLen ??= lengths.reduce(math.max);
    return lengths
        .map((len) => [List.generate(maxLen!, (i) => i < len ? 1.0 : 0.0)])
        .toList();
  }
}
