import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/shared/domain/entities/app_preferences.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';
import 'package:supertonic_audiobook/shared/data/repositories/repositorio_preferencias.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('settings_integration_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  group('Settings + AppPreferences integration', () {
    test('settings save preserves voice config loaded via typed API', () {
      final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');

      // Simulate: initial prefs have voice config via typed API
      const voicePrefs = AppPreferences(
        voiceConfig: VoiceConfig(
          voz: 'F2',
          steps: 8,
          speed: 1.3,
          langVoz: 'en',
        ),
      );
      repo.guardarPreferenciasTyped(voicePrefs);

      // Simulate: settings controller loads prefs, adds settings keys,
      // then saves back (merge pattern)
      final existing = repo.cargar();
      final merged = <String, Object>{
        ...existing,
        'tema_oscuro': true,
        'estilo': 'material',
        'idioma': 'es',
        'carpeta_out': '/output',
      };
      repo.guardar(merged);

      // Verify: voice config survives the merge
      final loaded = repo.cargarPreferenciasTyped();
      expect(loaded.voiceConfig.voz, 'F2');
      expect(loaded.voiceConfig.steps, 8);
      expect(loaded.voiceConfig.speed, 1.3);
      expect(loaded.voiceConfig.langVoz, 'en');
    });

    test('typed API roundtrip coexists with settings keys', () {
      final repo = PreferenciasJsonLocal(ruta: '${temp.path}/prefs.json');

      // Settings controller saves its keys
      repo.guardar({
        'tema_oscuro': false,
        'estilo': 'cupertino',
        'idioma': 'en',
        'carpeta_out': '/out',
      });

      // Home controller saves voice config via typed API (preserves existing)
      const voicePrefs = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'M3', steps: 6, speed: 1.0),
      );
      final merged = <String, Object>{
        ...repo.cargar(),
        ...Map<String, Object>.fromEntries(
          voicePrefs.toMap().entries.where((e) => e.value != null),
        ),
      };
      repo.guardar(merged);

      // Verify: both settings and voice config coexist
      final all = repo.cargar();
      expect(all['tema_oscuro'], isFalse);
      expect(all['estilo'], 'cupertino');
      expect(all['idioma'], 'en');
      expect(all['voz'], 'M3');
      expect(all['steps'], 6);
    });
  });
}
