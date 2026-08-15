import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/domain/use_cases/procesar_archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/controllers/seleccion_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

import '../../support/fakes.dart';

/// Stub de [ProcesarArchivo] que registra los argumentos y permite
/// bloquear/avanzar el procesamiento para probar cancelación y progreso.
class ProcesarArchivoStub extends ProcesarArchivo {
  ProcesarArchivoStub({
    required super.motor,
    required super.archivos,
    required super.exportador,
    required super.silencioMuestras,
    required super.memoriaSafeMarginBytes,
  });

  final List<
      ({
        Archivo archivo,
        String rutaBase,
        int steps,
        double speed,
        List<String> formatos,
        String lang,
      })> llamadas = [];

  /// Si se define, `procesar` espera a que se complete antes de avanzar.
  Future<void> Function()? espera;

  /// Llamado antes de resolverse, para inyectar onProgreso/debeDetenerse.
  void Function(void Function(int, int) onProgreso, bool Function() detener)?
      alProcesar;

  @override
  Future<void> procesar(
    Archivo archivo,
    String rutaBase, {
    required int steps,
    required double speed,
    required List<String> formatos,
    String lang = 'es',
    void Function(int actual, int total)? onProgreso,
    bool Function()? debeDetenerse,
  }) async {
    llamadas.add((
      archivo: archivo,
      rutaBase: rutaBase,
      steps: steps,
      speed: speed,
      formatos: formatos,
      lang: lang,
    ));
    await espera?.call();
    if (alProcesar != null && onProgreso != null && debeDetenerse != null) {
      alProcesar!(onProgreso, debeDetenerse);
    }
  }
}

void main() {
  AppLocalizations es() => lookupAppLocalizations(const Locale('es'));

  group('HomeController', () {
    late PreferenciasMemoria preferencias;
    late RepositorioArchivosFake repositorio;
    late MotorFake motor;
    late ExportadorFake exportador;
    late ReproductorFake reproductor;
    late ProcesarArchivoStub procesador;

    ProviderContainer crearContenedor() => ProviderContainer(
          overrides: [
            repositorioPreferenciasProvider.overrideWithValue(preferencias),
            repositorioArchivosProvider.overrideWithValue(repositorio),
            motorTtsProvider.overrideWithValue(motor),
            exportadorAudioProvider.overrideWithValue(exportador),
            reproductorAudioProvider.overrideWithValue(reproductor),
            procesarArchivoProvider.overrideWithValue(procesador),
            carpetaBaseProvider.overrideWithValue('C:/base'),
          ],
        );

    void baseFakes({List<Archivo>? archivos}) {
      preferencias = PreferenciasMemoria();
      repositorio = RepositorioArchivosFake(archivos ?? const []);
      motor = MotorFake();
      exportador = ExportadorFake();
      reproductor = ReproductorFake();
      procesador = ProcesarArchivoStub(
        motor: motor,
        archivos: repositorio,
        exportador: exportador,
        silencioMuestras: 0,
        memoriaSafeMarginBytes: 0,
      );
    }

    test('build carga preferencias §6.3 y lista archivos', () {
      preferencias = PreferenciasMemoria({
        'carpeta_in': 'C:/libros',
        'carpeta_out': 'C:/audio',
        'voz': 'F2',
        'steps': 7,
        'speed': 0.9,
        'lang_voz': 'en',
        'formatos': ['ogg'],
      });
      repositorio = RepositorioArchivosFake([
        const Archivo('C:/libros/a.md'),
        const Archivo('C:/libros/b.md'),
      ]);
      motor = MotorFake();
      exportador = ExportadorFake();
      reproductor = ReproductorFake();
      procesador = ProcesarArchivoStub(
        motor: motor,
        archivos: repositorio,
        exportador: exportador,
        silencioMuestras: 0,
        memoriaSafeMarginBytes: 0,
      );

      final container = crearContenedor();
      final estado = container.read(homeControllerProvider);

      expect(estado.carpetaIn, 'C:/libros');
      expect(estado.carpetaOut, 'C:/audio');
      expect(estado.voz, 'F2');
      expect(estado.steps, 7);
      expect(estado.speed, 0.9);
      expect(estado.langVoz, 'en');
      expect(estado.formatos, {'ogg'});
      expect(estado.archivos, hasLength(2));
      expect(repositorio.listados, 1);
    });

    test('build usa defaults sin preferencias', () {
      baseFakes();

      final container = crearContenedor();
      final estado = container.read(homeControllerProvider);

      expect(estado.carpetaIn, 'C:/base${Platform.pathSeparator}archivos');
      expect(estado.carpetaOut, 'C:/base${Platform.pathSeparator}audio');
      expect(estado.voz, 'M1');
      expect(estado.steps, 5);
      expect(estado.speed, 1.1);
      expect(estado.langVoz, 'es');
      expect(estado.formatos, {'wav', 'mp3'});
      expect(estado.ejecutando, isFalse);
    });

    test('seleccionar todo / nada / alternar', () {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);

      controller.seleccionarTodo();
      expect(container.read(homeControllerProvider).seleccion, hasLength(2));

      controller.limpiarSeleccion();
      expect(container.read(homeControllerProvider).seleccion, isEmpty);

      controller.alternarSeleccion('C:/libros/a.md');
      expect(
        container.read(homeControllerProvider).seleccion,
        {'C:/libros/a.md'},
      );

      controller.alternarSeleccion('C:/libros/a.md');
      expect(container.read(homeControllerProvider).seleccion, isEmpty);
    });

    test('cambiar opciones de síntesis', () {
      baseFakes();

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);

      controller.cambiarVoz('F1');
      controller.cambiarSteps(10);
      controller.cambiarSpeed(1.7);
      controller.cambiarLangVoz('fr');
      controller.alternarFormato('ogg');
      controller.alternarFormato('wav');

      final estado = container.read(homeControllerProvider);
      expect(estado.voz, 'F1');
      expect(estado.steps, 10);
      expect(estado.speed, 1.7);
      expect(estado.langVoz, 'fr');
      expect(estado.formatos, {'mp3', 'ogg'});
    });

    test('procesar sin formato: snackbar y log, sin ejecutar', () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      controller.alternarFormato('wav');
      controller.alternarFormato('mp3');

      final t = es();
      await controller.procesar(t);

      final estado = container.read(homeControllerProvider);
      expect(estado.snackbar?.texto, t.snackbar_formato);
      expect(estado.snackbar?.esError, isTrue);
      expect(estado.lineasLog, contains(t.log_formato_no_ok));
      expect(estado.ejecutando, isFalse);
      expect(procesador.llamadas, isEmpty);
    });

    test('procesar sin archivos: snackbar y log', () async {
      baseFakes();

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);

      final t = es();
      await controller.procesar(t);

      final estado = container.read(homeControllerProvider);
      expect(estado.snackbar?.texto, t.snackbar_sin_md);
      expect(estado.lineasLog, contains(t.log_sin_md));
      expect(procesador.llamadas, isEmpty);
    });

    test('procesar archivos: log completo, estado listo y persistencia',
        () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      controller.cambiarVoz('F2');
      controller.cambiarSteps(8);
      controller.cambiarSpeed(1.3);
      controller.cambiarLangVoz('en');
      controller.alternarFormato('ogg');

      final t = es();
      await controller.procesar(t);

      final estado = container.read(homeControllerProvider);
      final tiempo = t.tiempo_seg(0); // el stub resuelve instantáneamente
      expect(estado.ejecutando, isFalse);
      expect(estado.estado, t.estado_listo_n(2, tiempo));
      expect(estado.snackbar?.texto, t.snackbar_procesado(2, tiempo));
      expect(motor.vocesPedidas, ['F2']);
      expect(procesador.llamadas, hasLength(2));
      expect(
        procesador.llamadas.first.rutaBase,
        'C:/base${Platform.pathSeparator}audio${Platform.pathSeparator}a',
      );
      expect(procesador.llamadas.first.steps, 8);
      expect(procesador.llamadas.first.speed, 1.3);
      expect(procesador.llamadas.first.formatos,
          containsAll(['wav', 'mp3', 'ogg']));
      expect(procesador.llamadas.first.lang, 'en');

      final guardado = preferencias.datos;
      expect(guardado['voz'], 'F2');
      expect(guardado['steps'], 8);
      expect(guardado['speed'], 1.3);
      expect(guardado['lang_voz'], 'en');
      expect(guardado['formatos'], containsAll(['wav', 'mp3', 'ogg']));
      expect(guardado['carpeta_in'], 'C:/base${Platform.pathSeparator}archivos');
      expect(guardado['carpeta_out'], 'C:/base${Platform.pathSeparator}audio');
    });

    test('cancelar interrumpe el procesamiento', () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      final t = es();
      final liberar = Completer<void>();
      procesador.espera = () => liberar.future;

      final futuro = controller.procesar(t);
      await Future<void>.delayed(Duration.zero);
      controller.cancelar(t);
      liberar.complete();
      await futuro;

      final estado = container.read(homeControllerProvider);
      final tiempo = t.tiempo_seg(0);
      expect(estado.ejecutando, isFalse);
      expect(estado.estado, t.estado_cancelado);
      expect(estado.snackbar?.texto, t.snackbar_exportado);
      expect(estado.lineasLog, contains(t.log_cancelado(tiempo)));
      expect(procesador.llamadas, hasLength(1));
    });

    test('progreso con throttle: ~20 líneas por archivo', () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
      ]);

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      final t = es();
      procesador.alProcesar = (onProgreso, detener) {
        for (var i = 1; i <= 40; i++) {
          onProgreso(i, 40);
        }
      };

      await controller.procesar(t);

      final estado = container.read(homeControllerProvider);
      final paso = 40 ~/ 20;
      final esperadas = [
        for (var i = paso; i <= 40; i += paso) t.log_segmento(i, 40),
      ];
      final lineas = estado.lineasLog.where(esperadas.contains);
      expect(lineas, hasLength(20));
      expect(estado.progresoActual, 1);
      expect(estado.progresoTotal, 1);
    });

    test('cargarArchivosExternos reemplaza la lista y limpia la corrida',
        () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      controller.seleccionarTodo();
      await controller.procesar(es());

      expect(container.read(homeControllerProvider).lineasLog, isNotEmpty);

      controller.cargarArchivosExternos(const [
        Archivo('C:/sueltos/x.md'),
        Archivo('C:/sueltos/y.md'),
      ]);

      final estado = container.read(homeControllerProvider);
      expect(estado.archivos.map((a) => a.ruta), ['C:/sueltos/x.md', 'C:/sueltos/y.md']);
      expect(estado.seleccion, isEmpty);
      expect(estado.ejecutando, isFalse);
      expect(estado.lineasLog, isEmpty);
      expect(estado.snackbar, isNull);
    });

    test('cargarArchivosExternos conserva marcas de rutas que siguen', () {
      baseFakes();

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      controller.cargarArchivosExternos(const [
        Archivo('C:/sueltos/a.md'),
        Archivo('C:/sueltos/b.md'),
      ]);
      controller.alternarSeleccion('C:/sueltos/a.md');

      controller.cargarArchivosExternos(const [
        Archivo('C:/sueltos/a.md'),
        Archivo('C:/sueltos/c.md'),
      ]);

      expect(container.read(homeControllerProvider).seleccion, {
        'C:/sueltos/a.md',
      });
    });

    test('quitarArchivoExterno elimina solo esa ruta', () {
      baseFakes();

      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      controller.cargarArchivosExternos(const [
        Archivo('C:/sueltos/a.md'),
        Archivo('C:/sueltos/b.md'),
      ]);

      controller.quitarArchivoExterno('C:/sueltos/a.md');

      expect(
        container.read(homeControllerProvider).archivos.map((a) => a.ruta),
        ['C:/sueltos/b.md'],
      );
    });

    testWidgets('escuchar sintetiza y reproduce la muestra', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => 'C:/temp',
      );

      baseFakes();
      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      controller.cambiarLangVoz('en');

      final t = es();
      await controller.escuchar(t);

      final estado = container.read(homeControllerProvider);
      expect(estado.probandoVoz, isFalse);
      expect(estado.lineasLog, contains(t.log_muestra_fin));
      expect(reproductor.rutas, hasLength(1));
      expect(motor.vocesPedidas, ['M1']);
    });
  });

  group('SeleccionController', () {
    late PreferenciasMemoria preferencias;
    late RepositorioArchivosFake repositorio;
    late MotorFake motor;
    late ExportadorFake exportador;
    late ReproductorFake reproductor;
    late ProcesarArchivoStub procesador;

    ProviderContainer crearContenedor() => ProviderContainer(
          overrides: [
            repositorioPreferenciasProvider.overrideWithValue(preferencias),
            repositorioArchivosProvider.overrideWithValue(repositorio),
            motorTtsProvider.overrideWithValue(motor),
            exportadorAudioProvider.overrideWithValue(exportador),
            reproductorAudioProvider.overrideWithValue(reproductor),
            procesarArchivoProvider.overrideWithValue(procesador),
            carpetaBaseProvider.overrideWithValue('C:/base'),
          ],
        );

    void baseFakes({List<Archivo>? archivos}) {
      preferencias = PreferenciasMemoria();
      repositorio = RepositorioArchivosFake(archivos ?? const []);
      motor = MotorFake();
      exportador = ExportadorFake();
      reproductor = ReproductorFake();
      procesador = ProcesarArchivoStub(
        motor: motor,
        archivos: repositorio,
        exportador: exportador,
        silencioMuestras: 0,
        memoriaSafeMarginBytes: 0,
      );
    }

    test('build arranca con lista vacía aunque la carpeta por defecto tenga archivos',
        () {
      baseFakes(archivos: const [Archivo('C:/base/archivos/a.md')]);

      final container = crearContenedor();
      final estado = container.read(seleccionControllerProvider);

      expect(estado.archivos, isEmpty);
    });

    test('cargarArchivosExternos alimenta la lista y procesa', () async {
      baseFakes();

      final container = crearContenedor();
      final controller = container.read(seleccionControllerProvider.notifier);
      controller.cargarArchivosExternos(const [
        Archivo('C:/sueltos/a.md'),
        Archivo('C:/sueltos/b.md'),
      ]);

      await controller.procesar(es());

      final estado = container.read(seleccionControllerProvider);
      expect(estado.ejecutando, isFalse);
      expect(estado.estado, es().estado_listo_n(2, es().tiempo_seg(0)));
      expect(procesador.llamadas, hasLength(2));
      expect(
        procesador.llamadas.first.rutaBase,
        'C:/base${Platform.pathSeparator}audio${Platform.pathSeparator}a',
      );
    });
  });
}
