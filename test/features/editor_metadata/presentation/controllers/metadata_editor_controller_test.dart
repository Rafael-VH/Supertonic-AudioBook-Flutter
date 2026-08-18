import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/editor_metadata/domain/contracts/editor_metadata.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/use_cases/editar_metadata_mp3.dart';
import 'package:supertonic_audiobook/features/editor_metadata/presentation/controllers/metadata_editor_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

import '../../../../support/fakes.dart';

/// Fake de EditorMetadata que registra llamadas y permite inyectar errores.
class _EditorMetadataFake implements EditorMetadata {
  MetadatosMp3? metadataLeida;
  String? rutaLeida;
  String? rutaGuardada;
  MetadatosMp3? metadataGuardada;
  Exception? errorLeer;
  Exception? errorGuardar;

  @override
  Future<MetadatosMp3> leer(String rutaMp3) async {
    rutaLeida = rutaMp3;
    if (errorLeer != null) throw errorLeer!;
    return metadataLeida ?? const MetadatosMp3();
  }

  @override
  Future<void> guardar(String rutaMp3, MetadatosMp3 metadata) async {
    rutaGuardada = rutaMp3;
    metadataGuardada = metadata;
    if (errorGuardar != null) throw errorGuardar!;
  }
}

/// Stub de EditarMetadataMp3 que delega al fake.
class _EditarMetadataMp3Stub extends EditarMetadataMp3 {
  _EditarMetadataMp3Stub(this._fake) : super(_fake);

  final _EditorMetadataFake _fake;

  @override
  Future<MetadatosMp3> ejecutar(String rutaMp3) => _fake.leer(rutaMp3);

  @override
  Future<void> aplicar(String rutaMp3, MetadatosMp3 metadata) =>
      _fake.guardar(rutaMp3, metadata);
}

void main() {
  late _EditorMetadataFake fakeEditor;
  late _EditarMetadataMp3Stub fakeUseCase;
  late FilePickerFake fakePicker;

  setUp(() {
    fakeEditor = _EditorMetadataFake();
    fakeUseCase = _EditarMetadataMp3Stub(fakeEditor);
    fakePicker = FilePickerFake(null);
    FilePickerPlatform.instance = fakePicker;
  });

  ProviderContainer crearContenedor() => ProviderContainer(
        overrides: [
          editarMetadataMp3Provider.overrideWithValue(fakeUseCase),
        ],
      );

  group('MetadataEditorController', () {
    test('estado inicial está vacío', () {
      final container = crearContenedor();
      final estado = container.read(metadataEditorControllerProvider);

      expect(estado.metadata, const MetadatosMp3());
      expect(estado.rutaArchivo, isNull);
      expect(estado.nombreArchivo, isNull);
      expect(estado.isLoading, isFalse);
      expect(estado.isSaving, isFalse);
      expect(estado.error, isNull);
      expect(estado.mensajeExito, isNull);
    });

    test('cargar() establece metadata y rutaArchivo', () async {
      const esperado = MetadatosMp3(
        titulo: 'Canción',
        artista: 'Artista',
        album: 'Álbum',
      );
      fakeEditor.metadataLeida = esperado;

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.cargar('/path/audio.mp3');

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.metadata, equals(esperado));
      expect(estado.rutaArchivo, '/path/audio.mp3');
      expect(estado.isLoading, isFalse);
      expect(estado.error, isNull);
      expect(fakeEditor.rutaLeida, '/path/audio.mp3');
    });

    test('cargar() con archivo inexistente establece error', () async {
      fakeEditor.errorLeer = Exception('Archivo no encontrado: /bad.mp3');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.cargar('/bad.mp3');

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.error, contains('Archivo no encontrado'));
      expect(estado.isLoading, isFalse);
      expect(estado.rutaArchivo, isNull);
    });

    test('actualizarCampo() actualiza un campo específico', () async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Original');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/audio.mp3');

      controller.actualizarCampo(
        (actual) => actual.copyWith(titulo: 'Cambiado'),
      );

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.metadata.titulo, 'Cambiado');
      expect(estado.metadata.artista, isNull);
    });

    test('guardar() llama a aplicar en el use case', () async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Test');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/audio.mp3');

      await controller.guardar();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.isSaving, isFalse);
      expect(estado.mensajeExito, contains('guardados correctamente'));
      expect(estado.error, isNull);
      expect(fakeEditor.rutaGuardada, '/path/audio.mp3');
      expect(fakeEditor.metadataGuardada?.titulo, 'Test');
    });

    test('guardar() con error establece error en el estado', () async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Test');
      fakeEditor.errorGuardar = Exception('escritura fallida');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/audio.mp3');

      await controller.guardar();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.isSaving, isFalse);
      expect(estado.error, contains('escritura fallida'));
      expect(estado.mensajeExito, isNull);
    });

    test('guardar() sin archivo seleccionado establece error', () async {
      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.guardar();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.error, contains('No hay archivo'));
    });

    test('reset() limpia todo el estado', () async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Test');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/audio.mp3');
      expect(
        container.read(metadataEditorControllerProvider).rutaArchivo,
        isNotNull,
      );

      controller.reset();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.metadata, const MetadatosMp3());
      expect(estado.rutaArchivo, isNull);
      expect(estado.nombreArchivo, isNull);
      expect(estado.isLoading, isFalse);
      expect(estado.isSaving, isFalse);
      expect(estado.error, isNull);
      expect(estado.mensajeExito, isNull);
    });

    test('seleccionarArchivo() abre picker y carga el archivo', () async {
      fakePicker.resultado = FilePickerResult([
        PlatformFile(
          name: 'test.mp3',
          size: 1000,
          path: '/path/test.mp3',
        ),
      ]);
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Pickado');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.seleccionarArchivo();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.nombreArchivo, 'test.mp3');
      expect(estado.rutaArchivo, '/path/test.mp3');
      expect(estado.metadata.titulo, 'Pickado');
      expect(fakePicker.llamadas, 1);
      expect(fakePicker.ultimasExtensiones, ['mp3']);
    });

    test('seleccionarArchivo() cancelado no cambia el estado', () async {
      fakePicker.resultado = null;

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.seleccionarArchivo();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.rutaArchivo, isNull);
    });

    test('seleccionarCoverArt() agrega portada al estado', () async {
      final jpegBytes = Uint8List.fromList(
        [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(100, 0)],
      );
      fakePicker.resultado = FilePickerResult([
        PlatformFile(
          name: 'cover.jpg',
          size: jpegBytes.length,
          bytes: jpegBytes,
        ),
      ]);

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.seleccionarCoverArt();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.metadata.coverArtBytes, isNotNull);
      expect(estado.metadata.coverArtMime, 'image/jpeg');
    });

    test('seleccionarCoverArt() rechaza imagen mayor a 500KB', () async {
      final bigBytes = Uint8List(501 * 1024);
      bigBytes[0] = 0xFF;
      bigBytes[1] = 0xD8;
      fakePicker.resultado = FilePickerResult([
        PlatformFile(
          name: 'big.jpg',
          size: bigBytes.length,
          bytes: bigBytes,
        ),
      ]);

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);

      await controller.seleccionarCoverArt();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.error, contains('500KB'));
      expect(estado.metadata.coverArtBytes, isNull);
    });

    test('quitarCoverArt() elimina la portada', () async {
      final jpegBytes = Uint8List.fromList(
        [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(100, 0)],
      );
      fakePicker.resultado = FilePickerResult([
        PlatformFile(
          name: 'cover.jpg',
          size: jpegBytes.length,
          bytes: jpegBytes,
        ),
      ]);

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.seleccionarCoverArt();
      expect(
        container
            .read(metadataEditorControllerProvider)
            .metadata
            .coverArtBytes,
        isNotNull,
      );

      controller.quitarCoverArt();

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.metadata.coverArtBytes, isNull);
      expect(estado.metadata.coverArtMime, isNull);
    });

    test('copyWith conserva campos no modificados', () {
      const original = MetadataEditorState(
        metadata: MetadatosMp3(titulo: 'A'),
        rutaArchivo: '/path',
        nombreArchivo: 'file.mp3',
        isLoading: true,
        isSaving: true,
        error: 'err',
        mensajeExito: 'ok',
      );

      final copia = original.copyWith(isLoading: false);

      expect(copia.isLoading, isFalse);
      expect(copia.isSaving, isTrue);
      expect(copia.metadata.titulo, 'A');
      expect(copia.rutaArchivo, '/path');
      expect(copia.error, 'err');
      expect(copia.mensajeExito, 'ok');
    });

    test('copyWith clearError limpia el error', () {
      const original = MetadataEditorState(error: 'fail');
      final copia = original.copyWith(clearError: true);
      expect(copia.error, isNull);
    });

    test('copyWith clearMensajeExito limpia el mensaje', () {
      const original = MetadataEditorState(mensajeExito: 'ok');
      final copia = original.copyWith(clearMensajeExito: true);
      expect(copia.mensajeExito, isNull);
    });

    test('actualizarCampo() limpia error y mensaje de éxito', () async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Test');

      final container = crearContenedor();
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/audio.mp3');

      controller.actualizarCampo(
        (actual) => actual.copyWith(titulo: 'X'),
      );

      final estado = container.read(metadataEditorControllerProvider);
      expect(estado.error, isNull);
      expect(estado.mensajeExito, isNull);
    });
  });
}
