import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fdb_helper/fdb_helper.dart';
import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/data/config.dart';
import 'package:supertonic_audiobook/data/modelo/modelo_manager.dart';
import 'package:supertonic_audiobook/data/repositories/exportador_audio_ffmpeg.dart';
import 'package:supertonic_audiobook/data/repositories/motor_tts.dart';
import 'package:supertonic_audiobook/data/repositories/repositorio_archivos.dart';
import 'package:supertonic_audiobook/data/repositories/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/data/repositories/reproductor_just_audio.dart';
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
        exportadorAudioProvider.overrideWithValue(ExportadorAudioFfmpeg()),
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
        )),
        carpetaBaseProvider.overrideWithValue(docsBase),
        modeloManagerProvider.overrideWithValue(ModeloManager()),
      ],
      child: const App(),
    ),
  );
}
