import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../../core/audio/wav_io.dart' as wav;
import '../../domain/contracts/exportador_audio.dart';

/// Implementación del contrato [ExportadorAudio] sobre FFmpeg.
///
/// El WAV PCM16 se escribe directamente con [wav] (Dart puro, sin FFmpeg);
/// el resto de los formatos se re-encodan desde un WAV temporal con FFmpeg.
/// FFmpeg lee el WAV desde el archivo y vuelca el resultado también a
/// archivo, por lo que nunca se carga el audio completo en memoria (streaming
/// por bloques).
class ExportadorAudioFfmpeg implements ExportadorAudio {
  /// Codecs de salida por formato (paridad con `sf.write`).
  static const Map<String, String> _codecs = {
    'flac': 'flac',
    'ogg': 'libvorbis',
    'mp3': 'libmp3lame',
  };

  @override
  Future<void> escribirAudio(
      List<Float32List> fragmentos, String ruta, String formato) async {
    if (fragmentos.isEmpty) return;
    if (formato == 'wav') {
      wav.escribirWav(fragmentos, ruta);
      return;
    }
    final temporal = '$ruta.ffmpeg_tmp.wav';
    wav.escribirWav(fragmentos, temporal);
    try {
      await convertirDesdeWav(temporal, ruta, formato);
    } finally {
      try {
        File(temporal).deleteSync();
      } catch (_) {
        // Paridad: un temporal que no se pueda borrar no invalida el resultado.
      }
    }
  }

  @override
  Future<void> wavAppend(List<Float32List> fragmentos, String ruta) async {
    wav.wavAppend(fragmentos, ruta);
  }

  @override
  Future<void> convertirDesdeWav(
      String rutaWav, String rutaDestino, String formato) async {
    final codec = _codecs[formato];
    if (codec == null) {
      throw ArgumentError.value(formato, 'formato',
          'Formato de audio no soportado (se espera wav, flac, ogg o mp3)');
    }
    File(rutaDestino).parent.createSync(recursive: true);
    final sesion = await FFmpegKit.executeWithArguments(
        ['-i', rutaWav, '-c:a', codec, '-f', formato, rutaDestino]);
    final codigo = await sesion.getReturnCode();
    if (!ReturnCode.isSuccess(codigo)) {
      final logs = await sesion.getAllLogs();
      final detalle = logs.map((l) => l.getMessage()).join('\n');
      throw StateError('FFmpeg falló (código $codigo) al convertir a $formato: '
          '$rutaWav → $rutaDestino\n$detalle');
    }
  }

  @override
  Future<double> duracionAudio(String ruta) async {
    if (!File(ruta).existsSync()) return 0.0;
    if (ruta.toLowerCase().endsWith('.wav')) return wav.duracionWav(ruta);
    try {
      final sesion = await FFprobeKit.getMediaInformation(ruta);
      final duracion = sesion.getMediaInformation()?.getDuration();
      return double.tryParse(duracion ?? '') ?? 0.0;
    } catch (_) {
      // FFmpeg no disponible o archivo ilegible → 0.0 (paridad).
      return 0.0;
    }
  }
}
