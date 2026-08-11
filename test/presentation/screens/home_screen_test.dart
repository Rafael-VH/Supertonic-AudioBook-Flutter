import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';

import '../../support/fakes.dart';

Widget _harness({RepositorioArchivosFake? repositorio}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider
          .overrideWithValue(PreferenciasMemoria()),
      repositorioArchivosProvider.overrideWithValue(
          repositorio ?? RepositorioArchivosFake(const [])),
      motorTtsProvider.overrideWithValue(MotorFake()),
      exportadorAudioProvider.overrideWithValue(ExportadorFake()),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      carpetaBaseProvider.overrideWithValue('C:/base'),
    ],
    child: Consumer(builder: (context, ref, _) {
      final ajustes = ref.watch(settingsControllerProvider);
      return MaterialApp(
        locale: Locale(ajustes.idioma),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: construirTema(oscuro: false, estilo: ajustes.estilo),
        darkTheme: construirTema(oscuro: true, estilo: ajustes.estilo),
        themeMode: ajustes.temaOscuro ? ThemeMode.dark : ThemeMode.light,
        home: const HomeScreen(),
      );
    }),
  );
}

Future<void> _pump(WidgetTester tester,
    {RepositorioArchivosFake? repositorio}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(repositorio: repositorio));
}

void main() {
  testWidgets('Home muestra las secciones y los archivos encontrados',
      (tester) async {
    await _pump(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
        Archivo('C:/libros/capitulo2.md'),
      ]),
    );

    expect(find.text('Carpeta de origen'), findsOneWidget);
    expect(find.text('Salida de audio'), findsOneWidget);
    expect(find.text('Examinar…'), findsNWidgets(2));
    expect(find.text('Archivos Encontrados'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Nada'), findsOneWidget);
    expect(find.text('Refrescar'), findsOneWidget);
    expect(find.text('2 archivos'), findsOneWidget);
    expect(find.text('capitulo1.md'), findsOneWidget);
    expect(find.text('capitulo2.md'), findsOneWidget);
  });

  testWidgets('Home muestra opciones de síntesis y registro',
      (tester) async {
    await _pump(tester);

    expect(find.text('Opciones de síntesis'), findsOneWidget);
    expect(find.text('WAV'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
    expect(find.text('OGG'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
    expect(find.text('Modelo supertonic-3'), findsOneWidget);
    expect(find.text('Pasos'), findsOneWidget);
    expect(find.text('Velocidad'), findsOneWidget);
    expect(find.text('Idioma de la voz'), findsOneWidget);
    expect(find.text('Escuchar'), findsOneWidget);
    expect(find.text('Registro'), findsOneWidget);
    expect(find.textContaining('Procesar'), findsOneWidget);
    expect(find.textContaining('Cancelar'), findsOneWidget);
  });

  testWidgets('marcar un archivo actualiza el conteo seleccionados',
      (tester) async {
    await _pump(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
        Archivo('C:/libros/capitulo2.md'),
        Archivo('C:/libros/capitulo3.md'),
      ]),
    );

    await tester.tap(find.text('capitulo1.md'));
    await tester.pumpAndSettle();

    expect(find.text('1/3 seleccionados'), findsOneWidget);

    await tester.tap(find.text('Todo'));
    await tester.pumpAndSettle();
    expect(find.text('3/3 seleccionados'), findsOneWidget);

    await tester.tap(find.text('Nada'));
    await tester.pumpAndSettle();
    expect(find.text('3 archivos'), findsOneWidget);
  });

  testWidgets('cambiar idioma de interfaz traduce Home', (tester) async {
    await _pump(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    container.read(settingsControllerProvider.notifier).cambiarIdioma('en');
    await tester.pumpAndSettle();

    expect(find.text('Source folder'), findsOneWidget);
    expect(find.text('Browse…'), findsNWidgets(2));
    expect(find.text('Synthesis options'), findsOneWidget);
    expect(find.text('Listen'), findsOneWidget);
    expect(find.textContaining('Process'), findsOneWidget);
  });

  testWidgets('sin archivos muestra el estado vacío', (tester) async {
    await _pump(tester);

    expect(find.text('Sin archivos'), findsNWidgets(2));
    expect(find.text('Listo.'), findsOneWidget);
  });
}
