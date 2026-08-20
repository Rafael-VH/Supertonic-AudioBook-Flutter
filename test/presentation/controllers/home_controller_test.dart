import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/file_system_local.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/procesar_archivo.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/sintetizar_muestra.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

import '../../support/fakes.dart';

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
            domainLoggerProvider.overrideWithValue(NoOpLogger()),
            sintetizarMuestraProvider.overrideWithValue(
              SintetizarMuestra(
                motor: motor,
                exportador: exportador,
                logger: NoOpLogger(),
              ),
            ),
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
        fileSystem: FileSystemLocal(),
        silencioMuestras: 0,
        memoriaSafeMarginBytes: 0,
        topeMovilBytes: 0,
        logger: NoOpLogger(),
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
        fileSystem: FileSystemLocal(),
        silencioMuestras: 0,
        memoriaSafeMarginBytes: 0,
        topeMovilBytes: 0,
        logger: NoOpLogger(),
      );

      final container = crearContenedor();
      final estado = container.read(homeControllerProvider);

      expect(estado.carpetaIn, 'C:/libros');
      expect(estado.carpetaOut, 'C:/audio');
      expect(estado.voiceConfig.voz, 'F2');
      expect(estado.voiceConfig.steps, 7);
      expect(estado.voiceConfig.speed, 0.9);
      expect(estado.voiceConfig.langVoz, 'en');
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
      expect(estado.voiceConfig.voz, 'M1');
      expect(estado.voiceConfig.steps, 5);
      expect(estado.voiceConfig.speed, 1.1);
      expect(estado.voiceConfig.langVoz, 'es');
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
      expect(estado.voiceConfig.voz, 'F1');
      expect(estado.voiceConfig.steps, 10);
      expect(estado.voiceConfig.speed, 1.7);
      expect(estado.voiceConfig.langVoz, 'fr');
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

    test('quitarArchivoExterno se ignora durante una corrida en curso',
        () async {
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
      expect(container.read(homeControllerProvider).ejecutando, isTrue);

      // X (quitar) en plena corrida: no debe resetear la corrida (cancelar
      // quedaría inerte, el log se borraría y Procesar se re-habilitaría
      // para una segunda corrida concurrente sobre el mismo TTS).
      controller.quitarArchivoExterno('C:/libros/a.md');

      final durante = container.read(homeControllerProvider);
      expect(durante.ejecutando, isTrue);
      expect(durante.cancelar, isFalse);
      expect(durante.archivos, hasLength(2));
      expect(durante.lineasLog, isNotEmpty);

      liberar.complete();
      await futuro;

      // La corrida terminó sin que el borrado se aplicara a mitad de camino.
      final estado = container.read(homeControllerProvider);
      expect(estado.archivos, hasLength(2));
      expect(estado.ejecutando, isFalse);
      expect(estado.estado, t.estado_listo_n(2, t.tiempo_seg(0)));
    });

    test('cargarArchivosExternos no resetea el estado durante una corrida',
        () async {
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

      controller.cargarArchivosExternos(const [Archivo('C:/sueltos/x.md')]);

      final durante = container.read(homeControllerProvider);
      expect(durante.ejecutando, isTrue);
      expect(durante.archivos, hasLength(2));
      expect(durante.lineasLog, isNotEmpty);

      liberar.complete();
      await futuro;
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

    test('procesar se bloquea mientras probandoVoz', () async {
      baseFakes(archivos: const [Archivo('C:/libros/a.md')]);
      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      final t = es();

      // Deja la muestra en vuelo: cambiarVoz queda esperando y la corrida
      // del TTS no debe solaparse con la síntesis del procesamiento.
      motor.esperaVoz = Completer<void>();
      final futuroEscuchar = controller.escuchar(t);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(homeControllerProvider).probandoVoz, isTrue);

      await controller.procesar(t);

      expect(procesador.llamadas, isEmpty);
      expect(container.read(homeControllerProvider).ejecutando, isFalse);

      motor.esperaVoz!.complete();
      await futuroEscuchar;
    });

    test('procesar cuenta omitidos sin éxito ni error', () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);
      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      final t = es();
      procesador.resultado = const ProcesarResultado(estado: ResultadoProceso.omitido, segmentos: 0, duracionAudioSeg: 0, caracteres: 0);

      await controller.procesar(t);

      final estado = container.read(homeControllerProvider);
      expect(estado.estado, t.estado_listo_n(0, t.tiempo_seg(0)));
      expect(estado.lineasLog, contains(t.log_archivo_omitido(1, 2, 'a.md')));
      expect(estado.lineasLog, contains(t.log_archivo_omitido(2, 2, 'b.md')));
      expect(estado.lineasLog, isNot(contains(t.log_archivo_fin(1, 2))));
    });

    test('procesar cuenta errores devueltos por el use case', () async {
      baseFakes(archivos: const [
        Archivo('C:/libros/a.md'),
        Archivo('C:/libros/b.md'),
      ]);
      final container = crearContenedor();
      final controller = container.read(homeControllerProvider.notifier);
      final t = es();
      procesador.resultado = const ProcesarResultado(estado: ResultadoProceso.error, segmentos: 0, duracionAudioSeg: 0, caracteres: 0);

      await controller.procesar(t);

      final estado = container.read(homeControllerProvider);
      expect(estado.estado, t.estado_con_errores(0, 2, 2));
      expect(estado.snackbar?.esError, isTrue);
      expect(estado.lineasLog, contains(t.log_archivo_error(1, 2, 'a.md')));
    });
  });
}
