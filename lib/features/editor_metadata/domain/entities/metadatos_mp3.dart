import 'dart:typed_data';

/// Entidad de dominio: metadatos ID3 de un archivo MP3.
///
/// Objeto de valor inmutable que representa los campos editables
/// del editor de metadatos. Todos los campos son opcionales porque
/// un MP3 puede no tener ninguno de ellos seteado.
class MetadatosMp3 {
  const MetadatosMp3({
    this.titulo,
    this.artista,
    this.album,
    this.pista,
    this.disco,
    this.anio,
    this.genero,
    this.comentario,
    this.coverArtBytes,
    this.coverArtMime,
  });

  final String? titulo;
  final String? artista;
  final String? album;
  final int? pista;
  final int? disco;
  final int? anio;
  final String? genero;
  final String? comentario;
  final Uint8List? coverArtBytes;
  final String? coverArtMime;

  MetadatosMp3 copyWith({
    String? titulo,
    bool clearTitulo = false,
    String? artista,
    bool clearArtista = false,
    String? album,
    bool clearAlbum = false,
    int? pista,
    bool clearPista = false,
    int? disco,
    bool clearDisco = false,
    int? anio,
    bool clearAnio = false,
    String? genero,
    bool clearGenero = false,
    String? comentario,
    bool clearComentario = false,
    Uint8List? coverArtBytes,
    bool clearCoverArtBytes = false,
    String? coverArtMime,
    bool clearCoverArtMime = false,
  }) {
    return MetadatosMp3(
      titulo: clearTitulo ? null : (titulo ?? this.titulo),
      artista: clearArtista ? null : (artista ?? this.artista),
      album: clearAlbum ? null : (album ?? this.album),
      pista: clearPista ? null : (pista ?? this.pista),
      disco: clearDisco ? null : (disco ?? this.disco),
      anio: clearAnio ? null : (anio ?? this.anio),
      genero: clearGenero ? null : (genero ?? this.genero),
      comentario: clearComentario ? null : (comentario ?? this.comentario),
      coverArtBytes:
          clearCoverArtBytes ? null : (coverArtBytes ?? this.coverArtBytes),
      coverArtMime:
          clearCoverArtMime ? null : (coverArtMime ?? this.coverArtMime),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetadatosMp3 &&
        other.titulo == titulo &&
        other.artista == artista &&
        other.album == album &&
        other.pista == pista &&
        other.disco == disco &&
        other.anio == anio &&
        other.genero == genero &&
        other.comentario == comentario &&
        _bytesEqual(other.coverArtBytes, coverArtBytes) &&
        other.coverArtMime == coverArtMime;
  }

  @override
  int get hashCode => Object.hash(
        titulo,
        artista,
        album,
        pista,
        disco,
        anio,
        genero,
        comentario,
        coverArtMime,
      );

  @override
  String toString() {
    return 'MetadatosMp3('
        'titulo: $titulo, '
        'artista: $artista, '
        'album: $album, '
        'pista: $pista, '
        'disco: $disco, '
        'anio: $anio, '
        'genero: $genero, '
        'comentario: $comentario, '
        'coverArtMime: $coverArtMime'
        ')';
  }

  static bool _bytesEqual(Uint8List? a, Uint8List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
