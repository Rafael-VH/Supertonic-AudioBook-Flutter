import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/device_spec.dart';

void main() {
  group('DeviceSpec.toMap / fromMap', () {
    test('roundtrip preserva los 5 campos', () {
      const original = DeviceSpec(
        brand: 'Google',
        model: 'Pixel 8',
        board: 'cheetah',
        hardware: 'cheetah',
        ramBytes: 8589934592,
      );

      final restored = DeviceSpec.fromMap(original.toMap());

      expect(restored.brand, 'Google');
      expect(restored.model, 'Pixel 8');
      expect(restored.board, 'cheetah');
      expect(restored.hardware, 'cheetah');
      expect(restored.ramBytes, 8589934592);
    });

    test('toMap usa claves snake_case', () {
      const spec = DeviceSpec(
        brand: 'Google',
        model: 'Pixel 8',
        board: 'cheetah',
        hardware: 'cheetah',
        ramBytes: 8589934592,
      );

      final map = spec.toMap();

      expect(map.keys, {
        'brand',
        'model',
        'board',
        'hardware',
        'ram_bytes',
      });
      expect(map['ram_bytes'], 8589934592);
    });

    test('todos los campos null produce un mapa solo con null', () {
      const spec = DeviceSpec();

      final map = spec.toMap();
      final restored = DeviceSpec.fromMap(map);

      expect(restored.brand, isNull);
      expect(restored.model, isNull);
      expect(restored.board, isNull);
      expect(restored.hardware, isNull);
      expect(restored.ramBytes, isNull);
    });

    test('claves ausentes se leen como null', () {
      final restored = DeviceSpec.fromMap(const <String, Object?>{});

      expect(restored.brand, isNull);
      expect(restored.model, isNull);
      expect(restored.board, isNull);
      expect(restored.hardware, isNull);
      expect(restored.ramBytes, isNull);
    });

    test('ram_bytes numérico se normaliza a int', () {
      final restored =
          DeviceSpec.fromMap(const {'ram_bytes': 8.5e9});

      expect(restored.ramBytes, isA<int>());
      expect(restored.ramBytes, (8.5e9).toInt());
    });
  });
}
