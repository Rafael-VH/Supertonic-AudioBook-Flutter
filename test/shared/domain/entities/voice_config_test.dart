import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

void main() {
  group('VoiceConfig', () {
    test('creation with all parameters', () {
      const config = VoiceConfig(
        voz: 'F2',
        steps: 8,
        speed: 1.3,
        langVoz: 'en',
      );

      expect(config.voz, 'F2');
      expect(config.steps, 8);
      expect(config.speed, 1.3);
      expect(config.langVoz, 'en');
    });

    test('creation with defaults', () {
      const config = VoiceConfig(voz: 'M1');

      expect(config.voz, 'M1');
      expect(config.steps, 32);
      expect(config.speed, 1.0);
      expect(config.langVoz, 'es');
    });

    test('copyWith overrides individual fields', () {
      const original = VoiceConfig(voz: 'M1');
      final updated = original.copyWith(voz: 'F3', speed: 1.5);

      expect(updated.voz, 'F3');
      expect(updated.steps, 32); // unchanged
      expect(updated.speed, 1.5);
      expect(updated.langVoz, 'es'); // unchanged
    });

    test('copyWith null keeps original value', () {
      const original = VoiceConfig(voz: 'M1', steps: 8, speed: 1.3);
      final updated = original.copyWith();

      expect(updated.voz, original.voz);
      expect(updated.steps, original.steps);
      expect(updated.speed, original.speed);
      expect(updated.langVoz, original.langVoz);
    });

    test('equality via Equatable', () {
      const a = VoiceConfig(voz: 'F1', steps: 5, speed: 1.0, langVoz: 'es');
      const b = VoiceConfig(voz: 'F1', steps: 5, speed: 1.0, langVoz: 'es');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when voz differs', () {
      const a = VoiceConfig(voz: 'F1');
      const b = VoiceConfig(voz: 'F2');

      expect(a, isNot(equals(b)));
    });

    test('inequality when speed differs', () {
      const a = VoiceConfig(voz: 'F1', speed: 1.0);
      const b = VoiceConfig(voz: 'F1', speed: 1.5);

      expect(a, isNot(equals(b)));
    });

    test('props contains all fields', () {
      const config = VoiceConfig(
        voz: 'F2',
        steps: 8,
        speed: 1.3,
        langVoz: 'en',
      );

      expect(config.props, ['F2', 8, 1.3, 'en']);
    });

    test('props reflects defaults', () {
      const config = VoiceConfig(voz: 'M1');

      expect(config.props, ['M1', 32, 1.0, 'es']);
    });
  });
}
