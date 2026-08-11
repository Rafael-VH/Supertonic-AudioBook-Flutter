import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/domain/use_cases/formato.dart';

void main() {
  group('normalizarFormatos', () {
    test('normaliza minúsculas, espacios y orden', () {
      expect(normalizarFormatos('wav,MP3'), ['wav', 'mp3']);
      expect(normalizarFormatos('  OGG  , flac'), ['ogg', 'flac']);
    });

    test('ignora duplicados y conserva el orden de aparición', () {
      expect(normalizarFormatos('wav,mp3,wav'), ['wav', 'mp3']);
    });

    test('ignora separadores vacíos', () {
      expect(normalizarFormatos('wav,,mp3,'), ['wav', 'mp3']);
    });

    test('lanza FormatoInvalido para formatos desconocidos', () {
      expect(() => normalizarFormatos('aac'), throwsA(isA<FormatoInvalido>()));
      expect(
        () => normalizarFormatos('wav,aac'),
        throwsA(isA<FormatoInvalido>()),
      );
    });

    test('devuelve lista vacía para entrada vacía', () {
      expect(normalizarFormatos(''), isEmpty);
      expect(normalizarFormatos('  '), isEmpty);
    });
  });
}
