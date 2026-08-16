import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/domain/contracts/reproductor_audio.dart';
import 'package:supertonic_audiobook/presentation/controllers/biblioteca_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

import '../../support/fakes.dart';

/// Repositorio que registra la carpeta pedida a `listarAudios` (para
/// verificar el fallback `<base>/audio` del build).
class _RepositorioAudios extends RepositorioArchivosFake {
  _RepositorioAudios([List<String>? audios]) : super(const [], audios: audios);

  String? carpetaListada;

  @override
  List<String> listarAudios(String carpeta) {
    carpetaListada = carpeta;
    return super.listarAudios(carpeta);
  }
}

/// Repositorio cuyo listado falla (cubre el catch del build).
class _RepositorioQueFalla extends _RepositorioAudios {
  @override
  List<String> listarAudios(String carpeta) =>
      throw StateError('falla al listar audios');
}

/// Reproductor que falla al reproducir (BIB-5: archivo faltante o corrupto).
class _ReproductorQueFalla extends ReproductorFake {
  @override
  Future<void> reproducir(String ruta) async =>
      throw Exception('archivo faltante: $ruta');
}

void main() {
  group('BibliotecaController', () {
    late PreferenciasMemoria preferencias;
    late _RepositorioAudios repositorio;
    late ReproductorFake reproductor;

    ProviderContainer crearContenedor() => ProviderContainer(
      overrides: [
        repositorioPreferenciasProvider.overrideWithValue(preferencias),
        repositorioArchivosProvider.overrideWithValue(repositorio),
        reproductorAudioProvider.overrideWithValue(reproductor),
        carpetaBaseProvider.overrideWithValue('C:/base'),
      ],
    );

    void baseFakes({List<String>? audios}) {
      preferencias = PreferenciasMemoria();
      repositorio = _RepositorioAudios(audios);
      reproductor = ReproductorFake();
    }

    test('build usa carpeta_out de preferencias y agrupa por libro', () {
      baseFakes(
        audios: [
          'C:/audio/milibro.wav',
          'C:/audio/milibro.mp3',
          'C:/audio/otro.ogg',
        ],
      );
      preferencias = PreferenciasMemoria({'carpeta_out': 'C:/audio'});

      final container = crearContenedor();
      final estado = container.read(bibliotecaControllerProvider);

      expect(estado.libros, hasLength(2));
      expect(estado.libros.map((l) => l.titulo), ['milibro', 'otro']);
      expect(estado.libros.first.formatoPrioritario, 'mp3');
      expect(estado.libros.first.rutaPrioritaria, 'C:/audio/milibro.mp3');
      expect(estado.libros.last.formatoPrioritario, 'ogg');
      expect(estado.error, isNull);
      expect(estado.vacio, isFalse);
      expect(repositorio.carpetaListada, 'C:/audio');
      expect(reproductor.tieneOyentes, isTrue); // build suscribe al stream
    });

    test('build usa el fallback <base>/audio sin preferencias', () {
      baseFakes(audios: ['C:/base/audio/uno.mp3']);

      final container = crearContenedor();
      final estado = container.read(bibliotecaControllerProvider);

      expect(
        repositorio.carpetaListada,
        'C:/base${Platform.pathSeparator}audio',
      );
      expect(estado.libros, hasLength(1));
      expect(estado.libros.single.titulo, 'uno');
      expect(estado.error, isNull);
    });

    test('toggle play → pausa → reanuda sobre el mismo tile (BIB-3)', () async {
      baseFakes(audios: ['C:/audio/libro.mp3']);
      final container = crearContenedor();
      final controller = container.read(bibliotecaControllerProvider.notifier);
      final libro = container.read(bibliotecaControllerProvider).libros.single;

      await controller.alternarReproduccion(libro);
      var estado = container.read(bibliotecaControllerProvider);
      expect(estado.reproduciendoRuta, 'C:/audio/libro.mp3');
      expect(estado.pausado, isFalse);

      await controller.alternarReproduccion(libro);
      estado = container.read(bibliotecaControllerProvider);
      expect(estado.reproduciendoRuta, 'C:/audio/libro.mp3');
      expect(estado.pausado, isTrue);

      await controller.alternarReproduccion(libro);
      estado = container.read(bibliotecaControllerProvider);
      expect(estado.reproduciendoRuta, 'C:/audio/libro.mp3');
      expect(estado.pausado, isFalse);

      expect(reproductor.rutas, ['C:/audio/libro.mp3']); // una sola carga
      expect(reproductor.pausado, isTrue);
      expect(reproductor.reanudado, isTrue);
    });

    test('cambio de tile reemplaza la reproducción', () async {
      baseFakes(audios: ['C:/audio/a.mp3', 'C:/audio/b.mp3']);
      final container = crearContenedor();
      final controller = container.read(bibliotecaControllerProvider.notifier);
      final libros = container.read(bibliotecaControllerProvider).libros;

      await controller.alternarReproduccion(libros[0]);
      await controller.alternarReproduccion(libros[1]);

      final estado = container.read(bibliotecaControllerProvider);
      expect(estado.reproduciendoRuta, 'C:/audio/b.mp3');
      expect(estado.pausado, isFalse);
      expect(reproductor.rutas, ['C:/audio/a.mp3', 'C:/audio/b.mp3']);
    });

    test('error al reproducir deja idle con error (BIB-5)', () async {
      baseFakes(audios: ['C:/audio/borrado.mp3']);
      reproductor = _ReproductorQueFalla();
      final container = crearContenedor();
      final controller = container.read(bibliotecaControllerProvider.notifier);
      final libro = container.read(bibliotecaControllerProvider).libros.single;

      await controller.alternarReproduccion(libro);

      final estado = container.read(bibliotecaControllerProvider);
      expect(estado.error, contains('archivo faltante'));
      expect(estado.reproduciendoRuta, isNull);
      expect(estado.pausado, isFalse);
      expect(estado.vacio, isFalse); // el error no es estado vacío
    });

    test('fin natural del audio limpia el tile sin marcar error', () async {
      baseFakes(audios: ['C:/audio/libro.mp3']);
      final container = crearContenedor();
      final controller = container.read(bibliotecaControllerProvider.notifier);
      final libro = container.read(bibliotecaControllerProvider).libros.single;

      await controller.alternarReproduccion(libro);
      expect(
        container.read(bibliotecaControllerProvider).reproduciendoRuta,
        'C:/audio/libro.mp3',
      );

      reproductor.emitir(EstadoReproduccion.detenido);
      await Future<void>.delayed(Duration.zero);

      final estado = container.read(bibliotecaControllerProvider);
      expect(estado.reproduciendoRuta, isNull);
      expect(estado.pausado, isFalse);
      expect(estado.error, isNull); // el fin natural no es un error
    });

    test('dispose cancela la suscripción y detiene la reproducción', () async {
      baseFakes(audios: ['C:/audio/libro.mp3']);
      final container = crearContenedor();
      final controller = container.read(bibliotecaControllerProvider.notifier);
      await controller.alternarReproduccion(
        container.read(bibliotecaControllerProvider).libros.single,
      );
      expect(reproductor.tieneOyentes, isTrue);

      container.dispose();

      expect(reproductor.tieneOyentes, isFalse);
      expect(reproductor.detenido, isTrue);
    });

    test('error del listado inicial: estado error sin crash', () {
      preferencias = PreferenciasMemoria();
      repositorio = _RepositorioQueFalla();
      reproductor = ReproductorFake();

      final container = crearContenedor();
      final estado = container.read(bibliotecaControllerProvider);

      expect(estado.libros, isEmpty);
      expect(estado.error, contains('falla al listar'));
      expect(estado.vacio, isFalse);
    });

    test('sin audios: lista vacía sin error, estado vacío (BIB-4)', () {
      baseFakes();

      final container = crearContenedor();
      final estado = container.read(bibliotecaControllerProvider);

      expect(estado.libros, isEmpty);
      expect(estado.error, isNull);
      expect(estado.vacio, isTrue);
    });
  });
}
