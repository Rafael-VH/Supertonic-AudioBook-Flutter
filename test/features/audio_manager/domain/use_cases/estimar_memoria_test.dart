import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/audio_manager/domain/entities/audio_pendiente.dart';
import 'package:supertonic_audiobook/features/audio_manager/domain/use_cases/estimar_memoria.dart';

void main() {
  group('estimarBytesAudio', () {
    test('calcula bytes para chars conocidos', () {
      // 1000 chars → ceil(1000 * 4.0) = 4000 bytes
      final bytes = estimarBytesAudio(1000);
      expect(bytes, 4000);
    });

    test('cero chars devuelve cero', () {
      expect(estimarBytesAudio(0), 0);
    });

    test('valor razonable para texto largo', () {
      // 100,000 chars → ceil(100000 * 4.0) = 400,000 bytes (~390 KB)
      final bytes = estimarBytesAudio(100_000);
      expect(bytes, 400_000);
    });
  });

  group('estimarBytesLote', () {
    test('suma estimación de bytes de cada audio por chars', () {
      final audios = [
        AudioPendiente(
          tempPath: '/a.wav',
          originalName: 'a.md',
          displayName: 'A',
          format: 'wav',
          durationSec: 1,
          fileSizeBytes: 1000,
          chars: 100,
          segments: 5,
          fecha: DateTime(2025),
        ),
        AudioPendiente(
          tempPath: '/b.wav',
          originalName: 'b.md',
          displayName: 'B',
          format: 'wav',
          durationSec: 2,
          fileSizeBytes: 2000,
          chars: 200,
          segments: 10,
          fecha: DateTime(2025),
        ),
      ];

      // 100 chars → 400, 200 chars → 800, total = 1200
      expect(estimarBytesLote(audios), 1200);
    });

    test('lista vacía devuelve cero', () {
      expect(estimarBytesLote([]), 0);
    });
  });

  group('fraccionMemoriaRequerida', () {
    test('devuelve fracción correcta', () {
      expect(fraccionMemoriaRequerida(70, 100), 0.7);
    });

    test('total cero devuelve 1.0 (seguro por defecto)', () {
      expect(fraccionMemoriaRequerida(1000, 0), 1.0);
    });

    test('total negativo devuelve 1.0', () {
      expect(fraccionMemoriaRequerida(1000, -1), 1.0);
    });

    test('estimados cero devuelve 0.0', () {
      expect(fraccionMemoriaRequerida(0, 1000), 0.0);
    });
  });
}
