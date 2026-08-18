import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/core/audio/wav_io.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/exportador_audio_ffmpeg.dart';

/// True si FFmpeg está disponible en el entorno de ejecución (en `flutter test`
/// el plugin no está registrado y lanza MissingPluginException → los tests de
/// conversión se saltan; en el dispositivo corren de verdad).
///
/// Se ejecuta en un zone con guarda porque la inicialización del plugin
/// suelta errores asíncronos que escapan de cualquier `try/catch`.
Future<bool>? _ffmpegDisponible;

Future<bool> _probarFfmpeg() {
  return _ffmpegDisponible ??= _probarFfmpegUnaVez();
}

Future<bool> _probarFfmpegUnaVez() {
  final completer = Completer<bool>();
  runZonedGuarded(() {
    FFmpegKit.execute('-version').then((sesion) async {
      final rc = await sesion.getReturnCode();
      completer.complete(ReturnCode.isSuccess(rc));
    }).catchError((_) {
      if (!completer.isCompleted) completer.complete(false);
    });
  }, (Object error, StackTrace stack) {
    // Errores asíncronos del plugin en entornos sin FFmpeg caen acá.
    if (!completer.isCompleted) completer.complete(false);
  });
  return completer.future;
}

void main() {
  final exportador = ExportadorAudioFfmpeg();
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('exportador_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  group('escribirAudio', () {
    test('wav: escribe un WAV PCM16 con la duración esperada', () async {
      final ruta = '${temp.path}/a.wav';
      await exportador.escribirAudio(
          [Float32List(22050), Float32List(22050)], ruta, 'wav');

      expect(File(ruta).existsSync(), isTrue);
      final bytes = File(ruta).readAsBytesSync();
      expect(bytes.sublist(0, 4), 'RIFF'.codeUnits);
      expect(duracionWav(ruta), closeTo(1.0, 1e-9));
    });

    test('wav: crea las carpetas padre', () async {
      final ruta = '${temp.path}/sub/dir/a.wav';
      await exportador.escribirAudio([Float32List(44100)], ruta, 'wav');
      expect(File(ruta).existsSync(), isTrue);
    });

    test('wav: no escribe nada con fragmentos vacíos', () async {
      final ruta = '${temp.path}/a.wav';
      await exportador.escribirAudio(const [], ruta, 'wav');
      expect(File(ruta).existsSync(), isFalse);
    });

    test('no-wav: re-encoda vía FFmpeg (skip si no disponible)', () async {
      if (!await _probarFfmpeg()) {
        markTestSkipped('FFmpeg no disponible en este entorno');
        return;
      }
      final ruta = '${temp.path}/a.flac';
      await exportador.escribirAudio([Float32List(44100)], ruta, 'flac');
      expect(File(ruta).existsSync(), isTrue);
      expect(File(ruta).lengthSync(), greaterThan(0));
    });

    test('formato desconocido: lanza ArgumentError', () async {
      await expectLater(
        exportador.escribirAudio([Float32List(10)], '${temp.path}/a.xyz', 'xyz'),
        throwsArgumentError,
      );
    });
  });

  group('wavAppend', () {
    test('crea el WAV si no existe', () async {
      final ruta = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(44100)], ruta);
      expect(File(ruta).existsSync(), isTrue);
      expect(duracionWav(ruta), closeTo(1.0, 1e-9));
    });

    test('anexa samples y refleja la duración acumulada', () async {
      final ruta = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(44100)], ruta);
      await exportador.wavAppend([Float32List(44100)], ruta);
      expect(duracionWav(ruta), closeTo(2.0, 1e-9));
    });
  });

  group('convertirDesdeWav', () {
    test('formato inválido: lanza ArgumentError sin tocar FFmpeg', () async {
      final wav = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(44100)], wav);
      await expectLater(
        exportador.convertirDesdeWav(wav, '${temp.path}/a.xyz', 'xyz'),
        throwsArgumentError,
      );
    });

    test('convierte WAV a flac (skip si no disponible)', () async {
      if (!await _probarFfmpeg()) {
        markTestSkipped('FFmpeg no disponible en este entorno');
        return;
      }
      final wav = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(44100)], wav);
      final destino = '${temp.path}/a.flac';
      await exportador.convertirDesdeWav(wav, destino, 'flac');
      expect(File(destino).existsSync(), isTrue);
      expect(File(destino).lengthSync(), greaterThan(0));
    });

    test('sobrescribe un destino pre-creado (caso ProcesarArchivo) (skip si no disponible)', () async {
      // Regresión: ProcesarArchivo._nuevoTemporal pre-crea el destino vacío;
      // FFmpeg abortaría con "Not overwriting" (rc=1) sin el flag -y.
      if (!await _probarFfmpeg()) {
        markTestSkipped('FFmpeg no disponible en este entorno');
        return;
      }
      final wav = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(44100)], wav);
      final destino = '${temp.path}/a.flac';
      File(destino).createSync();
      await exportador.convertirDesdeWav(wav, destino, 'flac');
      expect(File(destino).existsSync(), isTrue);
      expect(File(destino).lengthSync(), greaterThan(0));
    });
  });

  group('duracionAudio', () {
    test('wav existente: duración desde el header', () async {
      final ruta = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(88200)], ruta);
      expect(await exportador.duracionAudio(ruta), closeTo(2.0, 1e-9));
    });

    test('archivo inexistente: 0.0', () async {
      expect(await exportador.duracionAudio('${temp.path}/no.wav'), 0.0);
    });

    test('wav corrupto: 0.0', () async {
      final ruta = '${temp.path}/basura.wav';
      File(ruta).writeAsBytesSync(List.filled(64, 0xAB));
      expect(await exportador.duracionAudio(ruta), 0.0);
    });

    test('no-wav: duración por ffprobe (skip si no disponible)', () async {
      if (!await _probarFfmpeg()) {
        markTestSkipped('FFmpeg no disponible en este entorno');
        return;
      }
      final wav = '${temp.path}/a.wav';
      await exportador.wavAppend([Float32List(88200)], wav);
      final flac = '${temp.path}/a.flac';
      await exportador.convertirDesdeWav(wav, flac, 'flac');
      expect(await exportador.duracionAudio(flac), closeTo(2.0, 0.2));
    });
  });
}
