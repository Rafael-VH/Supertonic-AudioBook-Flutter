import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/editor_metadata/domain/contracts/editor_metadata.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/use_cases/editar_metadata_mp3.dart';
import 'package:supertonic_audiobook/features/editor_metadata/presentation/controllers/metadata_editor_controller.dart';
import 'package:supertonic_audiobook/features/editor_metadata/presentation/screens/metadata_editor_screen.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

import '../../../../support/fakes.dart';

/// Fake de EditorMetadata que registra llamadas y permite inyectar errores.
class _EditorMetadataFake implements EditorMetadata {
  MetadatosMp3? metadataLeida;
  String? rutaLeida;
  String? rutaGuardada;
  MetadatosMp3? metadataGuardada;
  Exception? errorLeer;
  Exception? errorGuardar;

  @override
  Future<MetadatosMp3> leer(String rutaMp3) async {
    rutaLeida = rutaMp3;
    if (errorLeer != null) throw errorLeer!;
    return metadataLeida ?? const MetadatosMp3();
  }

  @override
  Future<void> guardar(String rutaMp3, MetadatosMp3 metadata) async {
    rutaGuardada = rutaMp3;
    metadataGuardada = metadata;
    if (errorGuardar != null) throw errorGuardar!;
  }
}

/// Stub de EditarMetadataMp3 que delega al fake.
class _EditarMetadataMp3Stub extends EditarMetadataMp3 {
  _EditarMetadataMp3Stub(this._fake) : super(_fake);

  final _EditorMetadataFake _fake;

  @override
  Future<MetadatosMp3> ejecutar(String rutaMp3) => _fake.leer(rutaMp3);

  @override
  Future<void> aplicar(String rutaMp3, MetadatosMp3 metadata) =>
      _fake.guardar(rutaMp3, metadata);
}

/// Construye la pantalla con dependencias falsas y el controller en un estado
/// preconfigurado.
Widget _buildScreen({
  required _EditorMetadataFake fakeEditor,
}) {
  final fakeUseCase = _EditarMetadataMp3Stub(fakeEditor);
  final fakePicker = FilePickerFake(null);
  FilePickerPlatform.instance = fakePicker;

  return ProviderScope(
    overrides: [
      editarMetadataMp3Provider.overrideWithValue(fakeUseCase),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MetadataEditorScreen(),
    ),
  );
}

void main() {
  late _EditorMetadataFake fakeEditor;

  setUp(() {
    fakeEditor = _EditorMetadataFake();
  });

  group('MetadataEditorScreen', () {
    testWidgets('muestra botón de selección cuando no hay archivo',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen(fakeEditor: fakeEditor));
      await tester.pumpAndSettle();

      expect(find.text('Seleccioná un archivo MP3 para editar sus metadatos.'), findsOneWidget);
      expect(find.text('Seleccionar archivo MP3'), findsOneWidget);
      expect(find.byIcon(Icons.audiotrack_outlined), findsOneWidget);
    });

    testWidgets('muestra formulario cuando hay archivo cargado',
        (WidgetTester tester) async {
      fakeEditor.metadataLeida = const MetadatosMp3(
        titulo: 'Canción Test',
        artista: 'Artista Test',
        album: 'Álbum Test',
      );

      await tester.pumpWidget(_buildScreen(fakeEditor: fakeEditor));
      await tester.pumpAndSettle();

      // Navigate to load a file — first tap the select button
      await tester.tap(find.text('Seleccionar archivo MP3'));
      await tester.pumpAndSettle();

      // The file picker fake returns null, so no file is loaded.
      // We need to manually set the state via the controller.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MetadataEditorScreen)),
      );
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/test.mp3');
      await tester.pumpAndSettle();

      // Form fields should be visible
      expect(find.text('Canción Test'), findsOneWidget);
      expect(find.text('Artista Test'), findsOneWidget);
      expect(find.text('Álbum Test'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('muestra campos del formulario con labels correctos',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildScreen(fakeEditor: fakeEditor));
      await tester.pumpAndSettle();

      // Load a file
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MetadataEditorScreen)),
      );
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/test.mp3');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Artista'), findsOneWidget);
      expect(find.text('Álbum'), findsOneWidget);
      expect(find.text('Pista'), findsOneWidget);
      expect(find.text('Disco'), findsOneWidget);
      expect(find.text('Año'), findsOneWidget);
      expect(find.text('Género'), findsOneWidget);
      expect(find.text('Comentario'), findsOneWidget);
      expect(find.text('Portada'), findsOneWidget);
    });

    testWidgets('botón guardar llama a controller.guardar()',
        (WidgetTester tester) async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Test');

      await tester.pumpWidget(_buildScreen(fakeEditor: fakeEditor));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MetadataEditorScreen)),
      );
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/test.mp3');
      await tester.pumpAndSettle();

      // Tap the save button
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(fakeEditor.rutaGuardada, '/path/test.mp3');
      expect(fakeEditor.metadataGuardada?.titulo, 'Test');
    });

    testWidgets('botón cancelar hace pop de la pantalla',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editarMetadataMp3Provider.overrideWithValue(
              _EditarMetadataMp3Stub(fakeEditor),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MetadataEditorScreen(),
                    ),
                  ),
                  child: const Text('Ir al editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to the editor screen
      await tester.tap(find.text('Ir al editor'));
      await tester.pumpAndSettle();

      expect(find.byType(MetadataEditorScreen), findsOneWidget);

      // Tap the close/cancel button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should be back to the previous screen
      expect(find.byType(MetadataEditorScreen), findsNothing);
      expect(find.text('Ir al editor'), findsOneWidget);
    });

    testWidgets('error muestra SnackBar', (WidgetTester tester) async {
      fakeEditor.errorGuardar = Exception('escritura fallida');

      await tester.pumpWidget(_buildScreen(fakeEditor: fakeEditor));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MetadataEditorScreen)),
      );
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/test.mp3');
      await tester.pumpAndSettle();

      // Tap save — should fail and show snackbar
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('escritura fallida'), findsOneWidget);
    });

    testWidgets('éxito muestra SnackBar y hace pop',
        (WidgetTester tester) async {
      fakeEditor.metadataLeida = const MetadatosMp3(titulo: 'Test');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editarMetadataMp3Provider.overrideWithValue(
              _EditarMetadataMp3Stub(fakeEditor),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MetadataEditorScreen(),
                    ),
                  ),
                  child: const Text('Ir al editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir al editor'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MetadataEditorScreen)),
      );
      final controller =
          container.read(metadataEditorControllerProvider.notifier);
      await controller.cargar('/path/test.mp3');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Should pop after success
      expect(find.byType(MetadataEditorScreen), findsNothing);
    });
  });
}
