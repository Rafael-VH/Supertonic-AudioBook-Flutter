import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:id3_codec/id3_codec.dart';

import 'package:supertonic_audiobook/features/editor_metadata/data/constants/id3v1_genres.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/contracts/editor_metadata.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';

/// Implementación concreta de [EditorMetadata] usando id3_codec.
///
/// Lee y escribe metadatos ID3 v1/v1.1 y v2.3/v2.4 en archivos MP3.
/// La estrategia de escritura combina v2.3 (título, artista, álbum, portada)
/// con v1 (pista, año, comentario, género) para cubrir todos los campos.
class EditorMetadataId3Codec implements EditorMetadata {
  @override
  Future<MetadatosMp3> leer(String rutaMp3) async {
    final file = File(rutaMp3);
    if (!await file.exists()) {
      throw Exception('Archivo no encontrado: $rutaMp3');
    }

    final bytes = await file.readAsBytes();
    final decoder = ID3Decoder(bytes);
    final metadatas = decoder.decodeSync();

    // Acumular datos de todas las versiones ID3 encontradas.
    // Prioridad: v2 sobre v1 cuando ambos existen.
    String? titulo;
    String? artista;
    String? album;
    int? pista;
    int? disco;
    int? anio;
    String? genero;
    String? comentario;
    Uint8List? coverArtBytes;
    String? coverArtMime;

    // El decoder retorna v1 primero y v2 después. Para dar prioridad
    // a v2 (más campos), iteramos en orden inverso y usamos ??=
    // para que solo el primer valor (v2) se conserve.
    for (var i = metadatas.length - 1; i >= 0; i--) {
      final metadata = metadatas[i];
      final tagMap = metadata.toTagMap();

      // Intentar extraer datos v2 (Frames)
      // Nota: id3_codec retorna Map<dynamic, dynamic> para los mapas anidados.
      // Cada entrada en Frames es un Map plano con keys como
      // 'Frame ID', 'Frame Size', 'Content', etc.
      if (tagMap.containsKey('Frames')) {
        final frames = tagMap['Frames'] as List;
        for (final frameEntry in frames) {
          final frameData = frameEntry as Map;
          final frameId = frameData['Frame ID'] as String?;
          final content = frameData['Content'] as Map?;

          if (content == null) continue;

          switch (frameId) {
            case 'TIT2':
              titulo ??= content['Information'] as String?;
            case 'TPE1':
              artista ??= content['Information'] as String?;
            case 'TALB':
              album ??= content['Information'] as String?;
            case 'TRCK':
              pista ??= _parseTrack(content['Information'] as String?);
            case 'TPOS':
              disco ??= _parseTrack(content['Information'] as String?);
            case 'TYER':
            case 'TDRC':
              anio ??=
                  int.tryParse(content['Information'] as String? ?? '');
            case 'TCON':
              genero ??= content['Information'] as String?;
            case 'COMM':
              comentario ??= content['The actual text'] as String?;
            case 'APIC':
                if (coverArtBytes == null) {
                  final base64Data = content['Base64'] as String?;
                  if (base64Data != null &&
                      base64Data.isNotEmpty &&
                      !base64Data.startsWith('<')) {
                    // Algunos decoders retornan strings placeholder
                    // como '<Has Picture Data>' en vez de base64 real.
                    try {
                      coverArtBytes = Uint8List.fromList(
                        base64.decode(base64Data),
                      );
                      coverArtMime = content['MIME'] as String?;
                    } catch (_) {
                      // Si el base64 es inválido, ignorar la portada
                    }
                  }
                }
          }
        }
      }

      // Intentar extraer datos v1 (campos planos)
      if (tagMap.containsKey('Title')) {
        titulo ??= tagMap['Title'] as String?;
      }
      if (tagMap.containsKey('Artist')) {
        artista ??= tagMap['Artist'] as String?;
      }
      if (tagMap.containsKey('Album')) {
        album ??= tagMap['Album'] as String?;
      }
      if (tagMap.containsKey('Track')) {
        pista ??= tagMap['Track'] as int?;
      }
      if (tagMap.containsKey('Year')) {
        anio ??= int.tryParse(tagMap['Year'] as String? ?? '');
      }
      if (tagMap.containsKey('Genre')) {
        genero ??= tagMap['Genre'] as String?;
      }
      if (tagMap.containsKey('Comment')) {
        comentario ??= tagMap['Comment'] as String?;
      }
    }

    return MetadatosMp3(
      titulo: titulo,
      artista: artista,
      album: album,
      pista: pista,
      disco: disco,
      anio: anio,
      genero: genero,
      comentario: comentario,
      coverArtBytes: coverArtBytes,
      coverArtMime: coverArtMime,
    );
  }

  @override
  Future<void> guardar(String rutaMp3, MetadatosMp3 metadata) async {
    final file = File(rutaMp3);
    if (!await file.exists()) {
      throw Exception('Archivo no encontrado: $rutaMp3');
    }

    // Validar portada antes de escribir
    if (metadata.coverArtBytes != null) {
      _validarCoverArt(metadata.coverArtBytes!);
    }

    // Escritura atómica: escribir a archivo temporal, luego renombrar.
    final tempPath = '$rutaMp3.tmp';
    final tempFile = File(tempPath);

    try {
      // Leer bytes originales para preservar datos de audio
      final originalBytes = await file.readAsBytes();

      // Paso 1: Escribir v2.3 con título, artista, álbum y portada
      List<int> currentBytes = originalBytes;
      final v2Body = MetadataV2p3Body(
        title: metadata.titulo,
        artist: metadata.artista,
        album: metadata.album,
        imageBytes: metadata.coverArtBytes,
      );
      final encoder = ID3Encoder(currentBytes);
      currentBytes = encoder.encodeSync(v2Body);

      // Paso 2: Escribir v1 con pista, año, comentario y género
      final v1Body = MetadataV1Body(
        title: metadata.titulo,
        artist: metadata.artista,
        album: metadata.album,
        year: metadata.anio?.toString(),
        comment: metadata.comentario,
        track: metadata.pista,
        genre: _genreStringToInt(metadata.genero),
      );
      final v1Encoder = ID3Encoder(currentBytes);
      currentBytes = v1Encoder.encodeSync(v1Body);

      // Escribir al temporal y renombrar (atómico)
      await tempFile.writeAsBytes(currentBytes);
      await tempFile.rename(rutaMp3);
    } catch (e) {
      // Limpiar archivo temporal en caso de error
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// Parsea un string de pista que puede ser "3" o "3/12".
  int? _parseTrack(String? value) {
    if (value == null || value.isEmpty) return null;
    final slashIndex = value.indexOf('/');
    final trackStr =
        slashIndex >= 0 ? value.substring(0, slashIndex) : value;
    return int.tryParse(trackStr.trim());
  }

  /// Convierte un nombre de género a su índice numérico v1.
  ///
  /// Realiza una búsqueda case-insensitive en la lista de géneros ID3v1.
  /// Retorna 12 ("Other") si no se encuentra coincidencia.
  int _genreStringToInt(String? genre) {
    if (genre == null || genre.isEmpty) return 12; // Other
    final lower = genre.toLowerCase();
    for (var i = 0; i < kId3v1Genres.length; i++) {
      if (kId3v1Genres[i].toLowerCase() == lower) {
        return i;
      }
    }
    return 12; // Other
  }

  void _validarCoverArt(List<int> bytes) {
    if (bytes.length > 500 * 1024) {
      throw Exception('La portada no puede superar 500KB');
    }
    // Validación básica JPEG (marcador SOI: 0xFF 0xD8)
    if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      throw Exception('La portada debe ser un archivo JPEG válido');
    }
  }
}
