import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/domain/contracts/reproductor_audio.dart';
import 'package:supertonic_audiobook/domain/entities/libro_generado.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Estado de la pantalla Biblioteca (BIB-3/BIB-4/BIB-5).
class BibliotecaEstado {
  const BibliotecaEstado({
    this.libros = const [],
    this.error,
    this.reproduciendoRuta,
    this.pausado = false,
  });

  /// Libros listados (agrupados por stem, orden natural, BIB-2).
  final List<LibroGenerado> libros;

  /// Error de la última operación (null si no hubo).
  final String? error;

  /// Ruta del audio que suena (null = idle).
  final String? reproduciendoRuta;

  /// La reproducción en curso está pausada.
  final bool pausado;

  /// Sin libros y sin error: muestra el estado vacío (BIB-4).
  bool get vacio => libros.isEmpty && error == null;

  BibliotecaEstado copyWith({
    List<LibroGenerado>? libros,
    String? error,
    bool clearError = false,
    String? reproduciendoRuta,
    bool clearReproduccion = false,
    bool? pausado,
  }) {
    return BibliotecaEstado(
      libros: libros ?? this.libros,
      error: clearError ? null : (error ?? this.error),
      reproduciendoRuta: clearReproduccion
          ? null
          : (reproduciendoRuta ?? this.reproduciendoRuta),
      pausado: pausado ?? this.pausado,
    );
  }
}

/// Orquesta la pantalla Biblioteca: carga los libros de la carpeta de salida
/// y controla play/pausa/reanudar/detener vía el contrato `ReproductorAudio`
/// (nunca `just_audio`, BIB-6).
class BibliotecaController extends Notifier<BibliotecaEstado> {
  StreamSubscription<EstadoReproduccion>? _subEstado;

  /// Carpeta de salida resuelta en [build]; `recargar()` la reutiliza para
  /// re-ejecutar el listado sin recomponer preferencias.
  String _carpeta = '';

  @override
  BibliotecaEstado build() {
    final prefs = ref.watch(repositorioPreferenciasProvider).cargar();
    final base = ref.watch(carpetaBaseProvider);
    final sep = Platform.pathSeparator;
    _carpeta = prefs['carpeta_out'] as String? ?? '$base${sep}audio';

    // El stream de estado es la fuente de verdad de pausa/fin/error de la
    // reproducción (D2). La suscripción se cancela en dispose (sin leaks).
    final reproductor = ref.watch(reproductorAudioProvider);
    _subEstado = reproductor.estado.listen(_onEstado);
    ref.onDispose(() {
      _subEstado?.cancel();
      // BIB-3 "detener al salir": al abandonar la pantalla el audio no
      // sigue en segundo plano. Fire-and-forget: el dispose no espera.
      reproductor.detener();
    });

    try {
      return BibliotecaEstado(
        libros: ref.read(listarAudiosProvider).ejecutar(carpeta: _carpeta),
      );
    } catch (e) {
      // Defensivo: un fallo del listado no debe crashear la pantalla
      // (paridad con la filosofía de BIB-5, sin estado vacío falso).
      return BibliotecaEstado(libros: const [], error: '$e');
    }
  }

  /// Botón reintentar del estado de error: re-ejecuta el listado y limpia el
  /// error si la carpeta ya responde. Síncrono (D3: el listado del FS es
  /// síncrono); un nuevo fallo vuelve a publicar el error.
  void recargar() {
    try {
      state = state.copyWith(
        libros: ref.read(listarAudiosProvider).ejecutar(carpeta: _carpeta),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  /// Toggle de un tile (BIB-3): pausa o reanuda el tile que suena; cualquier
  /// otra ruta (o idle) reproduce ese libro.
  Future<void> alternarReproduccion(LibroGenerado libro) async {
    final ruta = libro.rutaPrioritaria;
    if (ruta == state.reproduciendoRuta) {
      if (state.pausado) {
        await reanudar();
      } else {
        await pausar();
      }
    } else {
      await reproducir(libro);
    }
  }

  /// Reproduce [libro]; ante un fallo queda en idle con error (BIB-5), sin
  /// crashear.
  Future<void> reproducir(LibroGenerado libro) async {
    final ruta = libro.rutaPrioritaria;
    state = state.copyWith(
      reproduciendoRuta: ruta,
      pausado: false,
      clearError: true,
    );
    try {
      await ref.read(reproductorAudioProvider).reproducir(ruta);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        error: '$e',
        clearReproduccion: true,
        pausado: false,
      );
    }
  }

  Future<void> pausar() async {
    await ref.read(reproductorAudioProvider).pausar();
  }

  Future<void> reanudar() async {
    await ref.read(reproductorAudioProvider).reanudar();
  }

  /// Detiene la reproducción y vuelve al estado idle.
  Future<void> detener() async {
    await ref.read(reproductorAudioProvider).detener();
  }

  /// Reacciona al stream de estado del reproductor (D2): el fin natural del
  /// audio (`detenido`) limpia el tile; pausa/reanudación actualizan la flag.
  void _onEstado(EstadoReproduccion e) {
    switch (e) {
      case EstadoReproduccion.detenido:
        state = state.copyWith(clearReproduccion: true, pausado: false);
      case EstadoReproduccion.reproduciendo:
        state = state.copyWith(pausado: false);
      case EstadoReproduccion.pausado:
        state = state.copyWith(pausado: true);
    }
  }
}

final bibliotecaControllerProvider =
    NotifierProvider<BibliotecaController, BibliotecaEstado>(
      BibliotecaController.new,
    );
