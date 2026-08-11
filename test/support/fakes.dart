import 'dart:typed_data';

import 'package:supertonic_audiobook/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/domain/contracts/reproductor_audio.dart';
import 'package:supertonic_audiobook/domain/entities/archivo.dart';

/// Preferencias en memoria para los tests (sin disco).
class PreferenciasMemoria implements RepositorioPreferencias {
  PreferenciasMemoria([Map<String, Object>? inicial])
      : _datos = {...?inicial};

  final Map<String, Object> _datos;

  @override
  Map<String, Object> cargar() => Map.of(_datos);

  @override
  void guardar(Map<String, Object> preferencias) {
    _datos
      ..clear()
      ..addAll(preferencias);
  }

  Map<String, Object> get datos => Map.unmodifiable(_datos);
}

/// Repositorio de archivos falso con una lista fija de `.md`.
class RepositorioArchivosFake implements RepositorioArchivos {
  RepositorioArchivosFake(this.archivos, {this.carpetasCreadas});

  final List<Archivo> archivos;
  final List<String>? carpetasCreadas;

  int listados = 0;

  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {
    carpetasCreadas?.addAll(carpetas);
  }

  @override
  List<Archivo> listarArchivosMd(String carpeta) {
    listados++;
    return archivos;
  }

  @override
  String leerArchivo(String ruta) => '';
}

/// Motor falso que registra las voces pedidas.
class MotorFake implements MotorTts {
  final List<String> vocesPedidas = [];

  @override
  Future<void> cambiarVoz(String voz) async {
    vocesPedidas.add(voz);
  }

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    return Float32List(4410);
  }
}

/// Exportador falso que registra lo escrito.
class ExportadorFake implements ExportadorAudio {
  final List<String> escritos = [];

  @override
  Future<void> escribirAudio(
      List<Float32List> fragmentos, String ruta, String formato) async {
    escritos.add('$ruta.$formato');
  }

  @override
  Future<void> convertirDesdeWav(
      String rutaWav, String rutaDestino, String formato) async {}

  @override
  Future<double> duracionAudio(String ruta) async => 1.0;

  @override
  Future<void> wavAppend(List<Float32List> fragmentos, String ruta) async {}
}

/// Reproductor falso.
class ReproductorFake implements ReproductorAudio {
  final List<String> rutas = [];

  @override
  Future<void> reproducir(String ruta) async {
    rutas.add(ruta);
  }
}
