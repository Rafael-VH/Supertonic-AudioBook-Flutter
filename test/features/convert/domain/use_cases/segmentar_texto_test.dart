import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/segmentar_texto.dart';

void main() {
  group('segmentarTexto', () {
    test('respeta párrafos existentes', () {
      final largo = List.filled(20, 'Palabra larga. ').join();
      final resultado = segmentarTexto('$largo\n\n$largo\n\n$largo');
      expect(resultado, hasLength(3));
    });

    test('fusiona párrafos cortos', () {
      final resultado = segmentarTexto('Corto.\n\nTambién corto.\n\nLargo.');
      expect(resultado.length, lessThan(3));
    });

    test('divide párrafos largos por oraciones', () {
      final parrafo = '${List.filled(120, 'Oración una. ').join()}Oración final.';
      expect(parrafo.length, greaterThan(maxCharsPerSegment));
      final resultado = segmentarTexto(parrafo);
      expect(resultado.length, greaterThan(1));
      for (final segmento in resultado) {
        expect(segmento.length, lessThanOrEqualTo(maxCharsPerSegment));
      }
    });

    test('no parte abreviaturas españolas', () {
      final parrafo =
          List.filled(40, 'El Dr. Pérez llegó a tiempo. ').join().trim();
      final resultado = segmentarTexto(parrafo);
      for (final segmento in resultado) {
        expect(segmento, contains('Dr.'));
      }
    });

    test('el párrafo corto se mantiene entero', () {
      expect(segmentarTexto('Hola mundo.'), ['Hola mundo.']);
    });

    test('una frase que excede el límite se parte sin emitir vacíos', () {
      // Sin puntos: `_dividirEnOraciones` devuelve la frase entera como una
      // sola subfrase de >maxCharsPerSegment.
      final fraseLarga = 'a' * (maxCharsPerSegment + 100);
      final resultado = segmentarTexto(fraseLarga);

      expect(resultado, isNotEmpty);
      expect(resultado, everyElement(isNotEmpty));
      for (final segmento in resultado) {
        expect(segmento.length, lessThanOrEqualTo(maxCharsPerSegment));
      }
      // No se pierde texto: la unión reconstruye la frase original.
      expect(resultado.join(' ').replaceAll(' ', ''), fraseLarga);
    });
  });
}
