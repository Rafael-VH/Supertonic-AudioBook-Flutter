import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';

void main() {
  group('MetadatosMp3', () {
    group('constructor', () {
      test('crea con todos los campos poblados', () {
        final cover = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
        final m = MetadatosMp3(
          titulo: 'El principito',
          artista: 'Saint-Exupéry',
          album: 'Clásicos',
          pista: 1,
          disco: 1,
          anio: 1943,
          genero: 'Ficción',
          comentario: 'Edición anniversary',
          coverArtBytes: cover,
          coverArtMime: 'image/jpeg',
        );

        expect(m.titulo, 'El principito');
        expect(m.artista, 'Saint-Exupéry');
        expect(m.album, 'Clásicos');
        expect(m.pista, 1);
        expect(m.disco, 1);
        expect(m.anio, 1943);
        expect(m.genero, 'Ficción');
        expect(m.comentario, 'Edición anniversary');
        expect(m.coverArtBytes, cover);
        expect(m.coverArtMime, 'image/jpeg');
      });

      test('crea con todos los campos nulos', () {
        const m = MetadatosMp3();

        expect(m.titulo, isNull);
        expect(m.artista, isNull);
        expect(m.album, isNull);
        expect(m.pista, isNull);
        expect(m.disco, isNull);
        expect(m.anio, isNull);
        expect(m.genero, isNull);
        expect(m.comentario, isNull);
        expect(m.coverArtBytes, isNull);
        expect(m.coverArtMime, isNull);
      });
    });

    group('copyWith', () {
      test('actualiza campos específicos', () {
        const original = MetadatosMp3(
          titulo: 'Título viejo',
          artista: 'Artista A',
          anio: 2020,
        );

        final actualizado = original.copyWith(
          titulo: 'Título nuevo',
          anio: 2024,
        );

        expect(actualizado.titulo, 'Título nuevo');
        expect(actualizado.anio, 2024);
        expect(actualizado.artista, 'Artista A');
      });

      test('preserva campos no modificados', () {
        final cover = Uint8List.fromList([1, 2, 3]);
        final original = MetadatosMp3(
          titulo: 'T1',
          artista: 'A1',
          album: 'B1',
          pista: 3,
          disco: 2,
          anio: 1999,
          genero: 'Rock',
          comentario: 'com',
          coverArtBytes: cover,
          coverArtMime: 'image/png',
        );

        final copia = original.copyWith(album: 'B2');

        expect(copia.titulo, 'T1');
        expect(copia.artista, 'A1');
        expect(copia.album, 'B2');
        expect(copia.pista, 3);
        expect(copia.disco, 2);
        expect(copia.anio, 1999);
        expect(copia.genero, 'Rock');
        expect(copia.comentario, 'com');
        expect(copia.coverArtBytes, cover);
        expect(copia.coverArtMime, 'image/png');
      });

      test('limpia un campo con clearXxx', () {
        const original = MetadatosMp3(
          titulo: 'Título',
          artista: 'Artista',
        );

        final limpiado = original.copyWith(clearTitulo: true);

        expect(limpiado.titulo, isNull);
        expect(limpiado.artista, 'Artista');
      });
    });

    group('igualdad', () {
      test('misma referencia es igual', () {
        const m = MetadatosMp3(titulo: 'T', pista: 1);
        expect(m, equals(m));
      });

      test('mismos valores son iguales', () {
        const a = MetadatosMp3(
          titulo: 'T',
          artista: 'A',
          pista: 1,
          anio: 2024,
        );
        const b = MetadatosMp3(
          titulo: 'T',
          artista: 'A',
          pista: 1,
          anio: 2024,
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('diferentes valores no son iguales', () {
        const a = MetadatosMp3(titulo: 'T1');
        const b = MetadatosMp3(titulo: 'T2');
        expect(a, isNot(equals(b)));
      });

      test('coverArtBytes compara contenido, no referencia', () {
        final bytes1 = Uint8List.fromList([1, 2, 3]);
        final bytes2 = Uint8List.fromList([1, 2, 3]);
        final m1 = MetadatosMp3(coverArtBytes: bytes1);
        final m2 = MetadatosMp3(coverArtBytes: bytes2);
        expect(m1, equals(m2));
      });

      test('coverArtBytes de diferente longitud no son iguales', () {
        final m1 = MetadatosMp3(coverArtBytes: Uint8List.fromList([1, 2]));
        final m2 = MetadatosMp3(coverArtBytes: Uint8List.fromList([1, 2, 3]));
        expect(m1, isNot(equals(m2)));
      });
    });

    group('toString', () {
      test('contiene información clave', () {
        const m = MetadatosMp3(
          titulo: 'Mi canción',
          artista: 'Yo',
          anio: 2024,
        );

        final s = m.toString();
        expect(s, contains('titulo: Mi canción'));
        expect(s, contains('artista: Yo'));
        expect(s, contains('anio: 2024'));
      });

      test('muestra coverArtMime cuando está presente', () {
        const m = MetadatosMp3(coverArtMime: 'image/png');
        expect(m.toString(), contains('coverArtMime: image/png'));
      });
    });
  });
}
