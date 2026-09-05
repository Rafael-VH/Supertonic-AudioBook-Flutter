import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/convert/data/repositories/file_system_local.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/sintetizar_muestra.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/features/settings/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/features/convert/presentation/screens/convert_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

import '../../support/fakes.dart';

Future<ProviderContainer> _montar(
  WidgetTester tester, {
  RepositorioArchivosFake? repositorio,
  MotorFake? motor,
  ProcesarArchivoStub? procesador,
  int? rssBytes,
}) async {
  final motorEf = motor ?? MotorFake();
  final exportador = ExportadorFake();
  final repo = repositorio ?? RepositorioArchivosFake(const []);
  final procesadorEf = procesador ??
      ProcesarArchivoStub(
        motor: motorEf,
        archivos: repo,
        exportador: exportador,
        fileSystem: FileSystemLocal(),
        silencioMuestras: 0,
        memoriaSafeMarginBytes: 0,
        topeMovilBytes: 0,
        logger: NoOpLogger(),
      );

  final container = ProviderContainer(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        PreferenciasMemoria({'modelo_descargado': true}),
      ),
      repositorioArchivosProvider.overrideWithValue(repo),
      motorTtsProvider.overrideWithValue(motorEf),
      exportadorAudioProvider.overrideWithValue(exportador),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      carpetaBaseProvider.overrideWithValue('C:/base'),
      // procesar al terminar lee el benchmark y persiste el historial.
      repositorioBenchmarkProvider.overrideWithValue(PreferenciasMemoria()),
      repositorioHistorialProvider.overrideWithValue(PreferenciasMemoria()),
      procesarArchivoProvider.overrideWithValue(procesadorEf),
      // escuchar usa sintetizarMuestra + domainLogger; sin override cae al
      // catch y probandoVoz vuelve a false (botón Procesar habilitado).
      domainLoggerProvider.overrideWithValue(NoOpLogger()),
      sintetizarMuestraProvider.overrideWithValue(
        SintetizarMuestra(
          motor: motorEf,
          exportador: exportador,
          logger: NoOpLogger(),
        ),
      ),
      // RSS por defecto alto (no dispara advertencia); rssBytes bajo la fuerza.
      rssProcesoProvider.overrideWithValue(rssBytes ?? (1 << 40)),
      // El gate del modelo y la navegación post-corrida usan el modelo.
      modeloManagerProvider.overrideWithValue(ModeloGestorFake(disponible: true)),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  router.go(Rutas.home);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(builder: (context, ref, _) {
        final ajustes = ref.watch(settingsControllerProvider);
        return MaterialApp.router(
          routerConfig: router,
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
        );
      }),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _pump(WidgetTester tester,
    {RepositorioArchivosFake? repositorio,
    MotorFake? motor,
    ProcesarArchivoStub? procesador,
    int? rssBytes}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await _montar(tester,
      repositorio: repositorio,
      motor: motor,
      procesador: procesador,
      rssBytes: rssBytes);
}

/// Tamaño de móvil compacto (ancho < umbral) con barra de acción inferior.
Future<void> _pumpMovil(WidgetTester tester,
    {RepositorioArchivosFake? repositorio,
    MotorFake? motor,
    ProcesarArchivoStub? procesador,
    int? rssBytes}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await _montar(tester,
      repositorio: repositorio,
      motor: motor,
      procesador: procesador,
      rssBytes: rssBytes);
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
      tester.element(find.byType(ConvertScreen)),
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

  testWidgets('en móvil los acordeones son exclusivos: uno abierto a la vez',
      (tester) async {
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
    );

    // Carpetas abierto por defecto; archivos cerrado.
    expect(find.text('Carpetas'), findsOneWidget);
    expect(find.text('Archivos Encontrados'), findsOneWidget);
    expect(find.text('Carpeta de origen'), findsOneWidget);
    expect(find.text('capitulo1.md'), findsNothing);

    // Abrir archivos cierra carpetas (uno a la vez).
    await tester.tap(find.text('Archivos Encontrados'));
    await tester.pumpAndSettle();
    expect(find.text('capitulo1.md'), findsOneWidget);
    expect(find.text('Carpeta de origen'), findsNothing);

    // Tocar el acordeón ya abierto lo cierra (toggle).
    await tester.tap(find.text('Archivos Encontrados'));
    await tester.pumpAndSettle();
    expect(find.text('capitulo1.md'), findsNothing);
    expect(find.text('Carpeta de origen'), findsNothing);

    // Abrir carpetas de nuevo.
    await tester.tap(find.text('Carpetas'));
    await tester.pumpAndSettle();
    expect(find.text('Carpeta de origen'), findsOneWidget);

    // Tocar opciones cierra carpetas.
    await tester.tap(find.text('Opciones de síntesis'));
    await tester.pumpAndSettle();
    expect(find.text('Voz'), findsOneWidget);
    expect(find.text('Carpeta de origen'), findsNothing);
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

  testWidgets('Procesar queda deshabilitado mientras se prueba la voz',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => 'C:/temp',
    );
    final motor = MotorFake()..esperaVoz = Completer<void>();
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
      motor: motor,
    );

    // Abre el acordeón de opciones y deja la muestra en vuelo: probandoVoz
    // = true mientras cambiarVoz está bloqueado.
    await tester.tap(find.text('Opciones de síntesis'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Escuchar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuchar'));
    await tester.pump();
    expect(find.textContaining('Cancelar'), findsNothing);
    final boton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Procesar'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(boton.enabled, isFalse);

    // Al terminar la muestra, Procesar vuelve a estar disponible.
    motor.esperaVoz!.complete();
    await tester.pumpAndSettle();
    final boton2 = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Procesar'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(boton2.enabled, isTrue);
  });

  testWidgets(
      'memoria: con RSS mínimo la pantalla muestra el diálogo y confirmar ejecuta el lote',
      (tester) async {
    final motorEf = MotorFake();
    final exportador = ExportadorFake();
    final procesador = ProcesarArchivoStub(
      motor: motorEf,
      archivos: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
      exportador: exportador,
      fileSystem: FileSystemLocal(),
      silencioMuestras: 0,
      memoriaSafeMarginBytes: 0,
      topeMovilBytes: 0,
      logger: NoOpLogger(),
    );
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
      procesador: procesador,
      rssBytes: 1,
    );

    await tester.tap(find.textContaining('Procesar'));
    await tester.pumpAndSettle();

    // La vista muestra el diálogo (decisión en la capa de vista).
    expect(find.byType(AlertDialog), findsOneWidget);
    // Todavía no se ejecutó ningún archivo.
    expect(procesador.llamadas, isEmpty);

    // Confirmar reanuda el lote.
    await tester.tap(find.text('Procesar de todos modos'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(procesador.llamadas, hasLength(1));
    expect(find.textContaining('Cancelar'), findsNothing);
  });

  testWidgets('memoria: cancelar la advertencia detiene la corrida',
      (tester) async {
    final motorEf = MotorFake();
    final exportador = ExportadorFake();
    final procesador = ProcesarArchivoStub(
      motor: motorEf,
      archivos: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
      exportador: exportador,
      fileSystem: FileSystemLocal(),
      silencioMuestras: 0,
      memoriaSafeMarginBytes: 0,
      topeMovilBytes: 0,
      logger: NoOpLogger(),
    );
    await _pumpMovil(
      tester,
      repositorio: RepositorioArchivosFake(const [
        Archivo('C:/libros/capitulo1.md'),
      ]),
      procesador: procesador,
      rssBytes: 1,
    );

    await tester.tap(find.textContaining('Procesar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Cancelar'),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(procesador.llamadas, isEmpty);
    // El estado queda sin ejecutar y con el snackbar de cancelación.
    expect(find.textContaining('Exportado'), findsNothing);
  });
}
