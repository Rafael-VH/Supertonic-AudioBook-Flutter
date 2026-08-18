import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/shared/data/config.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/file_system_local.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/features/settings/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

class MotorFalso implements MotorTts {
  @override
  Future<void> cambiarVoz(String voz) async {}

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    return Float32List(100);
  }
}

class RepositorioArchivosFalso implements RepositorioArchivos {
  RepositorioArchivosFalso(this._contenidos);

  final Map<String, String> _contenidos;

  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {}

  @override
  List<Archivo> listarArchivosMd(String carpeta) => [];

  @override
  List<String> listarAudios(String carpeta) => [];

  @override
  String leerArchivo(String ruta) => _contenidos[ruta]!;
}

class ExportadorFalso implements ExportadorAudio {
  final List<Float32List> escritos = [];

  @override
  Future<void> escribirAudio(
      List<Float32List> fragmentos, String ruta, String formato) async {
    escritos.addAll(fragmentos);
  }

  @override
  Future<void> wavAppend(List<Float32List> fragmentos, String ruta) async {}

  @override
  Future<void> convertirDesdeWav(
      String rutaWav, String rutaDestino, String formato) async {}

  @override
  Future<double> duracionAudio(String ruta) async => 0.0;
}

class PreferenciasMemoria implements RepositorioPreferencias {
  PreferenciasMemoria([Map<String, Object>? inicial])
      : _datos = {...?inicial};

  final Map<String, Object> _datos;

  @override
  Map<String, Object> cargar() => Map.of(_datos);

  @override
  void guardar(Map<String, Object> preferencias) {
    _datos..clear()..addAll(preferencias);
  }
}

void main() {
  group('providers de contratos', () {
    test('sin inyección fallan rápido (la app solo corre con el grafo armado)',
        () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      // Riverpod 3 envuelve el error original en ProviderException; lo que
      // importa es que el mensaje del contrato sin inyectar llegue intacto.
      final fallaComposicion = throwsA(
        predicate<Object>(
          (e) => e.toString().contains('se inyecta en main.dart'),
        ),
      );

      expect(() => contenedor.read(motorTtsProvider), fallaComposicion);
      expect(() => contenedor.read(repositorioArchivosProvider),
          fallaComposicion);
      expect(() => contenedor.read(exportadorAudioProvider), fallaComposicion);
      expect(() => contenedor.read(fileSystemProvider), fallaComposicion);
      expect(() => contenedor.read(repositorioPreferenciasProvider),
          fallaComposicion);
      expect(() => contenedor.read(reproductorAudioProvider), fallaComposicion);
      expect(() => contenedor.read(modeloManagerProvider), fallaComposicion);
      expect(() => contenedor.read(configTtsProvider), fallaComposicion);
      expect(() => contenedor.read(procesarArchivoProvider), fallaComposicion);
      expect(() => contenedor.read(sintetizarMuestraProvider),
          fallaComposicion);
    });

    test('configTtsProvider propaga los valores exactos de §5.1', () {
      final contenedor = ProviderContainer(overrides: [
        configTtsProvider.overrideWithValue((
          silencioMuestras: silenceSamples,
          memoriaSafeMarginBytes: memoriaSafeMarginBytes,
          topeMovilBytes: memoriaSafeMarginBytesMovil,
          esMovil: false,
        )),
      ]);
      addTearDown(contenedor.dispose);

      final config = contenedor.read(configTtsProvider);
      expect(config.silencioMuestras, 26460);
      expect(config.memoriaSafeMarginBytes, 524288000);
      expect(config.topeMovilBytes, 67108864);
      expect(config.esMovil, false);
    });

    test(
        'procesarArchivoProvider compone el caso de uso con la config '
        'inyectada desde la composición', () async {
      final carpetaTmp = Directory.systemTemp.createTempSync('providers_test');
      addTearDown(() => carpetaTmp.deleteSync(recursive: true));

      final entrada = File('${carpetaTmp.path}${Platform.pathSeparator}cap1.md')
        ..writeAsStringSync('Hola mundo.');
      final salida = '${carpetaTmp.path}${Platform.pathSeparator}out';
      final motor = MotorFalso();
      final archivos = RepositorioArchivosFalso({entrada.path: 'Hola mundo.'});
      final exportador = ExportadorFalso();

      final contenedor = ProviderContainer(overrides: [
        motorTtsProvider.overrideWithValue(motor),
        repositorioArchivosProvider.overrideWithValue(archivos),
        exportadorAudioProvider.overrideWithValue(exportador),
        fileSystemProvider.overrideWithValue(FileSystemLocal()),
        configTtsProvider.overrideWithValue((
          silencioMuestras: silenceSamples,
          memoriaSafeMarginBytes: memoriaSafeMarginBytes,
          topeMovilBytes: memoriaSafeMarginBytesMovil,
          esMovil: false,
        )),
      ]);
      addTearDown(contenedor.dispose);

      final procesar = contenedor.read(procesarArchivoProvider);
      await procesar.procesar(
        Archivo(entrada.path),
        salida,
        steps: 5,
        speed: 1.1,
        formatos: const ['wav'],
      );

      // El silencio entre fragmentos llega desde la composición: 26460 muestras.
      expect(exportador.escritos, hasLength(2));
      expect(exportador.escritos[0], hasLength(100));
      expect(exportador.escritos[1], hasLength(silenceSamples));
    });
  });

  group('SettingsController', () {
    test('usa los defaults de §6.3 cuando no hay preferencias', () {
      final repo = PreferenciasMemoria();
      final contenedor = ProviderContainer(overrides: [
        repositorioPreferenciasProvider.overrideWithValue(repo),
        carpetaBaseProvider.overrideWithValue('/tmp/base'),
      ]);
      addTearDown(contenedor.dispose);

      final estado = contenedor.read(settingsControllerProvider);
      expect(estado.temaOscuro, false);
      expect(estado.estilo, AppEstilo.material);
      expect(estado.idioma, 'es');
      expect(repo.cargar(), isEmpty);
    });

    test('cada cambio persiste con las claves exactas de §6.3', () {
      final repo = PreferenciasMemoria();
      final contenedor = ProviderContainer(overrides: [
        repositorioPreferenciasProvider.overrideWithValue(repo),
        carpetaBaseProvider.overrideWithValue('/tmp/base'),
      ]);
      addTearDown(contenedor.dispose);

      contenedor.read(settingsControllerProvider.notifier).cambiarTemaOscuro(true);
      contenedor.read(settingsControllerProvider.notifier).cambiarEstilo(AppEstilo.neumo);
      contenedor.read(settingsControllerProvider.notifier).cambiarIdioma('en');

      final guardado = repo.cargar();
      expect(guardado['tema_oscuro'], true);
      expect(guardado['estilo'], 'neumo');
      expect(guardado['idioma'], 'en');
    });

    test('un nuevo arranque recarga las preferencias persistidas', () {
      final repo = PreferenciasMemoria();
      final contenedor = ProviderContainer(overrides: [
        repositorioPreferenciasProvider.overrideWithValue(repo),
        carpetaBaseProvider.overrideWithValue('/tmp/base'),
      ]);
      addTearDown(contenedor.dispose);
      contenedor.read(settingsControllerProvider.notifier).cambiarTemaOscuro(true);
      contenedor.read(settingsControllerProvider.notifier).cambiarEstilo(AppEstilo.skeuo);

      final contenedor2 = ProviderContainer(overrides: [
        repositorioPreferenciasProvider.overrideWithValue(repo),
        carpetaBaseProvider.overrideWithValue('/tmp/base'),
      ]);
      addTearDown(contenedor2.dispose);

      final recargado = contenedor2.read(settingsControllerProvider);
      expect(recargado.temaOscuro, true);
      expect(recargado.estilo, AppEstilo.skeuo);
      expect(recargado.idioma, 'es');
    });
  });
}
