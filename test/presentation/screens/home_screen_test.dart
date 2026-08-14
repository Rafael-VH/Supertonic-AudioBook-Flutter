import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/home_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';

import '../../support/fakes.dart';

Widget _harness({RepositorioArchivosFake? repositorio, MotorFake? motor}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider
          .overrideWithValue(PreferenciasMemoria()),
      repositorioArchivosProvider.overrideWithValue(
          repositorio ?? RepositorioArchivosFake(const [])),
      motorTtsProvider.overrideWithValue(motor ?? MotorFake()),
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
    {RepositorioArchivosFake? repositorio, MotorFake? motor}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(repositorio: repositorio, motor: motor));
}

/// Tamaño de móvil compacto (ancho < umbral) con barra de acción inferior.
Future<void> _pumpMovil(WidgetTester tester,
    {RepositorioArchivosFake? repositorio, MotorFake? motor}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(repositorio: repositorio, motor: motor));
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
    expect(find.byTooltip('Todo'), findsOneWidget);
    expect(find.byTooltip('Nada'), findsOneWidget);
    expect(find.byTooltip('Refrescar'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Todo'));
    await tester.pumpAndSettle();
    expect(find.text('3/3 seleccionados'), findsOneWidget);

    await tester.tap(find.byTooltip('Nada'));
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

  testWidgets('en móvil la acción vive en la barra inferior persistente',
      (tester) async {
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
        Archivo('C:/libros/capitulo2.md'),
      ]),
    );

    expect(find.textContaining('Procesar'), findsOneWidget);
    expect(find.textContaining('Cancelar'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Archivos Encontrados'), findsOneWidget);
  });

  testWidgets('en móvil carpetas y archivos son acordeones expandidos',
      (tester) async {
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
    );

    expect(find.text('Carpetas'), findsOneWidget);
    expect(find.text('Archivos Encontrados'), findsOneWidget);

    await tester.tap(find.text('Carpetas'));
    await tester.pumpAndSettle();
    expect(find.text('Carpeta de origen'), findsNothing);

    await tester.tap(find.text('Carpetas'));
    await tester.pumpAndSettle();
    expect(find.text('Carpeta de origen'), findsOneWidget);

    await tester.tap(find.text('Archivos Encontrados'));
    await tester.pumpAndSettle();
    expect(find.text('capitulo1.md'), findsNothing);

    await tester.tap(find.text('Archivos Encontrados'));
    await tester.pumpAndSettle();
    expect(find.text('capitulo1.md'), findsOneWidget);
  });

  testWidgets('en móvil la barra muestra Cancelar y progreso al ejecutar',
      (tester) async {
    final motor = MotorFake()..esperaVoz = Completer<void>();
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
      motor: motor,
    );

    await tester.tap(find.textContaining('Procesar'));
    await tester.pump();

    expect(find.textContaining('Cancelar'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    motor.esperaVoz!.complete();
    await tester.pumpAndSettle();

    expect(find.textContaining('Cancelar'), findsNothing);
  });
}
