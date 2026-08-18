import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/contracts/editor_metadata.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/use_cases/editar_metadata_mp3.dart';

class MockEditorMetadata extends Mock implements EditorMetadata {}

void main() {
  late MockEditorMetadata mockEditor;
  late EditarMetadataMp3 useCase;

  setUp(() {
    mockEditor = MockEditorMetadata();
    useCase = EditarMetadataMp3(mockEditor);
  });

  group('ejecutar', () {
    test('delega a editor.leer()', () async {
      const esperado = MetadatosMp3(titulo: 'Canción', pista: 3);
      when(() => mockEditor.leer('/path/audio.mp3'))
          .thenAnswer((_) async => esperado);

      final resultado = await useCase.ejecutar('/path/audio.mp3');

      expect(resultado, equals(esperado));
      verify(() => mockEditor.leer('/path/audio.mp3')).called(1);
    });

    test('propaga errores del editor', () async {
      when(() => mockEditor.leer('/bad.mp3'))
          .thenThrow(Exception('archivo corrupto'));

      expect(
        () => useCase.ejecutar('/bad.mp3'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('archivo corrupto'),
        )),
      );
    });
  });

  group('aplicar', () {
    test('delega a editor.guardar()', () async {
      const metadata = MetadatosMp3(
        titulo: 'Nuevo título',
        artista: 'Nuevo artista',
      );
      when(() => mockEditor.guardar('/path/audio.mp3', metadata))
          .thenAnswer((_) async {});

      await useCase.aplicar('/path/audio.mp3', metadata);

      verify(() => mockEditor.guardar('/path/audio.mp3', metadata)).called(1);
    });

    test('propaga errores del editor', () async {
      const metadata = MetadatosMp3(titulo: 'X');
      when(() => mockEditor.guardar('/bad.mp3', metadata))
          .thenThrow(Exception('escritura fallida'));

      expect(
        () => useCase.aplicar('/bad.mp3', metadata),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('escritura fallida'),
        )),
      );
    });
  });
}
