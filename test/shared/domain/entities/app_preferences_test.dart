import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/shared/domain/entities/app_preferences.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

void main() {
  group('AppPreferences', () {
    test('creation with all parameters', () {
      const prefs = AppPreferences(
        voiceConfig: VoiceConfig(
          voz: 'F2',
          steps: 8,
          speed: 1.3,
          langVoz: 'en',
        ),
        carpetaSalida: '/output',
        onboardingVisto: true,
        modeloState: 'descargado',
        modeloPath: '/model/path',
      );

      expect(prefs.voiceConfig.voz, 'F2');
      expect(prefs.carpetaSalida, '/output');
      expect(prefs.onboardingVisto, isTrue);
      expect(prefs.modeloState, 'descargado');
      expect(prefs.modeloPath, '/model/path');
    });

    test('creation with defaults', () {
      const prefs = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'M1'),
      );

      expect(prefs.carpetaSalida, isNull);
      expect(prefs.onboardingVisto, isFalse);
      expect(prefs.modeloState, isNull);
      expect(prefs.modeloPath, isNull);
    });

    test('fromMap extracts VoiceConfig fields', () {
      final map = <String, Object?>{
        'voz': 'F2',
        'steps': 8,
        'speed': 1.3,
        'langVoz': 'en',
        'carpeta_salida': '/output',
        'onboarding_visto': true,
        'modelo_state': 'descargado',
        'modelo_path': '/model/path',
      };

      final prefs = AppPreferences.fromMap(map);

      expect(prefs.voiceConfig.voz, 'F2');
      expect(prefs.voiceConfig.steps, 8);
      expect(prefs.voiceConfig.speed, 1.3);
      expect(prefs.voiceConfig.langVoz, 'en');
      expect(prefs.carpetaSalida, '/output');
      expect(prefs.onboardingVisto, isTrue);
      expect(prefs.modeloState, 'descargado');
      expect(prefs.modeloPath, '/model/path');
    });

    test('fromMap applies defaults for missing keys', () {
      final prefs = AppPreferences.fromMap({});

      expect(prefs.voiceConfig.voz, 'default');
      expect(prefs.voiceConfig.steps, 32);
      expect(prefs.voiceConfig.speed, 1.0);
      expect(prefs.voiceConfig.langVoz, 'es');
      expect(prefs.carpetaSalida, isNull);
      expect(prefs.onboardingVisto, isFalse);
      expect(prefs.modeloState, isNull);
      expect(prefs.modeloPath, isNull);
    });

    test('fromMap handles num types from JSON', () {
      final prefs = AppPreferences.fromMap({
        'steps': 7,
        'speed': 0.9,
      });

      expect(prefs.voiceConfig.steps, 7);
      expect(prefs.voiceConfig.speed, 0.9);
    });

    test('toMap produces correct map', () {
      const prefs = AppPreferences(
        voiceConfig: VoiceConfig(
          voz: 'F1',
          steps: 5,
          speed: 1.1,
          langVoz: 'es',
        ),
        carpetaSalida: '/audio',
        onboardingVisto: true,
        modeloState: 'no_descargado',
        modeloPath: '/path',
      );

      final map = prefs.toMap();

      expect(map['voz'], 'F1');
      expect(map['steps'], 5);
      expect(map['speed'], 1.1);
      expect(map['langVoz'], 'es');
      expect(map['carpeta_salida'], '/audio');
      expect(map['onboarding_visto'], isTrue);
      expect(map['modelo_state'], 'no_descargado');
      expect(map['modelo_path'], '/path');
    });

    test('roundtrip fromMap → toMap → fromMap preserves values', () {
      final original = <String, Object?>{
        'voz': 'F3',
        'steps': 9,
        'speed': 1.5,
        'langVoz': 'fr',
        'carpeta_salida': '/out',
        'onboarding_visto': true,
        'modelo_state': 'descargado',
        'modelo_path': '/m',
      };

      final first = AppPreferences.fromMap(original);
      final exported = first.toMap();
      final second = AppPreferences.fromMap(exported);

      expect(first, equals(second));
    });

    test('roundtrip preserves null optionals', () {
      final map = <String, Object?>{
        'voz': 'M1',
      };

      final prefs = AppPreferences.fromMap(map);
      final roundtripped = AppPreferences.fromMap(prefs.toMap());

      expect(roundtripped.carpetaSalida, isNull);
      expect(roundtripped.modeloState, isNull);
      expect(roundtripped.modeloPath, isNull);
    });

    test('equality via Equatable', () {
      const a = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'F1'),
        onboardingVisto: true,
      );
      const b = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'F1'),
        onboardingVisto: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when carpetaSalida differs', () {
      const a = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'M1'),
        carpetaSalida: '/a',
      );
      const b = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'M1'),
        carpetaSalida: '/b',
      );

      expect(a, isNot(equals(b)));
    });

    test('props contains all fields', () {
      const prefs = AppPreferences(
        voiceConfig: VoiceConfig(voz: 'F2', steps: 8, speed: 1.3, langVoz: 'en'),
        carpetaSalida: '/out',
        onboardingVisto: true,
        modeloState: 'descargado',
        modeloPath: '/m',
      );

      expect(prefs.props, hasLength(5));
      expect(prefs.props[0], isA<VoiceConfig>());
      expect(prefs.props[1], '/out');
      expect(prefs.props[2], isTrue);
      expect(prefs.props[3], 'descargado');
      expect(prefs.props[4], '/m');
    });
  });
}
