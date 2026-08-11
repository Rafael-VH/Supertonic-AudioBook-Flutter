import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/core/audio/wav_io.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('wav_io_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  group('escribirWav', () {
    test('escribe header RIFF/WAVE PCM16 mono 44100 y los samples', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([Float32List.fromList([0.0, 0.5, -0.5])], ruta);

      final bytes = File(ruta).readAsBytesSync();
      expect(bytes.sublist(0, 4), 'RIFF'.codeUnits);
      expect(bytes.sublist(8, 12), 'WAVE'.codeUnits);
      expect(bytes.sublist(12, 16), 'fmt '.codeUnits);
      final bd = ByteData.sublistView(bytes);
      // chunk_size del RIFF: 36 + 6 bytes de datos = 42
      expect(bd.getUint32(4, Endian.little), 42);
      expect(bd.getUint16(20, Endian.little), 1); // PCM
      expect(bd.getUint16(22, Endian.little), 1); // mono
      expect(bd.getUint32(24, Endian.little), 44100);
      expect(bd.getUint32(28, Endian.little), 88200); // byteRate
      expect(bd.getUint16(32, Endian.little), 2); // blockAlign
      expect(bd.getUint16(34, Endian.little), 16); // bits
      expect(bytes.sublist(36, 40), 'data'.codeUnits);
      expect(bd.getUint32(40, Endian.little), 6);
    });

    test('convierte float32 a int16 con clip * 32767 redondeado', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([Float32List.fromList([0.0, 0.5, -0.5, 1.0, -1.0])], ruta);

      final bd = ByteData.sublistView(File(ruta).readAsBytesSync(), 44);
      expect(bd.getInt16(0, Endian.little), 0);
      expect(bd.getInt16(2, Endian.little), 16384);
      expect(bd.getInt16(4, Endian.little), -16384);
      expect(bd.getInt16(6, Endian.little), 32767);
      expect(bd.getInt16(8, Endian.little), -32767);
    });

    test('concatena varios fragmentos en orden', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([
        Float32List.fromList([0.0, 0.0]),
        Float32List.fromList([1.0]),
      ], ruta);

      final bd = ByteData.sublistView(File(ruta).readAsBytesSync(), 44);
      expect(bd.getInt16(0, Endian.little), 0);
      expect(bd.getInt16(2, Endian.little), 0);
      expect(bd.getInt16(4, Endian.little), 32767);
    });

    test('clipea valores fuera de rango', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([Float32List.fromList([2.0, -2.0])], ruta);

      final bd = ByteData.sublistView(File(ruta).readAsBytesSync(), 44);
      expect(bd.getInt16(0, Endian.little), 32767);
      expect(bd.getInt16(2, Endian.little), -32767);
    });

    test('crea las carpetas padre si no existen', () {
      final ruta = '${temp.path}/sub/dir/a.wav';
      escribirWav([Float32List.fromList([0.0])], ruta);
      expect(File(ruta).existsSync(), isTrue);
    });
  });

  group('wavAppend', () {
    test('crea un WAV completo si el archivo no existe', () {
      final ruta = '${temp.path}/a.wav';
      wavAppend([Float32List.fromList([0.0, 0.5])], ruta);

      expect(File(ruta).existsSync(), isTrue);
      final bytes = File(ruta).readAsBytesSync();
      expect(bytes.sublist(0, 4), 'RIFF'.codeUnits);
      // 36 + 4 bytes = 40
      expect(ByteData.sublistView(bytes).getUint32(4, Endian.little), 40);
    });

    test('anexa samples y parchea los tamaños del header', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([Float32List.fromList([0.0, 0.5])], ruta);
      wavAppend([Float32List.fromList([-0.5, 1.0])], ruta);

      final bytes = File(ruta).readAsBytesSync();
      final bd = ByteData.sublistView(bytes);
      // 36 + 8 bytes de datos = 44
      expect(bd.getUint32(4, Endian.little), 44);
      expect(bd.getUint32(40, Endian.little), 8); // chunk data
      final datos = ByteData.sublistView(bytes, 44);
      expect(datos.getInt16(0, Endian.little), 0);
      expect(datos.getInt16(2, Endian.little), 16384);
      expect(datos.getInt16(4, Endian.little), -16384);
      expect(datos.getInt16(6, Endian.little), 32767);
    });

    test('no hace nada con fragmentos vacíos', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([Float32List.fromList([0.0])], ruta);
      final antes = File(ruta).lengthSync();
      wavAppend(const [], ruta);
      expect(File(ruta).lengthSync(), antes);
    });
  });

  group('duracionWav', () {
    test('calcula la duración desde el header sin cargar el contenido', () {
      final ruta = '${temp.path}/a.wav';
      // 88200 muestras mono a 44100 Hz = 2.0 s
      escribirWav([Float32List(88200)], ruta);
      expect(duracionWav(ruta), closeTo(2.0, 1e-9));
    });

    test('refleja el append en la duración', () {
      final ruta = '${temp.path}/a.wav';
      escribirWav([Float32List(44100)], ruta);
      wavAppend([Float32List(44100)], ruta);
      expect(duracionWav(ruta), closeTo(2.0, 1e-9));
    });

    test('devuelve 0.0 si el archivo no existe', () {
      expect(duracionWav('${temp.path}/no_existe.wav'), 0.0);
    });

    test('devuelve 0.0 para contenido corrupto', () {
      final ruta = '${temp.path}/basura.wav';
      File(ruta).writeAsBytesSync(List.filled(64, 0xAB));
      expect(duracionWav(ruta), 0.0);
    });
  });
}
