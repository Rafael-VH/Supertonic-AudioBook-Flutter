import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/config.dart';
import 'data/modelo/modelo_manager.dart';
import 'data/repositories/exportador_audio_ffmpeg.dart';
import 'data/repositories/motor_tts.dart';
import 'data/repositories/repositorio_archivos.dart';
import 'data/repositories/repositorio_preferencias.dart';
import 'data/repositories/reproductor_just_audio.dart';
import 'presentation/controllers/providers.dart';

/// Composition root: único punto que importa `data/`.
///
/// Construye el grafo de dependencias y lo inyecta como overrides en el
/// `ProviderScope`; los widgets y controllers solo ven contratos de `domain/`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final separador = Platform.pathSeparator;
  final docsBase = '${docs.path}$separador';
  final modeloDir = '${docsBase}supertonic${separador}modelo';

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
            onnxDir: modeloDir,
            voiceStylesDir: '${modeloDir}voice_styles',
          ),
        ),
        configTtsProvider.overrideWithValue((
          silencioMuestras: silenceSamples,
          memoriaSafeMarginBytes: memoriaSafeMarginBytes,
        )),
        carpetaBaseProvider.overrideWithValue(docsBase),
        modeloManagerProvider.overrideWithValue(ModeloManager()),
      ],
      child: const SupertonicApp(),
    ),
  );
}
