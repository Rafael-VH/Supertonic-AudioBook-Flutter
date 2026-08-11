import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/data/repositories/repositorio_preferencias.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('repositorio_preferencias_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('cargar sin archivo → mapa vacío', () {
    final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
    expect(repo.cargar(), isEmpty);
  });

  test('guarda y recarga los mismos valores', () {
    final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
    repo.guardar({
      'tema_oscuro': false,
      'estilo': 'material',
      'idioma': 'es',
      'voz': 'M1',
      'steps': 5,
      'speed': 1.1,
      'formatos': ['wav', 'mp3'],
    });

    final cargadas = repo.cargar();
    expect(cargadas['tema_oscuro'], isFalse);
    expect(cargadas['estilo'], 'material');
    expect(cargadas['idioma'], 'es');
    expect(cargadas['voz'], 'M1');
    expect(cargadas['steps'], 5);
    expect(cargadas['speed'], closeTo(1.1, 1e-9));
    expect(cargadas['formatos'], ['wav', 'mp3']);
  });

  test('persiste JSON legible (indentado)', () {
    final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
    repo.guardar({'voz': 'F1'});
    final texto = File('${temp.path}/prefs.json').readAsStringSync();
    expect(texto, contains('  "voz"'));
    expect(jsonDecode(texto), {'voz': 'F1'});
  });

  test('crea las carpetas padre si no existen', () {
    final repo = PreferenciasJsonLocal(ruta: '${temp.path}/a/b/prefs.json');
    repo.guardar({'voz': 'M1'});
    expect(File('${temp.path}/a/b/prefs.json').existsSync(), isTrue);
  });

  test('JSON corrupto → mapa vacío (no lanza)', () {
    File('${temp.path}/prefs.json').writeAsStringSync('{esto no es json');
    final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
    expect(repo.cargar(), isEmpty);
  });

  test('guardar no lanza si la ruta es inválida', () {
    final repo = PreferenciasJsonLocal(ruta: '${temp.path}/no_existe_dir/prefs.json');
    expect(() => repo.guardar({'voz': 'M1'}), returnsNormally);
  });
}
