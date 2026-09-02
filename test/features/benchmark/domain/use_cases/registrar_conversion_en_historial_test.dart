import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/registrar_conversion_en_historial.dart';

import '../../../../support/fakes.dart';

void main() {
  group('RegistrarConversionEnHistorial', () {
    late PreferenciasMemoria preferencias;

    setUp(() {
      preferencias = PreferenciasMemoria();
    });

    test('prepend entries to empty history', () {
      final useCase = RegistrarConversionEnHistorial(preferencias);

      useCase([
        {'nombreArchivo': 'a.md', 'caracteres': 100},
      ]);

      final datos = preferencias.cargar();
      final historial = datos['conversion_history'] as List;
      expect(historial, hasLength(1));
      expect(historial.first['nombreArchivo'], 'a.md');
    });

    test('prepend preserves order: newest first', () {
      final useCase = RegistrarConversionEnHistorial(preferencias);

      useCase([
        {'nombreArchivo': 'a.md', 'caracteres': 100},
      ]);
      useCase([
        {'nombreArchivo': 'b.md', 'caracteres': 200},
      ]);

      final datos = preferencias.cargar();
      final historial = (datos['conversion_history'] as List)
          .cast<Map<String, Object?>>();
      expect(historial[0]['nombreArchivo'], 'b.md');
      expect(historial[1]['nombreArchivo'], 'a.md');
    });

    test('merges with existing history entries', () {
      preferencias = PreferenciasMemoria({
        'conversion_history': [
          {'nombreArchivo': 'existing.md', 'caracteres': 50},
        ],
      });
      final useCase = RegistrarConversionEnHistorial(preferencias);

      useCase([
        {'nombreArchivo': 'new.md', 'caracteres': 100},
      ]);

      final datos = preferencias.cargar();
      final historial = (datos['conversion_history'] as List)
          .cast<Map<String, Object?>>();
      expect(historial, hasLength(2));
      expect(historial[0]['nombreArchivo'], 'new.md');
      expect(historial[1]['nombreArchivo'], 'existing.md');
    });

    test('caps at 100 entries', () {
      final existing = [
        for (var i = 0; i < 100; i++)
          {'nombreArchivo': 'old_$i.md', 'caracteres': i},
      ];
      preferencias = PreferenciasMemoria({
        'conversion_history': existing,
      });
      final useCase = RegistrarConversionEnHistorial(preferencias);

      useCase([
        {'nombreArchivo': 'new.md', 'caracteres': 999},
      ]);

      final datos = preferencias.cargar();
      final historial = datos['conversion_history'] as List;
      expect(historial, hasLength(100));
      expect(historial.first['nombreArchivo'], 'new.md');
      // Last entry (index 99) should be old_98 (old_99 got dropped)
      expect(historial.last['nombreArchivo'], 'old_98.md');
    });

    test('handles non-list raw data gracefully', () {
      preferencias = PreferenciasMemoria({
        'conversion_history': 'invalid',
      });
      final useCase = RegistrarConversionEnHistorial(preferencias);

      useCase([
        {'nombreArchivo': 'a.md', 'caracteres': 10},
      ]);

      final datos = preferencias.cargar();
      final historial = datos['conversion_history'] as List;
      expect(historial, hasLength(1));
      expect(historial.first['nombreArchivo'], 'a.md');
    });
  });
}
