import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/domain/contracts/modelo_gestor.dart';
import 'package:supertonic_audiobook/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/domain/contracts/reproductor_audio.dart';
import 'package:supertonic_audiobook/domain/use_cases/procesar_archivo.dart';
import 'package:supertonic_audiobook/domain/use_cases/sintetizar_muestra.dart';

/// Parámetros técnicos del pipeline de síntesis (plan §5.1), inyectados desde
/// la composición (`main.dart`). El caso de uso los recibe en el constructor.
typedef TtsConfig = ({int silencioMuestras, int memoriaSafeMarginBytes});

/// Contratos de `domain/` inyectados desde `main.dart` (composición).
///
/// Estos providers son el único punto de entrada a las implementaciones
/// concretas de `data/`. Si se usan sin inyección, fallan rápido: la app solo
/// se construye con el grafo armado.
final motorTtsProvider = Provider<MotorTts>(
  (_) => throw UnimplementedError('motorTtsProvider se inyecta en main.dart'),
);

final repositorioArchivosProvider = Provider<RepositorioArchivos>(
  (_) => throw UnimplementedError(
      'repositorioArchivosProvider se inyecta en main.dart'),
);

final exportadorAudioProvider = Provider<ExportadorAudio>(
  (_) => throw UnimplementedError(
      'exportadorAudioProvider se inyecta en main.dart'),
);

final repositorioPreferenciasProvider = Provider<RepositorioPreferencias>(
  (_) => throw UnimplementedError(
      'repositorioPreferenciasProvider se inyecta en main.dart'),
);

/// Reproducción de audio del botón **Escuchar**.
final reproductorAudioProvider = Provider<ReproductorAudio>(
  (_) => throw UnimplementedError('reproductorAudioProvider se inyecta en main.dart'),
);

/// Parámetros técnicos del pipeline, decididos en la composición.
final configTtsProvider = Provider<TtsConfig>(
  (_) => throw UnimplementedError('configTtsProvider se inyecta en main.dart'),
);

/// Carpeta base de documentos (raíz de `archivos/` y `audio/`), inyectada
/// desde la composición. `<carpeta_base>/archivos` y `<carpeta_base>/audio`
/// son las carpetas por defecto.
final carpetaBaseProvider = Provider<String>(
  (_) => throw UnimplementedError('carpetaBaseProvider se inyecta en main.dart'),
);

/// Gestión del modelo supertonic-3 (descarga + verificación, plan §5.5),
/// inyectada desde la composición (`data/modelo/modelo_manager.dart`).
final modeloManagerProvider = Provider<ModeloGestor>(
  (_) => throw UnimplementedError(
      'modeloManagerProvider se inyecta en main.dart'),
);

/// Caso de uso de conversión, compuesto con los contratos y la config técnica.
final procesarArchivoProvider = Provider<ProcesarArchivo>((ref) {
  final config = ref.watch(configTtsProvider);
  return ProcesarArchivo(
    motor: ref.watch(motorTtsProvider),
    archivos: ref.watch(repositorioArchivosProvider),
    exportador: ref.watch(exportadorAudioProvider),
    silencioMuestras: config.silencioMuestras,
    memoriaSafeMarginBytes: config.memoriaSafeMarginBytes,
  );
});

/// Caso de uso del botón **Escuchar** (muestra de voz).
final sintetizarMuestraProvider = Provider<SintetizarMuestra>((ref) {
  return SintetizarMuestra(
    motor: ref.watch(motorTtsProvider),
    exportador: ref.watch(exportadorAudioProvider),
  );
});
