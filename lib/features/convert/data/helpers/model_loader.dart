import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

final logger = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 80),
);

/// Copy an asset model file to a temp directory and return its path.
Future<String> copyModelToFile(String path) async {
  final byteData = await rootBundle.load(path);
  final tempDir = await getApplicationCacheDirectory();
  final modelPath = '${tempDir.path}/${path.split("/").last}';

  final file = File(modelPath);
  // Solo el view correcto del buffer: el ByteData puede empezar con offset.
  await file.writeAsBytes(
    byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
  );
  return modelPath;
}

/// Load TTS configuration from a JSON file.
Future<Map<String, dynamic>> loadCfgs(String onnxDir) async {
  final path = '$onnxDir/tts.json';
  final json = jsonDecode(
    path.startsWith('assets/')
        ? await rootBundle.loadString(path)
        : File(path).readAsStringSync(),
  );
  return json as Map<String, dynamic>;
}

/// Load all ONNX model sessions from a directory.
Future<Map<String, OrtSession>> loadOnnxAll(String dir) async {
  final ort = OnnxRuntime();
  final models = [
    'duration_predictor',
    'text_encoder',
    'vector_estimator',
    'vocoder'
  ];

  final sessions = await Future.wait(models.map((name) async {
    final path = '$dir/$name.onnx';
    final String modelPath;
    if (path.startsWith('assets/')) {
      modelPath = await copyModelToFile(path);
    } else {
      modelPath = path;
    }
    logger.d('Loading $name.onnx');
    return ort.createSession(modelPath);
  }));

  return {
    'dpOrt': sessions[0],
    'textEncOrt': sessions[1],
    'vectorEstOrt': sessions[2],
    'vocoderOrt': sessions[3],
  };
}
