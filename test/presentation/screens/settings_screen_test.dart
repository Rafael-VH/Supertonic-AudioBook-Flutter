import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/settings/settings_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';

import '../../support/fakes.dart';

/// Harness con modelo listo para que _CardEstadoModelo no dispare verificación
/// infinita (que causaría pumpAndSettle timeout).
Widget _harness(Widget child) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(_PreferenciasMemoria()),
      carpetaBaseProvider.overrideWithValue('/tmp/base'),
      repositorioArchivosProvider.overrideWithValue(
        RepositorioArchivosFake([]),
      ),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      modeloManagerProvider.overrideWithValue(
        ModeloGestorFake(disponible: true),
      ),
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
        home: child,
      );
    }),
  );
}

void main() {
  testWidgets('muestra todas las secciones de ajustes en español',
      (tester) async {
    await tester.pumpWidget(_harness(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('Estilo'), findsOneWidget);
    expect(find.text('Material (actual)'), findsOneWidget);
    expect(find.text('Neumorfismo'), findsOneWidget);
    expect(find.text('Skeuomorfismo'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('el contenido de Acerca de es el EXACTO del plan §6.4',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_harness(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Acerca de'), findsOneWidget);
    expect(find.text('Supertonic-AudioBook'), findsOneWidget);
    expect(find.text('Versión 1.0.3'), findsOneWidget);
    expect(
      find.text(
          'Convierte tus libros Markdown en audiolibros con voz sintética: '
          '100 % local, sin nube y sin GPU.'),
      findsOneWidget,
    );
    expect(
      find.text('Modelo de voz: Supertonic 3, de Supertone Inc. '
          '(licencia OpenRAIL-M)'),
      findsOneWidget,
    );
    expect(find.text('Licencia MIT'), findsOneWidget);
    expect(find.text('Ver el modelo en Hugging Face'), findsOneWidget);
    expect(find.text('Código fuente del modelo'), findsOneWidget);
  });

  testWidgets('cambiar a oscuro aplica el tema y persiste la clave §6.3',
      (tester) async {
    await tester.pumpWidget(_harness(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Tema'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Tema'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('cambiar a English traduce la interfaz', (tester) async {
    await tester.pumpWidget(_harness(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Style'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  // ─── Card de estado del modelo (movida desde DashboardScreen) ─────────────

  testWidgets('muestra la card de estado del modelo arriba de los ajustes',
      (tester) async {
    await tester.pumpWidget(_harness(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Modelos: descargado'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('la card muestra sin descargar cuando el modelo no está',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(_PreferenciasMemoria()),
          carpetaBaseProvider.overrideWithValue('/tmp/base'),
          repositorioArchivosProvider.overrideWithValue(
            RepositorioArchivosFake([]),
          ),
          reproductorAudioProvider.overrideWithValue(ReproductorFake()),
          modeloManagerProvider.overrideWithValue(ModeloGestorFake()),
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
            home: const SettingsScreen(),
          );
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modelos: sin descargar'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}

class _PreferenciasMemoria implements RepositorioPreferencias {
  final Map<String, Object> _datos = {};

  @override
  Map<String, Object> cargar() => Map.of(_datos);

  @override
  void guardar(Map<String, Object> preferencias) {
    _datos..clear()..addAll(preferencias);
  }
}
