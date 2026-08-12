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

void main() {
  testWidgets('diag movil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(PreferenciasMemoria()),
          repositorioArchivosProvider.overrideWithValue(
              RepositorioArchivosFake(const [
            Archivo('C:/libros/capitulo1.md'),
            Archivo('C:/libros/capitulo2.md'),
          ])),
          motorTtsProvider.overrideWithValue(MotorFake()),
          exportadorAudioProvider.overrideWithValue(ExportadorFake()),
          reproductorAudioProvider.overrideWithValue(ReproductorFake()),
          carpetaBaseProvider.overrideWithValue('C:/base'),
        ],
        child: Consumer(builder: (context, ref, _) {
          final ajustes = ref.watch(settingsControllerProvider);
          return MaterialApp(
            locale: const Locale('es'),
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
      ),
    );
    await tester.pump();

    // ignore: avoid_print
    print('RENDER TREE DIAG START');
    debugDumpRenderTree();
    // ignore: avoid_print
    print('RENDER TREE DIAG END');
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
