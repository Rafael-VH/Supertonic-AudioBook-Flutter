import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fdb_helper/fdb_helper.dart';
import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/shared/data/config.dart';
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
  // FdbBinding extiende WidgetsFlutterBinding; inicializarlo cubre ambos.
  // En release no usamos fdb_helper y va el binding estándar.
  if (kReleaseMode) {
    WidgetsFlutterBinding.ensureInitialized();
  } else {
    FdbBinding.ensureInitialized();
  }
  final docs = await getApplicationDocumentsDirectory();
  final soporte = await getApplicationSupportDirectory();
  final separador = Platform.pathSeparator;
  final docsBase = '${docs.path}$separador';
  final modeloDir = '${soporte.path}${separador}modelo';

  runApp(
    ProviderScope(
      overrides: [
        repositorioArchivosProvider.overrideWithValue(
          RepositorioArchivosLocal(),
        ),
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
        modeloManagerProvider.overrideWithValue(ModeloManager()),
        editorMetadataProvider.overrideWithValue(EditorMetadataId3Codec()),
        domainLoggerProvider.overrideWithValue(const PrintLogger()),
      ],
      child: const App(),
    ),
  );
}
