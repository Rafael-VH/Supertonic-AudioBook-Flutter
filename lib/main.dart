import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/shared/data/config.dart';
import 'package:supertonic_audiobook/features/audio_manager/domain/use_cases/limpiar_temporales.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/device_spec.dart';
import 'package:supertonic_audiobook/features/modelo/data/repositories/modelo_manager.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/exportador_audio_ffmpeg.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/file_system_local.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/motor_tts.dart';
import 'package:supertonic_audiobook/shared/data/repositories/repositorio_archivos.dart';
import 'package:supertonic_audiobook/shared/data/repositories/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/shared/data/repositories/reproductor_just_audio.dart';
import 'package:supertonic_audiobook/shared/data/repositories/print_logger.dart';
import 'package:supertonic_audiobook/features/editor_metadata/data/repositories/editor_metadata_id3_codec.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Composition root: único punto que importa `data/`.
///
/// Construye el grafo de dependencias y lo inyecta como overrides en el
/// `ProviderScope`; los widgets y controllers solo ven contratos de `domain/`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final soporte = await getApplicationSupportDirectory();
  final separador = Platform.pathSeparator;
  final docsBase = '${docs.path}$separador';
  final modeloDir = '${soporte.path}${separador}modelo';

  // Clean orphaned WAVs from previous runs before starting.
  final archivos = RepositorioArchivosLocal();
  final tempDir = '${docsBase}audio${separador}_temp';
  LimpiarTemporales(archivos: archivos).ejecutar(carpetaTemp: tempDir);

  // Device hardware, leído una sola vez en el arranque.
  final deviceSpec = await _leerDeviceSpec();

  runApp(
    ProviderScope(
      overrides: [
        deviceSpecProvider.overrideWithValue(deviceSpec),
        repositorioArchivosProvider.overrideWithValue(archivos),
        repositorioPreferenciasProvider.overrideWithValue(
          PreferenciasJsonLocal(ruta: '${docsBase}preferencias.json'),
        ),
        repositorioBenchmarkProvider.overrideWithValue(
          PreferenciasJsonLocal(ruta: '${docsBase}benchmark.json'),
        ),
        repositorioHistorialProvider.overrideWithValue(
          PreferenciasJsonLocal(ruta: '${docsBase}historial_conversiones.json'),
        ),
        exportadorAudioProvider.overrideWithValue(ExportadorAudioFfmpeg()),
        fileSystemProvider.overrideWithValue(FileSystemLocal()),
        reproductorAudioProvider.overrideWithValue(ReproductorJustAudio()),
        motorTtsProvider.overrideWith(
          (ref) => MotorTtsSupertonic(
            onnxDir: '$modeloDir$separador' 'onnx',
            voiceStylesDir: '$modeloDir$separador' 'voice_styles',
          ),
        ),
        configTtsProvider.overrideWithValue((
          silencioMuestras: silenceSamples,
          memoriaSafeMarginBytes: memoriaSafeMarginBytes,
          topeMovilBytes: memoriaSafeMarginBytesMovil,
          // Decisión de plataforma: acá vive (composition root con dart:io),
          // nunca en domain/.
          esMovil: Platform.isAndroid || Platform.isIOS,
        )),
        carpetaBaseProvider.overrideWithValue(docsBase),
        rssProcesoProvider.overrideWithValue(ProcessInfo.currentRss),
        modeloManagerProvider.overrideWithValue(ModeloManager()),
        editorMetadataProvider.overrideWithValue(EditorMetadataId3Codec()),
        domainLoggerProvider.overrideWithValue(const PrintLogger()),
      ],
      child: const App(),
    ),
  );
}

/// Lee la especificación del dispositivo en el arranque.
///
/// Devuelve `null` si falla por completo; cualquier fallo parcial deja el
/// campo correspondiente en `null` sin romper el arranque.
Future<DeviceSpec?> _leerDeviceSpec() async {
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      return DeviceSpec(
        brand: android.brand,
        model: android.model,
        board: android.board,
        hardware: android.hardware,
        ramBytes: await _readAndroidRam(),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final ios = await plugin.iosInfo;
      // ramBytes queda null: no hay API de RAM total en Dart 3.12
      // (ProcessInfo.physicalMemory fue removida).
      return DeviceSpec(
        brand: ios.name,
        model: ios.model,
      );
    }
    return null;
  } catch (_) {
    // Lectura fallida: el deviceSpec queda null y la card se oculta.
    return null;
  }
}

/// Lee la RAM total desde `/proc/meminfo` (Android). Devuelve `null` en error.
Future<int?> _readAndroidRam() async {
  try {
    final content = await File('/proc/meminfo').readAsString();
    final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(content);
    return match != null ? int.parse(match.group(1)!) * 1024 : null;
  } catch (_) {
    return null;
  }
}
