import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/shared/domain/entities/audio_pendiente.dart';

void main() {
  group('AudioPendiente', () {
    test('constructor crea instancia válida', () {
      final audio = AudioPendiente(
        tempPath: '/tmp/_temp/cap1_123.wav',
        displayName: 'Capitulo 1',
        format: 'wav',
        durationSec: 45.2,
        fileSizeBytes: 12_300_000,
      );

      expect(audio.tempPath, '/tmp/_temp/cap1_123.wav');
      expect(audio.displayName, 'Capitulo 1');
      expect(audio.format, 'wav');
      expect(audio.durationSec, 45.2);
      expect(audio.fileSizeBytes, 12_300_000);
    });

    test('equal cuando todos los campos coinciden', () {
      const a = AudioPendiente(
        tempPath: '/a.wav',
        displayName: 'X',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
      );
      const b = AudioPendiente(
        tempPath: '/a.wav',
        displayName: 'X',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
      );
      const c = AudioPendiente(
        tempPath: '/b.wav', // diferente
        displayName: 'X',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('props contiene los 5 campos', () {
      const audio = AudioPendiente(
        tempPath: '/x.wav',
        displayName: 'A',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
      );

      expect(audio.props, [
        '/x.wav',
        'A',
        'wav',
        1.0,
        100,
      ]);
    });

    test('es inmutable', () {
      const audio = AudioPendiente(
        tempPath: '/x.wav',
        displayName: 'A',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
      );

      // Los campos son finales, no se pueden reasignar.
      expect(() => audio as dynamic, returnsNormally);
    });
  });
}
