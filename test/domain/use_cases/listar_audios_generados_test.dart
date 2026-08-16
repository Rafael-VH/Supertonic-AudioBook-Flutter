import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/domain/use_cases/listar_audios_generados.dart';

import '../../support/fakes.dart';

void main() {
  const carpeta = 'C:/audio';

  ListarAudiosGenerados caso(List<String> audios) => ListarAudiosGenerados(
        archivos: RepositorioArchivosFake(const [], audios: audios),
      );

  group('ListarAudiosGenerados', () {
    test('un stem en varios formatos → un solo libro con el mp3 ganador', () {
      final libros = caso([
        '$carpeta/milibro.wav',
        '$carpeta/milibro.mp3',
      ]).ejecutar(carpeta: carpeta);

      expect(libros, hasLength(1));
      expect(libros.single.titulo, 'milibro');
      expect(libros.single.formatoPrioritario, 'mp3');
      expect(libros.single.rutaPrioritaria, '$carpeta/milibro.mp3');
      expect(libros.single.archivos, [
        '$carpeta/milibro.wav',
        '$carpeta/milibro.mp3',
      ]);
    });

    test('prioridad completa mp3 > ogg > flac > wav', () {
      final libros = caso([
        '$carpeta/libro.wav',
        '$carpeta/libro.flac',
        '$carpeta/libro.ogg',
        '$carpeta/libro.mp3',
      ]).ejecutar(carpeta: carpeta);

      expect(libros, hasLength(1));
      expect(libros.single.formatoPrioritario, 'mp3');
      expect(libros.single.rutaPrioritaria, '$carpeta/libro.mp3');
    });

    test('ogg gana sobre flac y wav cuando no hay mp3', () {
      final libros = caso([
        '$carpeta/libro.wav',
        '$carpeta/libro.flac',
        '$carpeta/libro.ogg',
      ]).ejecutar(carpeta: carpeta);

      expect(libros.single.formatoPrioritario, 'ogg');
      expect(libros.single.rutaPrioritaria, '$carpeta/libro.ogg');
    });

    test('solo formatos pesados → usa el wav disponible (no hay prioridad)',
        () {
      final libros = caso(['$carpeta/milibro.wav']).ejecutar(carpeta: carpeta);

      expect(libros, hasLength(1));
      expect(libros.single.formatoPrioritario, 'wav');
      expect(libros.single.rutaPrioritaria, '$carpeta/milibro.wav');
    });

    test('agrupa varios libros preservando el orden natural del repo', () {
      final libros = caso([
        '$carpeta/capitulo10.mp3',
        '$carpeta/capitulo2.ogg',
        '$carpeta/capitulo2.mp3',
        '$carpeta/capitulo1.wav',
        '$carpeta/capitulo1.mp3',
      ]).ejecutar(carpeta: carpeta);

      // Orden de primer encuentro por stem (D4: el repo ya ordena natural).
      expect(libros.map((l) => l.titulo).toList(),
          ['capitulo10', 'capitulo2', 'capitulo1']);
      expect(libros[0].formatoPrioritario, 'mp3');
      expect(libros[1].formatoPrioritario, 'mp3');
      expect(libros[2].formatoPrioritario, 'mp3');
    });

    test('sin audios → lista vacía', () {
      expect(caso(const []).ejecutar(carpeta: carpeta), isEmpty);
    });
  });
}
