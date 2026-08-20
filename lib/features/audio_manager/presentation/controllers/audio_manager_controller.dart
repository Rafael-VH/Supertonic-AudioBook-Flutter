import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/audio_manager/domain/entities/audio_pendiente.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Estado de la pantalla AudioManager.
class AudioManagerEstado {
  const AudioManagerEstado({
    this.pendientes = const [],
    this.guardando = false,
    this.snackbar,
    this.error,
  });

  final List<AudioPendiente> pendientes;
  final bool guardando;
  final String? snackbar;
  final String? error;

  bool get vacio => pendientes.isEmpty;

  AudioManagerEstado copyWith({
    List<AudioPendiente>? pendientes,
    bool? guardando,
    String? snackbar,
    bool clearSnackbar = false,
    String? error,
    bool clearError = false,
  }) {
    return AudioManagerEstado(
      pendientes: pendientes ?? this.pendientes,
      guardando: guardando ?? this.guardando,
      snackbar: clearSnackbar ? null : (snackbar ?? this.snackbar),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller para la pantalla de audios pendientes.
///
/// Recibe la lista de audios generados y orquesta guardado/eliminación/renombrado.
class AudioManagerController extends Notifier<AudioManagerEstado> {
  @override
  AudioManagerEstado build() => const AudioManagerEstado();

  void setPendientes(List<AudioPendiente> audios) {
    state = state.copyWith(pendientes: audios);
  }

  Future<void> guardarUno(
    AudioPendiente pendiente, {
    required String carpetaDestino,
    required String nombreArchivo,
  }) async {
    if (state.guardando) return;
    state = state.copyWith(guardando: true, clearError: true);
    try {
      ref.read(guardarAudioProvider).ejecutar(
            tempPath: pendiente.tempPath,
            carpetaDestino: carpetaDestino,
            nombreArchivo: nombreArchivo,
          );
      state = state.copyWith(
        pendientes: [
          for (final p in state.pendientes)
            if (p.tempPath != pendiente.tempPath) p,
        ],
        guardando: false,
        snackbar: 'Audio guardado',
      );
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        error: e.toString(),
      );
    }
  }

  void eliminar(int index) {
    if (index < 0 || index >= state.pendientes.length) return;
    final pendiente = state.pendientes[index];
    ref.read(repositorioArchivosProvider).eliminarSiExiste(pendiente.tempPath);
    final nueva = [...state.pendientes]..removeAt(index);
    state = state.copyWith(pendientes: nueva);
  }

  void actualizarNombre(int index, String nuevoNombre) {
    if (index < 0 || index >= state.pendientes.length) return;
    final antiguo = state.pendientes[index];
    final nueva = [...state.pendientes];
    nueva[index] = antiguo.copyWith(displayName: nuevoNombre);
    state = state.copyWith(pendientes: nueva);
  }

  Future<void> guardarTodos(String carpetaDestino) async {
    if (state.guardando || state.pendientes.isEmpty) return;
    state = state.copyWith(guardando: true, clearError: true);
    try {
      final guardar = ref.read(guardarAudioProvider);
      for (final pendiente in state.pendientes) {
        guardar.ejecutar(
          tempPath: pendiente.tempPath,
          carpetaDestino: carpetaDestino,
          nombreArchivo: '${pendiente.displayName}.${pendiente.format}',
        );
      }
      state = state.copyWith(
        pendientes: const [],
        guardando: false,
        snackbar: 'Audios guardados',
      );
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        error: e.toString(),
      );
    }
  }
}
