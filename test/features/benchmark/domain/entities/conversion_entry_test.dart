import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';

void main() {
  group('ConversionEntry', () {
    final fecha = DateTime(2026, 8, 19, 12, 0);

    group('constructor', () {
      test('crea con todos los campos', () {
        final e = ConversionEntry(
          nombreArchivo: 'test.md',
          caracteres: 100,
          segmentos: 2,
          duracionAudioSeg: 3.5,
          fecha: fecha,
        );
        expect(e.nombreArchivo, 'test.md');
        expect(e.caracteres, 100);
        expect(e.segmentos, 2);
        expect(e.duracionAudioSeg, 3.5);
        expect(e.fecha, fecha);
      });
    });

    group('toMap / fromMap', () {
      test('roundtrip preserva todos los campos', () {
        final original = ConversionEntry(
          nombreArchivo: 'capitulo01.md',
          caracteres: 4500,
          segmentos: 5,
          duracionAudioSeg: 12.5,
          fecha: fecha,
        );
        final map = original.toMap();
        final restored = ConversionEntry.fromMap(map);

        expect(restored.nombreArchivo, original.nombreArchivo);
        expect(restored.caracteres, original.caracteres);
        expect(restored.segmentos, original.segmentos);
        expect(restored.duracionAudioSeg, original.duracionAudioSeg);
        expect(restored.fecha, original.fecha);
      });

      test('fecha se serializa como ISO 8601 string', () {
        final e = ConversionEntry(
          nombreArchivo: 'x.md',
          caracteres: 0,
          segmentos: 0,
          duracionAudioSeg: 0,
          fecha: fecha,
        );
        final map = e.toMap();
        expect(map['fecha'], isA<String>());
        expect(map['fecha'], fecha.toIso8601String());
      });

      test('fromMap maneja defaults para campos faltantes', () {
        final map = <String, Object?>{
          'nombreArchivo': '',
          'fecha': '2026-01-01T00:00:00.000',
          // caracteres, segmentos, duracionAudioSeg ausentes
        };
        final e = ConversionEntry.fromMap(map);
        expect(e.nombreArchivo, '');
        expect(e.caracteres, 0);
        expect(e.segmentos, 0);
        expect(e.duracionAudioSeg, 0.0);
      });

      test('fromMap maneja fecha malformada con DateTime.now()', () {
        final before = DateTime.now();
        final map = <String, Object?>{
          'nombreArchivo': 'test.md',
          'caracteres': 10,
          'segmentos': 1,
          'duracionAudioSeg': 2.0,
          'fecha': 'not-a-date',
        };
        final e = ConversionEntry.fromMap(map);
        expect(e.fecha.isAfter(before.subtract(const Duration(seconds: 2))), true);
      });

      test('roundtrip preserva valores grandes', () {
        final original = ConversionEntry(
          nombreArchivo: 'large.md',
          caracteres: 30000,
          segmentos: 100,
          duracionAudioSeg: 250.75,
          fecha: DateTime(2026, 12, 31, 23, 59, 59),
        );
        final restored = ConversionEntry.fromMap(original.toMap());
        expect(restored.nombreArchivo, original.nombreArchivo);
        expect(restored.caracteres, original.caracteres);
        expect(restored.segmentos, original.segmentos);
        expect(restored.duracionAudioSeg, original.duracionAudioSeg);
        expect(restored.fecha, original.fecha);
      });
    });
  });
}
