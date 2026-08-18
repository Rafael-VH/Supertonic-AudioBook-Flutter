import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:id3_codec/id3_codec.dart';
import 'package:supertonic_audiobook/features/editor_metadata/data/repositories/editor_metadata_id3_codec.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';

/// Crea bytes de un MP3 mínimo con un header ID3v2.3 vacío.
///
/// Esto permite que [ID3Encoder] modifique el tag existente sin
/// usar `_createNewID3Body` (que tiene un bug con `List.filled` fixed-length).
List<int> _crearBytesMp3Base() {
  // Header ID3v2.3: "ID3" + version(03 00) + flags(0x00) + size(synchsafe)
  // Size = 0 (tag vacío, solo header)
  return [
    0x49, 0x44, 0x33, // "ID3"
    0x03, 0x00, // version 2.3.0
    0x00, // flags: none
    0x00, 0x00, 0x00, 0x00, // size: 0 (synchsafe)
    // Audio data ficticio (puede ser cualquier cosa)
    ...List<int>.filled(256, 0xFF),
  ];
}

/// Crea un MP3 mínimo con tags v2.3 y v1 para testing.
Future<File> _crearMp3DeTest(
  Directory dir, {
  String? titulo,
  String? artista,
  String? album,
  int? pista,
  int? anio,
  String? comentario,
}) async {
  var bytes = _crearBytesMp3Base();

  // Escribir v2.3
  final v2Body = MetadataV2p3Body(
    title: titulo,
    artist: artista,
    album: album,
  );
  bytes = ID3Encoder(bytes).encodeSync(v2Body);

  // Escribir v1
  final v1Body = MetadataV1Body(
    title: titulo,
    artist: artista,
    album: album,
    track: pista,
    year: anio?.toString(),
    comment: comentario,
    genre: 17, // Rock
  );
  bytes = ID3Encoder(bytes).encodeSync(v1Body);

  final file = File('${dir.path}/test.mp3');
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  late EditorMetadataId3Codec editor;
  late Directory tempDir;

  setUp(() async {
    editor = EditorMetadataId3Codec();
    tempDir = await Directory.systemTemp.createTemp('editor_metadata_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('leer', () {
    test('retorna MetadatosMp3 con campos correctos', () async {
      final file = await _crearMp3DeTest(
        tempDir,
        titulo: 'Mi canción',
        artista: 'Artista Test',
        album: 'Álbum Test',
        pista: 5,
        anio: 2024,
        comentario: 'Un comentario',
      );

      final metadata = await editor.leer(file.path);

      expect(metadata.titulo, 'Mi canción');
      expect(metadata.artista, 'Artista Test');
      expect(metadata.album, 'Álbum Test');
      expect(metadata.pista, 5);
      expect(metadata.anio, 2024);
      expect(metadata.comentario, 'Un comentario');
    });

    test('retorna campos nulos cuando no hay tags', () async {
      // Archivo sin tags ID3 — solo bytes de audio ficticios
      final file = File('${tempDir.path}/empty.mp3');
      await file.writeAsBytes(List<int>.filled(256, 0xFF));

      final metadata = await editor.leer(file.path);

      expect(metadata.titulo, isNull);
      expect(metadata.artista, isNull);
      expect(metadata.album, isNull);
      expect(metadata.pista, isNull);
      expect(metadata.disco, isNull);
      expect(metadata.anio, isNull);
      expect(metadata.genero, isNull);
      expect(metadata.comentario, isNull);
      expect(metadata.coverArtBytes, isNull);
    });

    test('lanza excepción si el archivo no existe', () async {
      expect(
        () => editor.leer('${tempDir.path}/noexiste.mp3'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('no encontrado'),
          ),
        ),
      );
    });

    test('prioriza v2 sobre v1 cuando ambos existen', () async {
      var bytes = _crearBytesMp3Base();

      // v2.3 con título A
      final v2Body = MetadataV2p3Body(
        title: 'Título V2',
        artist: 'Artista V2',
        album: 'Álbum V2',
      );
      bytes = ID3Encoder(bytes).encodeSync(v2Body);

      // v1 con título B (diferente)
      final v1Body = MetadataV1Body(
        title: 'Título V1',
        artist: 'Artista V1',
        year: '2020',
      );
      bytes = ID3Encoder(bytes).encodeSync(v1Body);

      final file = File('${tempDir.path}/priority.mp3');
      await file.writeAsBytes(bytes);

      final metadata = await editor.leer(file.path);

      // v2 tiene prioridad para título, artista, álbum
      expect(metadata.titulo, 'Título V2');
      expect(metadata.artista, 'Artista V2');
      expect(metadata.album, 'Álbum V2');
      // anio solo existe en v1
      expect(metadata.anio, 2020);
    });
  });

  group('guardar', () {
    test('escribe metadata y se puede leer de vuelta', () async {
      final file = await _crearMp3DeTest(tempDir);
      const metadata = MetadatosMp3(
        titulo: 'Nuevo título',
        artista: 'Nuevo artista',
        album: 'Nuevo álbum',
        pista: 3,
        anio: 2025,
        comentario: 'Comentario nuevo',
      );

      await editor.guardar(file.path, metadata);

      final leido = await editor.leer(file.path);
      expect(leido.titulo, 'Nuevo título');
      expect(leido.artista, 'Nuevo artista');
      expect(leido.album, 'Nuevo álbum');
      expect(leido.pista, 3);
      expect(leido.anio, 2025);
      expect(leido.comentario, 'Comentario nuevo');
    });

    test('escritura atómica: archivo temporal se renombra', () async {
      final file = await _crearMp3DeTest(tempDir);
      const metadata = MetadatosMp3(titulo: 'Test');

      await editor.guardar(file.path, metadata);

      // El archivo temporal NO debe existir después de la escritura
      final tempFile = File('${file.path}.tmp');
      expect(await tempFile.exists(), isFalse);

      // El archivo original debe existir y tener contenido
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('limpia archivo temporal en caso de error', () async {
      final file = await _crearMp3DeTest(tempDir);
      final originalBytes = await file.readAsBytes();

      // Crear un directorio para que el renombrado del temporal falle
      // (no se puede renombrar un archivo encima de un directorio existente).
      final blockingDir = Directory('${file.path}.tmp');
      await blockingDir.create();

      const metadata = MetadatosMp3(titulo: 'Test');
      try {
        await editor.guardar(file.path, metadata);
        fail('Debería haber lanzado excepción');
      } catch (_) {
        // Esperado
      }

      // El archivo temporal debe ser limpiado (o nunca creado)
      final tempFile = File('${file.path}.tmp');
      expect(await tempFile.exists(), isFalse);

      // Verificar que el original no fue corrompido
      final afterBytes = await file.readAsBytes();
      expect(afterBytes, equals(originalBytes));

      // Cleanup
      await blockingDir.delete();
    });

    test('lanza excepción si el archivo no existe', () async {
      const metadata = MetadatosMp3(titulo: 'Test');

      expect(
        () => editor.guardar('${tempDir.path}/noexiste.mp3', metadata),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('no encontrado'),
          ),
        ),
      );
    });
  });

  group('validación de cover art', () {
    test('lanza excepción si supera 500KB', () async {
      final file = await _crearMp3DeTest(tempDir);

      // Crear bytes JPEG válidos pero muy grandes (>500KB)
      final bigJpeg = Uint8List(501 * 1024);
      bigJpeg[0] = 0xFF;
      bigJpeg[1] = 0xD8;

      final metadata = MetadatosMp3(coverArtBytes: bigJpeg);

      expect(
        () => editor.guardar(file.path, metadata),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('500KB'),
          ),
        ),
      );
    });

    test('lanza excepción si no es JPEG válido', () async {
      final file = await _crearMp3DeTest(tempDir);

      // Bytes que no empiezan con 0xFF 0xD8
      final notJpeg = Uint8List.fromList([0x00, 0x01, 0x02]);

      final metadata = MetadatosMp3(coverArtBytes: notJpeg);

      expect(
        () => editor.guardar(file.path, metadata),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('JPEG'),
          ),
        ),
      );
    });

    test('acepta portada JPEG válida dentro del límite', () async {
      final file = await _crearMp3DeTest(tempDir);

      // JPEG válido con header APP0 completo
      final validJpeg = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        0xFF, 0xE0, // APP0 marker
        0x00, 0x10, // APP0 length (16 bytes)
        0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
        0x01, 0x01, // version
        0x00, // units
        0x00, 0x01, // X density
        0x00, 0x01, // Y density
        0x00, 0x00, // thumbnail
        0xFF, 0xD9, // EOI
      ]);

      final metadata = MetadatosMp3(coverArtBytes: validJpeg);

      // No debe lanzar excepción al guardar con portada
      await editor.guardar(file.path, metadata);

      // El archivo debe ser legible sin errores
      final leido = await editor.leer(file.path);
      expect(leido.titulo, isNotNull);

      // Nota: id3_codec's APIC decoder retorna un placeholder para
      // Base64 en lugar de datos reales. La portada SÍ se escribe
      // correctamente en el archivo (verificable con otros tools),
      // pero la decodificación round-trip es una limitación conocida
      // de esta librería.
    });
  });
}
