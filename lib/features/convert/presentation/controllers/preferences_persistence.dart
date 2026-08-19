import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

/// Handles preferences persistence and folder selection for the convert screen.
///
/// This class encapsulates:
/// - Saving/loading preferences
/// - Folder picker integration
/// - Storage permission handling (Android)
class PreferencesPersistence {
  PreferencesPersistence({required this.repositorio});

  final RepositorioPreferencias repositorio;

  /// Check if we have storage access (Android-specific).
  ///
  /// Returns true on non-Android platforms.
  /// On Android, requests MANAGE_EXTERNAL_STORAGE permission.
  Future<bool> tieneAccesoAlmacenamiento() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    final estado = await Permission.manageExternalStorage.request();
    return estado.isGranted;
  }

  /// Pick an input folder using the system folder picker.
  ///
  /// Returns the selected path, or null if cancelled or no permission.
  Future<String?> pickCarpetaIn() async {
    if (!await tieneAccesoAlmacenamiento()) return null;
    return FilePicker.getDirectoryPath();
  }

  /// Pick an output folder using the system folder picker.
  ///
  /// Returns the selected path, or null if cancelled or no permission.
  Future<String?> pickCarpetaOut() async {
    if (!await tieneAccesoAlmacenamiento()) return null;
    return FilePicker.getDirectoryPath();
  }

  /// Save current state to preferences.
  ///
  /// Merges with existing preferences to preserve other settings.
  void guardarPreferencias({
    required VoiceConfig voiceConfig,
    required Set<String> formatos,
    required String carpetaIn,
    required String carpetaOut,
  }) {
    final prefs = {
      ...repositorio.cargar(),
      'voz': voiceConfig.voz,
      'steps': voiceConfig.steps,
      'speed': voiceConfig.speed,
      'lang_voz': voiceConfig.langVoz,
      'formatos': [...formatos]..sort(),
      'carpeta_in': carpetaIn,
      'carpeta_out': carpetaOut,
    };
    repositorio.guardar(prefs);
  }
}
