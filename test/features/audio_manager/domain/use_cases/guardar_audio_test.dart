import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/audio_manager/domain/use_cases/guardar_audio.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';

/// Fake de RepositorioArchivos para tests de GuardarAudio.
class _FakeArchivos implements RepositorioArchivos {
  _FakeArchivos({Set<String> existentes = const {}})
      : _existentes = {...existentes};

  final Set<String> _existentes;
  final List<(String, String)> movidos = [];
  final List<List<String>> carpetasCreadas = [];

  void simularConflicto(String ruta) => _existentes.add(ruta);

  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) =>
      carpetasCreadas.add(carpetas);

  @override
  bool existe(String ruta) => _existentes.contains(ruta);

  @override
  void moverArchivo(String origen, String destino) {
    movidos.add((origen, destino));
    _existentes.add(destino);
  }

  @override
  String get pathSeparator => '/';

  // Stub de métodos no usados por GuardarAudio.
  @override
  List<Archivo> listarArchivosMd(String carpeta) => [];
  @override
  List<String> listarAudios(String carpeta) => [];
  @override
  String leerArchivo(String ruta) => '';
  @override
  void eliminarSiExiste(String ruta) {}
  @override
  DateTime? fechaModificacion(String ruta) => null;
}

void main() {
  group('GuardarAudio.ejecutar', () {
    test('mueve temporal a destino final', () {
      final archivos = _FakeArchivos();
      final guardar = GuardarAudio(archivos: archivos);

      final resultado = guardar.ejecutar(
        tempPath: '/tmp/_temp/audio_123.wav',
        carpetaDestino: '/out',
        nombreArchivo: 'Capitulo 1.wav',
      );

      expect(resultado, '/out/Capitulo 1.wav');
      expect(archivos.movidos, [('/tmp/_temp/audio_123.wav', '/out/Capitulo 1.wav')]);
      expect(archivos.carpetasCreadas, [['/out']]);
    });

    test('resuelve conflicto con sufijo (1)', () {
      final archivos = _FakeArchivos();
      archivos.simularConflicto('/out/Capitulo 1.wav');
      final guardar = GuardarAudio(archivos: archivos);

      final resultado = guardar.ejecutar(
        tempPath: '/tmp/_temp/audio_123.wav',
        carpetaDestino: '/out',
        nombreArchivo: 'Capitulo 1.wav',
      );

      expect(resultado, '/out/Capitulo 1(1).wav');
    });

    test('resuelve múltiples conflictos', () {
      final archivos = _FakeArchivos();
      archivos.simularConflicto('/out/Capitulo 1.wav');
      archivos.simularConflicto('/out/Capitulo 1(1).wav');
      final guardar = GuardarAudio(archivos: archivos);

      final resultado = guardar.ejecutar(
        tempPath: '/tmp/_temp/audio_123.wav',
        carpetaDestino: '/out',
        nombreArchivo: 'Capitulo 1.wav',
      );

      expect(resultado, '/out/Capitulo 1(1)(2).wav');
    });

    test('sin conflicto no agrega sufijo', () {
      final archivos = _FakeArchivos();
      final guardar = GuardarAudio(archivos: archivos);

      final resultado = guardar.ejecutar(
        tempPath: '/tmp/_temp/audio_123.wav',
        carpetaDestino: '/out',
        nombreArchivo: 'libro.wav',
      );

      expect(resultado, '/out/libro.wav');
    });
  });
}
