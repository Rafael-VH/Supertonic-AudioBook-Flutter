import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/core/audio/wav_io.dart' as wav;
import 'package:supertonic_audiobook/features/convert/data/repositories/exportador_audio_ffmpeg.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/file_system_local.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/procesar_archivo.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/sintetizar_muestra.dart';

import '../../../../support/fakes.dart';

/// Devuelve [cantidad] muestras float32 (1 s de silencio = 44100 muestras).
Float32List _audio(double segundos) => Float32List((segundos * wav.wavSampleRate).round());

/// Párrafo largo (> mergeThreshold = 200) para que NO se fusione con el
/// siguiente en `segmentarTexto` y el test controle los segmentos.
String _parrafoLargo() => '${'Palabra '.padRight(230, 'a')}.';

class _FakeMotor implements MotorTts {
  _FakeMotor({this.fallar = false, this.vaciar = false});

  final bool fallar;
  final bool vaciar;
  final List<String> textosSintetizados = [];
  int llamadas = 0;

  @override
  Future<void> cambiarVoz(String voz) async {}

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    llamadas++;
    if (fallar) throw Exception('motor caído');
    if (vaciar) return Float32List(0);
    textosSintetizados.add(texto);
    return _audio(1.0);
  }
}

class _FakeRepositorio implements RepositorioArchivos {
  _FakeRepositorio(this._contenido);

  final String _contenido;
  String? ultimaRutaLeida;

  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {}

  @override
  List<Archivo> listarArchivosMd(String carpeta) => const [];

  @override
  List<String> listarAudios(String carpeta) => const [];

  @override
  String leerArchivo(String ruta) {
    ultimaRutaLeida = ruta;
    if (_contenido == 'ERROR') throw const FileSystemException('no legible');
    return _contenido;
  }
}

/// Exportador que falla al convertir los formatos en [formatosQueFallan]
/// pero funciona para el resto (WAV siempre funciona).
class _ExportadorSelectivo implements ExportadorAudio {
  _ExportadorSelectivo({required this.formatosQueFallan});

  final Set<String> formatosQueFallan;

  @override
  Future<void> escribirAudio(
      List<Float32List> fragmentos, String ruta, String formato) async {
    if (formatosQueFallan.contains(formato)) {
      throw StateError('FFmpeg falló al convertir a $formato');
    }
    wav.escribirWav(fragmentos, ruta);
  }

  @override
  Future<void> wavAppend(List<Float32List> fragmentos, String ruta) async {
    wav.wavAppend(fragmentos, ruta);
  }

  @override
  Future<void> convertirDesdeWav(
      String rutaWav, String rutaDestino, String formato) async {
    if (formatosQueFallan.contains(formato)) {
      throw StateError('FFmpeg falló al convertir a $formato');
    }
    // Para formatos selectivos que no fallan, escribimos un WAV simple
    // (suficiente para el test de publicación).
    final datos = File(rutaWav).readAsBytesSync();
    File(rutaDestino).writeAsBytesSync(datos);
  }

  @override
  Future<double> duracionAudio(String ruta) async {
    if (!File(ruta).existsSync()) return 0.0;
    if (ruta.toLowerCase().endsWith('.wav')) return wav.duracionWav(ruta);
    return 0.0;
  }
}

ProcesarArchivo _caso(
  MotorTts motor,
  RepositorioArchivos archivos, {
  int silencio = 0,
  int margenMemoria = 1 << 30,
  ExportadorAudio? exportador,
}) {
  return ProcesarArchivo(
    motor: motor,
    archivos: archivos,
    exportador: exportador ?? ExportadorAudioFfmpeg(),
    fileSystem: FileSystemLocal(),
    silencioMuestras: silencio,
    memoriaSafeMarginBytes: margenMemoria,
    topeMovilBytes: margenMemoria,
    logger: NoOpLogger(),
  );
}

void main() {
  final exportador = ExportadorAudioFfmpeg();
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('procesar_integracion');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  group('ProcesarArchivo (integración)', () {
    test('convierte un markdown a WAV y reporta progreso', () async {
      final motor = _FakeMotor();
      final caso = _caso(motor, _FakeRepositorio('${_parrafoLargo()}\n\n${_parrafoLargo()}'));
      final progresos = <int>[];

      final resultado = await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
        onProgreso: (procesados, total) => progresos.add(procesados),
      );

      expect(resultado.estado, ResultadoProceso.ok);
      expect(resultado.segmentos, 2);
      final ruta = '${temp.path}/salida.wav';
      expect(File(ruta).existsSync(), isTrue);
      // 2 segmentos de 1 s = 2.0 s (sin silencio intermedio).
      expect(wav.duracionWav(ruta), closeTo(2.0, 1e-6));
      expect(progresos, [1, 2]);
      expect(motor.llamadas, 2);
    });

    test('no deja archivos temporales al terminar', () async {
      final caso = _caso(_FakeMotor(), _FakeRepositorio('Texto.'));
      await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
      );
      final sobrantes = temp
          .listSync()
          .where((e) => e.path.contains('.tmp_'))
          .toList();
      expect(sobrantes, isEmpty);
    });

    test('deduplica formatos repetidos', () async {
      final caso = _caso(_FakeMotor(), _FakeRepositorio('Texto.'));
      await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav', 'wav'],
      );
      expect(File('${temp.path}/salida.wav').existsSync(), isTrue);
    });

    test('cancela a mitad de camino y exporta lo generado', () async {
      final motor = _FakeMotor();
      final caso = _caso(
          motor,
          _FakeRepositorio(
              '${_parrafoLargo()}\n\n${_parrafoLargo()}\n\n${_parrafoLargo()}'));
      var vueltas = 0;

      final resultado = await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
        debeDetenerse: () => ++vueltas > 1,
      );

      // Se sintetizó 1 segmento; el resto nunca se procesó.
      expect(resultado.estado, ResultadoProceso.ok);
      expect(motor.llamadas, 1);
      final ruta = '${temp.path}/salida.wav';
      expect(File(ruta).existsSync(), isTrue);
      expect(wav.duracionWav(ruta), closeTo(1.0, 1e-6));
    });

    test('cancelar conserva el output previo y publica solo destinos nuevos',
        () async {
      // Output previo COMPLETO (9 s) de una corrida anterior.
      final previo = '${temp.path}/salida.wav';
      wav.escribirWav([_audio(9.0)], previo);

      final motor = _FakeMotor();
      final caso = _caso(
          motor,
          _FakeRepositorio(
              '${_parrafoLargo()}\n\n${_parrafoLargo()}\n\n${_parrafoLargo()}'));
      var vueltas = 0;

      await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
        debeDetenerse: () => ++vueltas > 1,
      );

      // Solo se sintetizó 1 segmento (1 s) y el destino YA existía: la
      // cancelación no debe pisar el audio previo con el truncado.
      expect(motor.llamadas, 1);
      expect(wav.duracionWav(previo), closeTo(9.0, 1e-6));
    });

    test('vuelca a disco por límite de memoria y arma el WAV final', () async {
      final caso = _caso(
          _FakeMotor(),
          _FakeRepositorio(
              '${_parrafoLargo()}\n\n${_parrafoLargo()}\n\n${_parrafoLargo()}'),
          margenMemoria: 0);
      await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
      );
      final ruta = '${temp.path}/salida.wav';
      expect(File(ruta).existsSync(), isTrue);
      expect(wav.duracionWav(ruta), closeTo(3.0, 1e-6));
    });

    test('omite archivos vacíos tras limpiar', () async {
      final motor = _FakeMotor();
      // Un bloque de código se elimina completo → el texto queda vacío.
      final caso = _caso(motor, _FakeRepositorio('```\nbloque\n```'));
      final resultado = await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
      );
      expect(resultado.estado, ResultadoProceso.omitido);
      expect(motor.llamadas, 0);
      expect(File('${temp.path}/salida.wav').existsSync(), isFalse);
    });

    test('devuelve error si el archivo de entrada no se puede leer', () async {
      final caso = _caso(_FakeMotor(), _FakeRepositorio('ERROR'));
      final resultado = await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
      );
      expect(resultado.estado, ResultadoProceso.error);
      expect(File('${temp.path}/salida.wav').existsSync(), isFalse);
    });

    test('si el motor no genera audio, no publica nada', () async {
      final caso = _caso(_FakeMotor(vaciar: true), _FakeRepositorio('Texto.'));
      final resultado = await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['wav'],
      );
      expect(resultado.estado, ResultadoProceso.omitido);
      expect(File('${temp.path}/salida.wav').existsSync(), isFalse);
    });

    test('no reemplaza el WAV previo si el destino está en uso (Windows)',
        () async {
      final previo = '${temp.path}/salida.wav';
      wav.escribirWav([_audio(9.0)], previo);
      final raf = File(previo).openSync(mode: FileMode.append);
      try {
        final caso = _caso(_FakeMotor(), _FakeRepositorio('Texto.'));
        await expectLater(
          caso.procesar(
            Archivo('${temp.path}/in.md'),
            '${temp.path}/salida',
            steps: 5,
            speed: 1.1,
            formatos: ['wav'],
          ),
          throwsA(isA<FileSystemException>()),
        );
        // El WAV previo quedó intacto (9.0 s).
        expect(wav.duracionWav(previo), closeTo(9.0, 1e-6));
      } finally {
        raf.closeSync();
      }
    }, skip: !Platform.isWindows ? 'El lock de archivo es de Windows' : null);

    test('si un formato falla, publica los que sí convirtieron', () async {
      // FLAC falla, MP3 y WAV funcionan.
      final exportador = _ExportadorSelectivo(formatosQueFallan: {'flac'});
      final caso = _caso(
        _FakeMotor(),
        _FakeRepositorio('Texto.'),
        exportador: exportador,
      );

      final resultado = await caso.procesar(
        Archivo('${temp.path}/in.md'),
        '${temp.path}/salida',
        steps: 5,
        speed: 1.1,
        formatos: ['mp3', 'flac', 'wav'],
      );

      expect(resultado.estado, ResultadoProceso.ok);
      // MP3 y WAV se publicaron; FLAC no (fallo de conversión).
      expect(File('${temp.path}/salida.mp3').existsSync(), isTrue);
      expect(File('${temp.path}/salida.wav').existsSync(), isTrue);
      expect(File('${temp.path}/salida.flac').existsSync(), isFalse);
    });
  });

  group('SintetizarMuestra (integración)', () {
    test('escribe el WAV de muestra y devuelve la ruta', () async {
      final caso = SintetizarMuestra(
        motor: _FakeMotor(),
        exportador: exportador,
        logger: NoOpLogger(),
      );
      final ruta = '${temp.path}/muestra.wav';
      final resultado = await caso.generar('Hola', ruta: ruta);

      expect(resultado, ruta);
      expect(File(ruta).existsSync(), isTrue);
      expect(wav.duracionWav(ruta), closeTo(1.0, 1e-6));
    });

    test('con el motor caído relanza el error sin crear archivo', () async {
      final caso = SintetizarMuestra(
        motor: _FakeMotor(fallar: true),
        exportador: exportador,
        logger: NoOpLogger(),
      );
      final ruta = '${temp.path}/muestra.wav';

      expect(
        () => caso.generar('Hola', ruta: ruta),
        throwsA(isA<Exception>()),
      );
      expect(File(ruta).existsSync(), isFalse);
    });

    test('con audio vacío escribe un WAV de cero muestras', () async {
      final caso = SintetizarMuestra(
        motor: _FakeMotor(vaciar: true),
        exportador: exportador,
        logger: NoOpLogger(),
      );
      final ruta = '${temp.path}/muestra.wav';
      final resultado = await caso.generar('Hola', ruta: ruta);

      expect(resultado, ruta);
      expect(File(ruta).existsSync(), isTrue);
      expect(wav.duracionWav(ruta), 0.0);
    });
  });
}
