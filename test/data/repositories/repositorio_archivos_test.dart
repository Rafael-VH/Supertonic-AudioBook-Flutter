import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/data/repositories/repositorio_archivos.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('repositorio_archivos_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  File crear(String nombre, [String contenido = '']) {
    final f = File('${temp.path}/$nombre');
    f.writeAsStringSync(contenido);
    return f;
  }

  List<String> nombresMd() => RepositorioArchivosLocal()
      .listarArchivosMd(temp.path)
      .map((a) => a.ruta.split(Platform.pathSeparator).last)
      .toList();

  group('listarArchivosMd', () {
    test('ordena con natural sort (números, no lexicográfico)', () {
      crear('capitulo.md');
      crear('capitulo1.md');
      crear('capitulo2.md');
      crear('capitulo10.md');

      expect(nombresMd(), [
        'capitulo.md',
        'capitulo1.md',
        'capitulo2.md',
        'capitulo10.md',
      ]);
    });

    test('ignora el padding numérico (desempate determinista por stem)', () {
      crear('archivo01.md');
      crear('archivo1.md');

      expect(nombresMd(), ['archivo01.md', 'archivo1.md']);
    });

    test('múltiples números por nombre', () {
      crear('c1s10.md');
      crear('c1s2.md');

      expect(nombresMd(), ['c1s2.md', 'c1s10.md']);
    });

    test('nombres que empiezan con número van primero', () {
      crear('3.md');
      crear('capitulo.md');

      expect(nombresMd(), ['3.md', 'capitulo.md']);
    });

    test('filtra solo .md (case-insensitive en la extensión)', () {
      crear('a.md');
      crear('b.MD');
      crear('c.txt');
      crear('d.md~');

      expect(nombresMd(), ['a.md', 'b.MD']);
    });

    test('no incluye carpetas aunque terminen en .md', () {
      crear('archivo.md');
      Directory('${temp.path}/carpeta.md').createSync();

      expect(nombresMd(), ['archivo.md']);
    });

    test('carpeta inexistente → lista vacía', () {
      expect(RepositorioArchivosLocal().listarArchivosMd('${temp.path}/nope'), isEmpty);
    });
  });

  group('leerArchivo', () {
    test('lee contenido UTF-8', () {
      crear('a.md', 'Hola, mundo — áéíóú');
      expect(
        RepositorioArchivosLocal().leerArchivo('${temp.path}/a.md'),
        'Hola, mundo — áéíóú',
      );
    });
  });

  group('crearCarpetasSiNoExisten', () {
    test('crea carpetas anidadas', () {
      final sub = '${temp.path}/a/b/c';
      RepositorioArchivosLocal().crearCarpetasSiNoExisten([sub]);
      expect(Directory(sub).existsSync(), isTrue);
    });
  });
}
