import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/audio_manager/domain/use_cases/limpiar_temporales.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';

/// Fake de RepositorioArchivos para tests de LimpiarTemporales.
class _FakeArchivos implements RepositorioArchivos {
  _FakeArchivos({
    required this.audios,
    required this.fechas,
  });

  final List<String> audios;
  final Map<String, DateTime?> fechas;
  final List<String> eliminados = [];

  @override
  List<String> listarAudios(String carpeta) => audios;

  @override
  DateTime? fechaModificacion(String ruta) => fechas[ruta];

  @override
  void eliminarSiExiste(String ruta) => eliminados.add(ruta);

  // Stub de métodos no usados por LimpiarTemporales.
  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {}
  @override
  List<Archivo> listarArchivosMd(String carpeta) => [];
  @override
  String leerArchivo(String ruta) => '';
  @override
  bool existe(String ruta) => false;
  @override
  void moverArchivo(String origen, String destino) {}
  @override
  String get pathSeparator => '/';
}

void main() {
  group('LimpiarTemporales.ejecutar', () {
    test('elimina audios mayores a 24h', () {
      final ahora = DateTime.now();
      final fake = _FakeArchivos(
        audios: ['/temp/old.wav', '/temp/recent.wav'],
        fechas: {
          '/temp/old.wav': ahora.subtract(const Duration(hours: 25)),
          '/temp/recent.wav': ahora.subtract(const Duration(hours: 1)),
        },
      );

      final limpiar = LimpiarTemporales(archivos: fake);
      limpiar.ejecutar(carpetaTemp: '/temp');

      expect(fake.eliminados, ['/temp/old.wav']);
    });

    test('preserva archivos recientes', () {
      final ahora = DateTime.now();
      final fake = _FakeArchivos(
        audios: ['/temp/recent.wav'],
        fechas: {
          '/temp/recent.wav': ahora.subtract(const Duration(hours: 1)),
        },
      );

      final limpiar = LimpiarTemporales(archivos: fake);
      limpiar.ejecutar(carpetaTemp: '/temp');

      expect(fake.eliminados, isEmpty);
    });

    test('lista vacía no elimina nada', () {
      final fake = _FakeArchivos(audios: [], fechas: {});

      final limpiar = LimpiarTemporales(archivos: fake);
      limpiar.ejecutar(carpetaTemp: '/temp');

      expect(fake.eliminados, isEmpty);
    });

    test('audio sin fecha de modificación se preserva', () {
      final fake = _FakeArchivos(
        audios: ['/temp/no-date.wav'],
        fechas: {'/temp/no-date.wav': null},
      );

      final limpiar = LimpiarTemporales(archivos: fake);
      limpiar.ejecutar(carpetaTemp: '/temp');

      expect(fake.eliminados, isEmpty);
    });

    test('elimina múltiples audios viejos', () {
      final ahora = DateTime.now();
      final fake = _FakeArchivos(
        audios: ['/temp/a.wav', '/temp/b.wav', '/temp/c.wav'],
        fechas: {
          '/temp/a.wav': ahora.subtract(const Duration(hours: 48)),
          '/temp/b.wav': ahora.subtract(const Duration(hours: 2)),
          '/temp/c.wav': ahora.subtract(const Duration(hours: 30)),
        },
      );

      final limpiar = LimpiarTemporales(archivos: fake);
      limpiar.ejecutar(carpetaTemp: '/temp');

      expect(fake.eliminados, ['/temp/a.wav', '/temp/c.wav']);
    });
  });
}
