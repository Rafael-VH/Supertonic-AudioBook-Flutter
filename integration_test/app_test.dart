import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/features/convert/data/repositories/file_system_local.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';

import '../test/support/fakes.dart';

/// E2E del flujo completo md → limpieza → síntesis → WAV → export.
///
/// Corre sobre el pipeline REAL de la app (ProcesarArchivo con FileSystemLocal
/// + wav_io puro) con fakes solo para el motor TTS, el exportador (FFmpeg
/// mockeado; el formato wav nunca lo toca) y el modelo (gate de /home).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('convierte un .md a WAV y llega a audios generados',
      (tester) async {
    final carpetaOut = await Directory.systemTemp.createTemp('e2e_audio');

    final archivos = _RepositorioConMd([
      const Archivo('C:/libros/capitulo1.md'),
    ], contenidos: {
      'C:/libros/capitulo1.md':
          '# Capitulo 1\n\nHola mundo. Este es el texto de prueba del E2E.',
    });

    final container = ProviderContainer(overrides: [
      repositorioArchivosProvider.overrideWithValue(archivos),
      repositorioPreferenciasProvider.overrideWithValue(PreferenciasMemoria({
        'onboardingVisto': true,
        'modelo_descargado': true,
        'carpeta_in': 'C:/libros',
        'carpeta_out': carpetaOut.path,
        'formatos': ['wav'],
        'voz': 'M1',
        'steps': 5,
        'speed': 1.0,
        'lang_voz': 'es',
      })),
      repositorioBenchmarkProvider.overrideWithValue(PreferenciasMemoria()),
      repositorioHistorialProvider.overrideWithValue(PreferenciasMemoria()),
      exportadorAudioProvider.overrideWithValue(ExportadorFake()),
      fileSystemProvider.overrideWithValue(FileSystemLocal()),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      motorTtsProvider.overrideWithValue(MotorFake()),
      modeloManagerProvider.overrideWithValue(ModeloGestorFake(
        disponible: true,
      )),
      domainLoggerProvider.overrideWithValue(NoOpLogger()),
    ]);
    addTearDown(container.dispose);
    addTearDown(() => carpetaOut.delete(recursive: true));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );

    // El splash decide en 1.2 s con las prefs sembradas (sin onboarding).
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Ir directo a la conversión; el gate del modelo pasa (modelo listo).
    container.read(appRouterProvider).go(Rutas.home);
    await tester.pumpAndSettle();

    expect(find.text('Procesar'), findsOneWidget);
    await tester.tap(find.text('Procesar'));

    // El pipeline escribe en disco real: poll hasta llegar a /audio-manager.
    await _esperar(
      tester,
      find.text('Audios Generados'),
      total: const Duration(seconds: 10),
    );

    expect(find.text('Audios Generados'), findsOneWidget);
    expect(find.text('capitulo1'), findsOneWidget);
    expect(archivos.leidos, contains('C:/libros/capitulo1.md'));
    expect(
      (container.read(exportadorAudioProvider) as ExportadorFake).escritos,
      isNotEmpty,
    );
  });
}

/// Repositorio fake con contenido Markdown real para el paso de limpieza.
class _RepositorioConMd extends RepositorioArchivosFake {
  _RepositorioConMd(super.archivos, {required Map<String, String> contenidos})
      : _contenidos = contenidos;

  final Map<String, String> _contenidos;
  final List<String> leidos = [];

  @override
  String leerArchivo(String ruta) {
    leidos.add(ruta);
    return _contenidos[ruta] ?? '';
  }
}

/// Hace pump hasta que [finder] aparezca o se agote [total].
Future<void> _esperar(
  WidgetTester tester,
  Finder finder, {
  required Duration total,
}) async {
  final fin = DateTime.now().add(total);
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}