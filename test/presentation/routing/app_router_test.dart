import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/screens/biblioteca/biblioteca_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

import '../../support/fakes.dart';

/// Prueba la ruta `/biblioteca` con el router REAL (appRouterProvider):
/// el redirect del modelo no toca esta ruta (el gate se cubre en WO-5).
void main() {
  testWidgets('la ruta /biblioteca renderiza BibliotecaScreen con contexto', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        repositorioPreferenciasProvider.overrideWithValue(
          PreferenciasMemoria({'carpeta_out': 'C:/audio'}),
        ),
        repositorioArchivosProvider.overrideWithValue(
          RepositorioArchivosFake(const [], audios: ['C:/audio/libro.mp3']),
        ),
        reproductorAudioProvider.overrideWithValue(ReproductorFake()),
        carpetaBaseProvider.overrideWithValue('C:/base'),
        modeloManagerProvider.overrideWithValue(ModeloGestorFake()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    router.go(Rutas.biblioteca);

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

    expect(find.byType(BibliotecaScreen), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget); // AppBar biblioteca_titulo
    expect(find.text('libro'), findsOneWidget); // tile listado con contexto
    expect(find.text('MP3'), findsOneWidget);
  });
}
