import 'dart:io';
import 'dart:typed_data';

// Escritura de WAV PCM16 little-endian a nivel de bytes (plan §5.2).
// Núcleo puro en dart:io: 44100 Hz, mono, PCM16 LE. La conversión
// float32→int16 es `clip(audio, -1, 1) * 32767` (redondeo). La duración se
// lee SOLO del header (nunca carga el archivo).

/// Frecuencia de muestreo fija del pipeline (plan §5.1).
const wavSampleRate = 44100;

/// Concatena [fragmentos] y los escribe como un WAV PCM16 completo en [ruta].
void escribirWav(
  List<Float32List> fragmentos,
  String ruta, {
  int sampleRate = wavSampleRate,
}) {
  final pcm = _pcm16De(fragmentos);
  final archivo = File(ruta);
  archivo.parent.createSync(recursive: true);
  final raf = archivo.openSync(mode: FileMode.write);
  try {
    _escribirCabecera(raf, pcm.length, sampleRate: sampleRate);
    raf.writeFromSync(pcm);
  } finally {
    raf.closeSync();
  }
}

/// Agrega [fragmentos] al final de un WAV PCM16 existente.
///
/// Si el archivo no existe o pesa 0 bytes, escribe un WAV completo nuevo.
/// Si no: anexa los samples crudos y parchea el header RIFF (`chunk_size` del
/// RIFF y del chunk `data`) — port de `wav_append`.
void wavAppend(
  List<Float32List> fragmentos,
  String ruta, {
  int sampleRate = wavSampleRate,
}) {
  if (fragmentos.isEmpty) return;

  final archivo = File(ruta);
  archivo.parent.createSync(recursive: true);
  if (!archivo.existsSync() || archivo.lengthSync() == 0) {
    escribirWav(fragmentos, ruta, sampleRate: sampleRate);
    return;
  }

  final pcm = _pcm16De(fragmentos);
  final raf = archivo.openSync(mode: FileMode.append);
  try {
    raf.writeFromSync(pcm);
  } finally {
    raf.closeSync();
  }

  _parchearCabecera(archivo);
}

/// Devuelve la duración de un WAV en segundos leyendo solo el header.
///
/// `0.0` si el archivo no existe, está corrupto o no es WAV (nunca carga el
/// contenido — plan §5.2).
double duracionWav(String ruta) {
  try {
    final archivo = File(ruta);
    final raf = archivo.openSync();
    try {
      raf.setPositionSync(12);
      int? sampleRate;
      int? blockAlign;
      int? dataSize;
      while (true) {
        final cabecera = raf.readSync(8);
        if (cabecera.length < 8) break;
        final id = String.fromCharCodes(cabecera.sublist(0, 4));
        final tamano = ByteData.sublistView(cabecera, 4).getUint32(0, Endian.little);
        if (id == 'fmt ') {
          final fmt = raf.readSync(tamano);
          if (fmt.length < 14) break;
          final bd = ByteData.sublistView(fmt);
          sampleRate = bd.getUint32(4, Endian.little);
          blockAlign = bd.getUint16(12, Endian.little);
        } else if (id == 'data') {
          dataSize = tamano;
          break;
        } else {
          raf.setPositionSync(raf.positionSync() + tamano + (tamano % 2));
        }
      }
      if (sampleRate == null || blockAlign == null || dataSize == null) return 0.0;
      if (sampleRate == 0 || blockAlign == 0) return 0.0;
      final frames = dataSize ~/ blockAlign;
      return frames / sampleRate;
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    return 0.0;
  }
}

/// Convierte float32 (−1..1) a PCM int16 LE (clip * 32767, redondeado).
///
/// Un NaN (silencioso, del motor) se escribe como 0: `NaN.round()` lanzaría
/// y corrompería el archivo. Infinitos se recortan al clip.
Uint8List _pcm16De(List<Float32List> fragmentos) {
  final total = fragmentos.fold<int>(0, (acum, f) => acum + f.length);
  final datos = ByteData(total * 2);
  var offset = 0;
  for (final fragmento in fragmentos) {
    for (final muestra in fragmento) {
      final valor = muestra.isNaN ? 0.0 : muestra;
      final pcm = (valor.clamp(-1.0, 1.0) * 32767.0).round();
      datos.setInt16(offset, pcm, Endian.little);
      offset += 2;
    }
  }
  return datos.buffer.asUint8List();
}

void _escribirCabecera(RandomAccessFile raf, int dataSize, {required int sampleRate}) {
  final byteRate = sampleRate * 2; // mono 16-bit: sampleRate * canales(1) * bytes(2)
  final bd = ByteData(44);
  bd.setUint8(0, 0x52); // R
  bd.setUint8(1, 0x49); // I
  bd.setUint8(2, 0x46); // F
  bd.setUint8(3, 0x46); // F
  bd.setUint32(4, 36 + dataSize, Endian.little);
  bd.setUint8(8, 0x57); // W
  bd.setUint8(9, 0x41); // A
  bd.setUint8(10, 0x56); // V
  bd.setUint8(11, 0x45); // E
  bd.setUint8(12, 0x66); // f
  bd.setUint8(13, 0x6D); // m
  bd.setUint8(14, 0x74); // t
  bd.setUint8(15, 0x20); // ' '
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, byteRate, Endian.little);
  bd.setUint16(32, 2, Endian.little); // blockAlign = canales * bytes por muestra
  bd.setUint16(34, 16, Endian.little); // bits por muestra
  bd.setUint8(36, 0x64); // d
  bd.setUint8(37, 0x61); // a
  bd.setUint8(38, 0x74); // t
  bd.setUint8(39, 0x61); // a
  bd.setUint32(40, dataSize, Endian.little);
  raf.writeFromSync(bd.buffer.asUint8List());
}

/// Reajusta los `chunk_size` del RIFF y del `data` tras anexar bytes.
///
/// Se reabre el archivo y se sobrescriben esos campos con `writeFromSync`
/// posicionado (dart:io no expone un modo "readWrite sin truncar", pero el
/// modo `append` permite writes posicionales; se verifica por tests).
void _parchearCabecera(File archivo) {
  final total = archivo.lengthSync();
  final raf = archivo.openSync(mode: FileMode.append);
  try {
    final riffSize = ByteData(4)..setUint32(0, total - 8, Endian.little);
    raf.setPositionSync(4);
    raf.writeFromSync(riffSize.buffer.asUint8List());

    raf.setPositionSync(12);
    while (true) {
      final cabecera = raf.readSync(8);
      if (cabecera.length < 8) break;
      final id = String.fromCharCodes(cabecera.sublist(0, 4));
      final tamano = ByteData.sublistView(cabecera, 4).getUint32(0, Endian.little);
      if (id == 'data') {
        final posTamano = raf.positionSync() - 4;
        final offsetDatos = raf.positionSync();
        raf.setPositionSync(posTamano);
        final dataSize = ByteData(4)..setUint32(0, total - offsetDatos, Endian.little);
        raf.writeFromSync(dataSize.buffer.asUint8List());
        break;
      }
      final salto = tamano + (tamano % 2);
      raf.setPositionSync(raf.positionSync() + salto);
    }
  } finally {
    raf.closeSync();
  }
}
