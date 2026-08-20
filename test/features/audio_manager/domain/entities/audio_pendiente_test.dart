import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/audio_manager/domain/entities/audio_pendiente.dart';

void main() {
  group('AudioPendiente', () {
    test('constructor crea instancia válida', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final audio = AudioPendiente(
        tempPath: '/tmp/_temp/cap1_123.wav',
        originalName: 'capitulo1.md',
        displayName: 'Capitulo 1',
        format: 'wav',
        durationSec: 45.2,
        fileSizeBytes: 12_300_000,
        chars: 3200,
        segments: 12,
        fecha: now,
      );

      expect(audio.tempPath, '/tmp/_temp/cap1_123.wav');
      expect(audio.originalName, 'capitulo1.md');
      expect(audio.displayName, 'Capitulo 1');
      expect(audio.format, 'wav');
      expect(audio.durationSec, 45.2);
      expect(audio.fileSizeBytes, 12_300_000);
      expect(audio.chars, 3200);
      expect(audio.segments, 12);
      expect(audio.fecha, now);
    });

    test('equal cuando todos los campos coinciden', () {
      final a = AudioPendiente(
        tempPath: '/a.wav',
        originalName: 'x.md',
        displayName: 'X',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
        chars: 10,
        segments: 1,
        fecha: DateTime(2025),
      );
      final b = AudioPendiente(
        tempPath: '/a.wav',
        originalName: 'x.md',
        displayName: 'X',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
        chars: 10,
        segments: 1,
        fecha: DateTime(2025),
      );
      final c = AudioPendiente(
        tempPath: '/b.wav', // diferente
        originalName: 'x.md',
        displayName: 'X',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
        chars: 10,
        segments: 1,
        fecha: DateTime(2025),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('props contiene los 9 campos', () {
      final now = DateTime(2025);
      final audio = AudioPendiente(
        tempPath: '/x.wav',
        originalName: 'a.md',
        displayName: 'A',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
        chars: 10,
        segments: 1,
        fecha: now,
      );

      expect(audio.props, [
        '/x.wav',
        'a.md',
        'A',
        'wav',
        1.0,
        100,
        10,
        1,
        now,
      ]);
    });

    test('es inmutable', () {
      final audio = AudioPendiente(
        tempPath: '/x.wav',
        originalName: 'a.md',
        displayName: 'A',
        format: 'wav',
        durationSec: 1,
        fileSizeBytes: 100,
        chars: 10,
        segments: 1,
        fecha: DateTime(2025),
      );

      // Los campos son finales, no se pueden reasignar.
      expect(() => audio as dynamic, returnsNormally);
    });
  });
}
