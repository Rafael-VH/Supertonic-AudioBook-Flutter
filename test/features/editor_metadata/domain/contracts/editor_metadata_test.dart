import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/contracts/editor_metadata.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';

/// Implementación fake del contrato para verificar que compila correctamente.
class FakeEditorMetadata implements EditorMetadata {
  @override
  Future<MetadatosMp3> leer(String rutaMp3) async =>
      const MetadatosMp3(titulo: 'fake');

  @override
  Future<void> guardar(String rutaMp3, MetadatosMp3 metadata) async {}
}

void main() {
  group('EditorMetadata contract', () {
    test('compila como interfaz abstracta', () {
      // Verifica que la interfaz se puede importar y referenciar.
      expect(EditorMetadata, isA<Type>());
    });

    test('fake implementation puede instanciarse y usarse', () async {
      final fake = FakeEditorMetadata();

      final metadata = await fake.leer('/test.mp3');
      expect(metadata.titulo, 'fake');

      // guardar no lanza excepciones
      await fake.guardar('/test.mp3', metadata);
    });
  });
}
