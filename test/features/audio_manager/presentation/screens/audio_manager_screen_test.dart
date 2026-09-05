import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/shared/domain/entities/audio_pendiente.dart';
import 'package:supertonic_audiobook/features/audio_manager/presentation/screens/audio_manager_screen.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

import '../../../../support/fakes.dart';

/// FilePicker fake que sí responde getDirectoryPath (el de fakes.dart no).
class _FolderPickerFake extends FilePickerFake {
  _FolderPickerFake(this.carpeta) : super(null);
  final String? carpeta;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    bool lockParentWindow = false,
  }) async =>
      carpeta;
}

AudioPendiente _pendiente(String nombre,
        {double durationSec = 90.0, int fileSizeBytes = 1572864}) =>
    AudioPendiente(
      tempPath: 'C:/tmp/${nombre.toLowerCase()}.wav',
      displayName: nombre,
      format: 'wav',
      durationSec: durationSec,
      fileSizeBytes: fileSizeBytes,
    );

Future<void> _pump(WidgetTester tester, List<AudioPendiente> pendientes,
    {String? carpeta}) async {
  FilePickerPlatform.instance = _FolderPickerFake(carpeta);
  final router = GoRouter(
    initialLocation: Rutas.audioManager,
    routes: [
      GoRoute(
        path: Rutas.audioManager,
        builder: (_, __) => AudioManagerScreen(pendientes: pendientes),
      ),
      GoRoute(
        path: Rutas.home,
        builder: (_, __) => const Scaffold(body: Text('Home stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioArchivosProvider.overrideWithValue(
          RepositorioArchivosFake(const []),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  // El estado se inyecta postFrame: primer frame muestra el empty state.
  await tester.pump();
}

void main() {
  testWidgets('muestra la lista de pendientes', (tester) async {
    await _pump(tester, [
      _pendiente('capitulo1'),
      _pendiente('capitulo2', durationSec: 45.0, fileSizeBytes: 512),
    ]);

    expect(find.text('Audios Generados'), findsOneWidget);
    expect(find.text('capitulo1'), findsOneWidget);
    expect(find.text('capitulo2'), findsOneWidget);
    expect(find.text('WAV · 1 min 30 s · 1.5 MB'), findsOneWidget);
    expect(find.text('WAV · 0 min 45 s · 512 B'), findsOneWidget);
    expect(find.text('Guardar Todos'), findsOneWidget);
  });

  testWidgets('renombrar actualiza el tile', (tester) async {
    await _pump(tester, [_pendiente('capitulo1')]);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renombrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'renombrado');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('renombrado'), findsOneWidget);
    expect(find.text('capitulo1'), findsNothing);
  });

  testWidgets('guardar un audio navega al home', (tester) async {
    await _pump(tester, [_pendiente('capitulo1')], carpeta: 'C:/out');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Guardar'), findsNothing); // el menú no tiene "Guardar"
    await tester.tap(find.text('Elegir carpeta'));
    await tester.pumpAndSettle();

    expect(find.text('Home stub'), findsOneWidget);
  });

  testWidgets('eliminar quita el tile', (tester) async {
    await _pump(tester, [_pendiente('capitulo1')]);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('capitulo1'), findsNothing);
    expect(find.text('No hay audios pendientes'), findsOneWidget);
  });

  testWidgets('sin pendientes muestra el empty state', (tester) async {
    await _pump(tester, const []);

    expect(find.text('No hay audios pendientes'), findsOneWidget);
  });
}