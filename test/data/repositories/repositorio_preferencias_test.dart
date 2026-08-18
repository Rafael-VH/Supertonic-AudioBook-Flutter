import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/shared/data/repositories/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/shared/domain/entities/app_preferences.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

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

  // --- Typed methods ---

  group('guardarPreferenciasTyped / cargarPreferenciasTyped', () {
    test('guardar typed persists AppPreferences to disk', () {
      final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
      const prefs = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'F2', steps: 8, speed: 1.3, langVoz: 'en'),
        carpetaSalida: '/output',
        onboardingVisto: true,
      );

      repo.guardarPreferenciasTyped(prefs);

      final raw = jsonDecode(File('${temp.path}/prefs.json').readAsStringSync());
      expect(raw['voz'], 'F2');
      expect(raw['steps'], 8);
      expect(raw['speed'], closeTo(1.3, 1e-9));
      expect(raw['langVoz'], 'en');
      expect(raw['carpeta_salida'], '/output');
      expect(raw['onboarding_visto'], isTrue);
    });

    test('cargar typed returns AppPreferences from disk', () {
      final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
      const prefs = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'M1'),
        onboardingVisto: false,
      );

      repo.guardarPreferenciasTyped(prefs);
      final loaded = repo.cargarPreferenciasTyped();

      expect(loaded.voiceConfig.voz, 'M1');
      expect(loaded.voiceConfig.steps, 32);
      expect(loaded.onboardingVisto, isFalse);
    });

    test('roundtrip typed preserves all values', () {
      final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
      const original = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'F3', steps: 9, speed: 1.5, langVoz: 'fr'),
        carpetaSalida: '/audio',
        onboardingVisto: true,
        modeloState: 'descargado',
        modeloPath: '/m',
      );

      repo.guardarPreferenciasTyped(original);
      final roundtripped = repo.cargarPreferenciasTyped();

      expect(roundtripped, equals(original));
    });

    test('cargar typed from empty file returns default AppPreferences', () {
      final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');
      final loaded = repo.cargarPreferenciasTyped();

      expect(loaded.voiceConfig.voz, 'default');
      expect(loaded.onboardingVisto, isFalse);
    });
  });
}
