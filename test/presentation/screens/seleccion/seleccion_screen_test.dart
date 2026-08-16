import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/seleccion/seleccion_screen.dart';

import '../../../support/fakes.dart';

void main() {
  late FilePickerFake picker;

  AppLocalizations es() => lookupAppLocalizations(const Locale('es'));

  ProviderScope construirApp({
    required ModeloGestorFake modelo,
    List<String>? rutas,
  }) {
    final preferencias = PreferenciasMemoria();
    final repositorio = RepositorioArchivosFake(const []);
    final motor = MotorFake();
    final exportador = ExportadorFake();
    final reproductor = ReproductorFake();
    final procesador = ProcesarArchivoStub(
      motor: motor,
      archivos: repositorio,
      exportador: exportador,
      silencioMuestras: 0,
      memoriaSafeMarginBytes: 0,
      topeMovilBytes: 0,
    );
    picker = FilePickerFake(
      rutas == null
          ? null
          : FilePickerResult([
              for (final r in rutas) PlatformFile(path: r, name: r.split('/').last, size: 10),
            ]),
    );
    FilePickerPlatform.instance = picker;

    return ProviderScope(
      overrides: [
        repositorioPreferenciasProvider.overrideWithValue(preferencias),
        repositorioArchivosProvider.overrideWithValue(repositorio),
        motorTtsProvider.overrideWithValue(motor),
        exportadorAudioProvider.overrideWithValue(exportador),
        reproductorAudioProvider.overrideWithValue(reproductor),
        procesarArchivoProvider.overrideWithValue(procesador),
        carpetaBaseProvider.overrideWithValue('C:/base'),
        modeloManagerProvider.overrideWithValue(modelo),
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
        home: const SeleccionScreen(),
      ),
    );
  }

  setUp(() {
    FilePickerPlatform.instance = FilePickerFake(null);
  });

  testWidgets('abre el buscador con .md, múltiple y muestra los elegidos',
      (tester) async {
    await tester.pumpWidget(construirApp(
      modelo: ModeloGestorFake(disponible: true),
      rutas: ['C:/sueltos/a.md', 'C:/sueltos/b.md'],
    ));
    await tester.pumpAndSettle();

    expect(picker.llamadas, 1);
    expect(picker.ultimoTipo, FileType.custom);
    expect(picker.ultimasExtensiones, ['md']);
    expect(picker.ultimoMultiple, isTrue);
    expect(find.text('a.md'), findsOneWidget);
    expect(find.text('b.md'), findsOneWidget);
    expect(find.text(es().seleccion_agregar), findsOneWidget);
  });

  testWidgets('sin resultados muestra el estado vacío con botón de elegir',
      (tester) async {
    await tester.pumpWidget(construirApp(modelo: ModeloGestorFake()));
    await tester.pumpAndSettle();

    expect(find.text(es().seleccion_sin_archivos), findsOneWidget);
    expect(find.text(es().seleccion_elegir), findsOneWidget);
  });

  testWidgets('quitar elimina un archivo de la lista', (tester) async {
    await tester.pumpWidget(construirApp(
      modelo: ModeloGestorFake(disponible: true),
      rutas: ['C:/sueltos/a.md', 'C:/sueltos/b.md'],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('a.md'), findsNothing);
    expect(find.text('b.md'), findsOneWidget);
  });

  testWidgets('sin modelo muestra el aviso de descarga al procesar',
      (tester) async {
    await tester.pumpWidget(construirApp(
      modelo: ModeloGestorFake(disponible: false),
      rutas: ['C:/sueltos/a.md'],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(es().btn_procesar));
    await tester.pumpAndSettle();

    expect(find.text(es().seleccion_modelo_aviso), findsOneWidget);
    expect(find.text(es().seleccion_ir_modelo), findsOneWidget);
  });

  testWidgets('con modelo listo procesa sin mostrar el aviso', (tester) async {
    await tester.pumpWidget(construirApp(
      modelo: ModeloGestorFake(disponible: true),
      rutas: ['C:/sueltos/a.md'],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(es().btn_procesar));
    await tester.pumpAndSettle();

    expect(find.text(es().seleccion_modelo_aviso), findsNothing);
    expect(
      find.text(es().snackbar_procesado(1, es().tiempo_seg(0))),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text(es().estado_listo_n(1, es().tiempo_seg(0))), findsOneWidget);
  });
}
