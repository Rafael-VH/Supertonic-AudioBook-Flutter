import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/modelo/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

import '../../support/fakes.dart';

void main() {
  group('ModeloController', () {
    late ModeloGestorFake gestor;

    ProviderContainer crearContenedor({PreferenciasMemoria? preferencias}) {
      final contenedor = ProviderContainer(
        overrides: [
          modeloManagerProvider.overrideWithValue(gestor),
          repositorioPreferenciasProvider
              .overrideWithValue(preferencias ?? PreferenciasMemoria()),
        ],
      );
      // Mantiene vivo el provider: sin listener, Riverpod descarta el
      // Notifier tras el read y `ref.mounted` corta la verificación.
      contenedor.listen(modeloControllerProvider, (_, __) {});
      addTearDown(contenedor.dispose);
      return contenedor;
    }

    /// Avanza los microtasks hasta que `build()` resuelve la verificación.
    Future<void> estabilizar() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('con el modelo en disco pasa directo a listo', () async {
      gestor = ModeloGestorFake(disponible: true);
      final contenedor = crearContenedor();

      await estabilizar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, true);
      expect(estado.descargando, false);
      expect(estado.verificando, false);
      expect(gestor.descargas, 0);
    });

    test('sin el modelo queda pendiente, sin error', () async {
      gestor = ModeloGestorFake();
      final contenedor = crearContenedor();

      await estabilizar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, false);
      expect(estado.descargando, false);
      expect(estado.verificando, false);
      expect(estado.error, isNull);
    });

    test('descargar emite progreso y termina listo', () async {
      gestor = ModeloGestorFake()..espera = Completer<void>();
      final contenedor = crearContenedor();
      await estabilizar();
      final controller = contenedor.read(modeloControllerProvider.notifier);

      final futuro = controller.descargar();
      await estabilizar();

      final durante = contenedor.read(modeloControllerProvider);
      expect(durante.descargando, true);
      expect(durante.bytesMb, 1);
      expect(durante.totalMb, 10);
      expect(durante.archivo, 'onnx/vocoder.onnx');

      gestor.espera!.complete();
      await futuro;

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, true);
      expect(estado.descargando, false);
      expect(gestor.descargas, 1);
    });

    test('cancelar vuelve a pendiente sin error', () async {
      gestor = ModeloGestorFake()..espera = Completer<void>();
      final contenedor = crearContenedor();
      await estabilizar();
      final controller = contenedor.read(modeloControllerProvider.notifier);

      final futuro = controller.descargar();
      await estabilizar();
      expect(contenedor.read(modeloControllerProvider).descargando, true);

      controller.cancelar();
      gestor.espera!.complete();
      await futuro;

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.descargando, false);
      expect(estado.listo, false);
      expect(estado.error, isNull);
      expect(gestor.cancelaciones, 1);
    });

    test('si la descarga falla muestra el error', () async {
      gestor = ModeloGestorFake(fallar: true);
      final contenedor = crearContenedor();
      await estabilizar();
      final controller = contenedor.read(modeloControllerProvider.notifier);

      await controller.descargar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.descargando, false);
      expect(estado.listo, false);
      expect(estado.error, isNotNull);
      expect(gestor.descargas, 1);
    });

    test('no descarga dos veces si ya está listo', () async {
      gestor = ModeloGestorFake(disponible: true);
      final contenedor = crearContenedor();
      await estabilizar();
      expect(contenedor.read(modeloControllerProvider).listo, true);

      final controller = contenedor.read(modeloControllerProvider.notifier);
      await controller.descargar();

      expect(gestor.descargas, 0);
    });

    test(
        'una verificación que termina tarde no pisa el estado de descarga',
        () async {
      gestor = ModeloGestorFake()
        ..verificacionLenta = Completer<void>()
        ..espera = Completer<void>();
      final contenedor = crearContenedor();
      // build() lanzó _verificar, que quedó pendiente.
      await Future<void>.delayed(Duration.zero);

      final controller = contenedor.read(modeloControllerProvider.notifier);
      final futuro = controller.descargar();
      await estabilizar();
      expect(contenedor.read(modeloControllerProvider).descargando, true);

      // La verificación termina DESPUÉS de que la descarga arrancó: su
      // resultado no debe pisar `descargando: true`.
      gestor.verificacionLenta!.complete();
      await estabilizar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.descargando, true);
      expect(estado.listo, false);

      gestor.espera!.complete();
      await futuro;
      expect(contenedor.read(modeloControllerProvider).listo, true);
    });

    test(
        'una verificación obsoleta no pisa `listo` si la descarga terminó '
        'mientras hasheaba', () async {
      gestor = ModeloGestorFake()..verificacionLenta = Completer<void>();
      final contenedor = crearContenedor();
      // build() lanzó _verificar, que quedó pendiente.
      await Future<void>.delayed(Duration.zero);

      // La descarga arranca y TERMINA (sin bloqueos) antes de que la
      // verificación resuelva: publica `listo` con ambas flags en false.
      final controller = contenedor.read(modeloControllerProvider.notifier);
      await controller.descargar();
      expect(contenedor.read(modeloControllerProvider).listo, true);

      // La verificación (que vio el disco vacío) termina tarde: su veredicto
      // pre-descarga no debe borrar `listo`.
      gestor.verificacionLenta!.complete();
      await estabilizar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, true);
      expect(estado.descargando, false);
      expect(estado.verificando, false);
      expect(estado.error, isNull);
    });

    test(
        'una verificación obsoleta no borra el error de una descarga '
        'fallida', () async {
      gestor = ModeloGestorFake(fallar: true)
        ..verificacionLenta = Completer<void>();
      final contenedor = crearContenedor();
      // build() lanzó _verificar, que quedó pendiente.
      await Future<void>.delayed(Duration.zero);

      // La descarga arranca y FALLA antes de que la verificación resuelva:
      // publica `error` con `descargando: false`.
      final controller = contenedor.read(modeloControllerProvider.notifier);
      await controller.descargar();
      expect(contenedor.read(modeloControllerProvider).error, isNotNull);

      // La verificación (que vio el disco vacío) termina tarde: su veredicto
      // pre-descarga no debe pisar el estado con error ni dejar el gate
      // "idle" como si el fallo no hubiera pasado.
      gestor.verificacionLenta!.complete();
      await estabilizar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.error, isNotNull);
      expect(estado.descargando, false);
      expect(estado.listo, false);
      expect(estado.verificando, false);
    });

    test('persistir el veredicto no pisa otras preferencias', () async {
      gestor = ModeloGestorFake(disponible: true);
      final preferencias = PreferenciasMemoria({'onboarding_visto': true});
      crearContenedor(preferencias: preferencias);
      await estabilizar();

      expect(preferencias.datos['onboarding_visto'], true);
      expect(preferencias.datos['modelo_descargado'], true);
    });

    test('con preferencia guardada arranca optimista en listo', () async {
      gestor = ModeloGestorFake(disponible: true);
      final contenedor = crearContenedor(
        preferencias: PreferenciasMemoria({'modelo_descargado': true}),
      );

      // Estado inicial inmediato: muestra "descargado" sin esperar el disco.
      var estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, true);
      expect(estado.verificando, true);

      // La verificación de fondo confirma el optimismo y lo deja estable.
      await estabilizar();
      estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, true);
      expect(estado.verificando, false);
      expect(
        contenedor.read(repositorioPreferenciasProvider).cargar()[
            'modelo_descargado'],
        true,
      );
    });

    test(
        'el optimismo de preferencia se corrige si el modelo ya no está '
        'en disco', () async {
      // Preferencia dice "descargado", pero el disco está vacío (el modelo se
      // borró o se corrompió): la verificación de fondo debe corregir el
      // estado y la preferencia, no dejar "descargado" para siempre.
      gestor = ModeloGestorFake();
      final preferencias = PreferenciasMemoria({'modelo_descargado': true});
      final contenedor = crearContenedor(preferencias: preferencias);
      await estabilizar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, false);
      expect(estado.verificando, false);
      expect(preferencias.datos['modelo_descargado'], false);
    });

    test('verificar() pública re-chequea, publica y persiste el resultado',
        () async {
      gestor = ModeloGestorFake();
      final preferencias = PreferenciasMemoria();
      final contenedor = crearContenedor(preferencias: preferencias);
      await estabilizar();
      expect(preferencias.datos['modelo_descargado'], false);

      // El modelo "aparece" en disco: el botón del dashboard debe detectarlo.
      gestor.disponible = true;
      final controller = contenedor.read(modeloControllerProvider.notifier);
      await controller.verificar();

      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.listo, true);
      expect(estado.verificando, false);
      expect(preferencias.datos['modelo_descargado'], true);
    });

    test('verificar() durante una descarga no interfiere', () async {
      gestor = ModeloGestorFake()..espera = Completer<void>();
      final contenedor = crearContenedor();
      await estabilizar();
      final controller = contenedor.read(modeloControllerProvider.notifier);

      final futuro = controller.descargar();
      await estabilizar();
      expect(contenedor.read(modeloControllerProvider).descargando, true);

      await controller.verificar();
      final estado = contenedor.read(modeloControllerProvider);
      expect(estado.descargando, true);
      expect(estado.listo, false);

      gestor.espera!.complete();
      await futuro;
      expect(contenedor.read(modeloControllerProvider).listo, true);
    });
  });
}
