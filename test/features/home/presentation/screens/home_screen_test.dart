import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/features/convert/presentation/screens/convert_screen.dart';
import 'package:supertonic_audiobook/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:supertonic_audiobook/features/home/presentation/screens/home_screen.dart';
import 'package:supertonic_audiobook/features/convert/domain/entities/selection_mode.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';

import '../../../../support/fakes.dart';

/// Monta la app con el router REAL en `/dashboard` (el hub es el tab 0) y
/// fakes para el grafo, con un [FilePickerFake] como plataforma.
Future<ProviderContainer> _montar(
  WidgetTester tester,
  FilePickerFake picker,
) async {
  FilePickerPlatform.instance = picker;

  final container = ProviderContainer(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        PreferenciasMemoria({'modelo_descargado': true}),
      ),
      repositorioArchivosProvider.overrideWithValue(
        RepositorioArchivosFake(const []),
      ),
      carpetaBaseProvider.overrideWithValue('C:/base'),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      modeloManagerProvider.overrideWithValue(
        ModeloGestorFake(disponible: true),
      ),
      // El dashboard embebe SettingsBody, que lee ambos providers.
      repositorioBenchmarkProvider.overrideWithValue(PreferenciasMemoria()),
      repositorioHistorialProvider.overrideWithValue(PreferenciasMemoria()),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  router.go(Rutas.dashboard);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
        theme: construirTema(oscuro: false, estilo: AppEstilo.material),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Abre la bottom sheet de "Convertir archivos a audio" con pumps acotados.
Future<void> _abrirOpcionesConversion(WidgetTester tester) async {
  await tester.tap(find.text('Convertir archivos a audio'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('HomeScreen (hub)', () {
    testWidgets('muestra las tarjetas de función del hub', (tester) async {
      await _montar(tester, FilePickerFake(null));

      expect(find.text('¿Qué quieres hacer hoy?'), findsOneWidget);
      expect(find.text('Convertir archivos a audio'), findsOneWidget);
      expect(find.text('Editor de metadatos'), findsOneWidget);
      expect(find.text('Editor de voz'), findsOneWidget);
    });

    testWidgets('"Convertir archivos a audio" abre la bottom sheet',
        (tester) async {
      await _montar(tester, FilePickerFake(null));

      await _abrirOpcionesConversion(tester);

      expect(find.text('¿Qué querés convertir?'), findsOneWidget);
      expect(find.text('Seleccionar carpeta'), findsOneWidget);
      expect(find.text('Seleccionar archivos'), findsOneWidget);
    });

    testWidgets('elegir carpeta setea carpetaIn y navega a ConvertScreen',
        (tester) async {
      final container = await _montar(
        tester,
        FilePickerFake(null, carpeta: 'C:/libros'),
      );

      await _abrirOpcionesConversion(tester);

      await tester.tap(find.text('Seleccionar carpeta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));

      // Navegó al hub de conversión (ConvertScreen embebido en /home).
      expect(find.byType(ConvertScreen), findsOneWidget);

      // El controller recibió la carpeta y quedó en modo carpeta.
      final estado = container.read(homeControllerProvider);
      expect(estado.carpetaIn, 'C:/libros');
      expect(estado.modoSeleccion, SelectionMode.carpeta);
    });

    testWidgets('elegir archivos .md setea modo archivos y navega',
        (tester) async {
      final picker = FilePickerFake(
        FilePickerResult([
          PlatformFile(name: 'cap1.md', size: 10, path: 'C:/docs/cap1.md'),
        ]),
      );
      final container = await _montar(tester, picker);

      await _abrirOpcionesConversion(tester);

      await tester.tap(find.text('Seleccionar archivos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ConvertScreen), findsOneWidget);

      final estado = container.read(homeControllerProvider);
      expect(estado.modoSeleccion, SelectionMode.archivos);
      expect(estado.archivos, hasLength(1));
      expect(estado.archivos.first.ruta, 'C:/docs/cap1.md');
      expect(picker.ultimasExtensiones, ['md']);
      expect(picker.ultimoMultiple, isTrue);
    });

    testWidgets('cancelar el picker de carpeta no navega', (tester) async {
      await _montar(tester, FilePickerFake(null, carpeta: null));

      await _abrirOpcionesConversion(tester);

      await tester.tap(find.text('Seleccionar carpeta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));

      // Sigue en el dashboard (hub); no navegó a /home.
      expect(find.byType(ConvertScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
