import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/features/biblioteca/presentation/screens/biblioteca_screen.dart';
import 'package:supertonic_audiobook/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:supertonic_audiobook/features/convert/presentation/screens/convert_screen.dart';
import 'package:supertonic_audiobook/features/modelo/presentation/screens/modelo_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

import '../../support/fakes.dart';

/// Ruta actual del router (go_router 17 no expone `location` públicamente y
/// `uri` ignora las rutas imperativas, así que se lee la última match).
String _rutaActual(GoRouter router) =>
    router.routerDelegate.currentConfiguration.matches.last.matchedLocation;

/// Monta la app con el router REAL (`appRouterProvider`) y overrides de fakes.
///
/// La navegación inicial se hace ANTES del pump: si el splash llegara a
/// montar, su `Future.delayed` de 1.2 s quedaría pendiente y el test fallaría
/// por la invariante de timers de flutter_test.
///
/// Con [modeloListo] el gate parte con el modelo disponible (preferencia
/// persistida + verificación de fondo) y el redirect de `/modelo` dispara;
/// con `false` el gate queda abierto y `/modelo` se muestra.
Future<ProviderContainer> _montar(
  WidgetTester tester, {
  required bool modeloListo,
  String? inicio,
  Object? extra,
}) async {
  final container = ProviderContainer(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        modeloListo
            ? PreferenciasMemoria({'modelo_descargado': true})
            : PreferenciasMemoria({'carpeta_out': 'C:/audio'}),
      ),
      repositorioArchivosProvider.overrideWithValue(
        RepositorioArchivosFake(const [], audios: ['C:/audio/libro.mp3']),
      ),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      carpetaBaseProvider.overrideWithValue('C:/base'),
      modeloManagerProvider.overrideWithValue(
        ModeloGestorFake(disponible: modeloListo),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  if (inicio != null) router.go(inicio, extra: extra);
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

void main() {
  testWidgets('la ruta /biblioteca renderiza BibliotecaScreen con contexto', (
    tester,
  ) async {
    await _montar(tester, modeloListo: false, inicio: Rutas.biblioteca);

    expect(find.byType(BibliotecaScreen), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget); // AppBar biblioteca_titulo
    expect(find.text('libro'), findsOneWidget); // tile listado con contexto
    expect(find.text('MP3'), findsOneWidget);
  });

  group('gate del modelo', () {
    testWidgets(
      '/home sin modelo redirige a /modelo (gate intacto)',
      (tester) async {
        final container = await _montar(
          tester,
          modeloListo: false,
          inicio: Rutas.home,
        );
        final router = container.read(appRouterProvider);

        expect(_rutaActual(router), Rutas.modelo);
        expect(find.byType(ModeloScreen), findsOneWidget);
      },
    );

    testWidgets('con modelo no listo el gate deja ver /modelo', (tester) async {
      final container = await _montar(
        tester,
        modeloListo: false,
        inicio: Rutas.modelo,
      );
      final router = container.read(appRouterProvider);

      expect(_rutaActual(router), Rutas.modelo);
      expect(find.byType(ModeloScreen), findsOneWidget);
    });

    testWidgets('sin extra el redirect de /modelo vuelve a /home', (
      tester,
    ) async {
      final container = await _montar(
        tester,
        modeloListo: true,
        inicio: Rutas.modelo,
      );
      final router = container.read(appRouterProvider);

      expect(_rutaActual(router), Rutas.home);
      expect(find.byType(ConvertScreen), findsOneWidget);
    });

    testWidgets('con extra /dashboard el redirect devuelve al dashboard '
        '(DASH-4)', (tester) async {
      final container = await _montar(
        tester,
        modeloListo: true,
        inicio: Rutas.modelo,
        extra: Rutas.dashboard,
      );
      final router = container.read(appRouterProvider);

      expect(_rutaActual(router), Rutas.dashboard);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('con extra desconocido el redirect cae al fallback /home', (
      tester,
    ) async {
      final container = await _montar(
        tester,
        modeloListo: true,
        inicio: Rutas.modelo,
        extra: '/ruta/inexistente',
      );
      final router = container.read(appRouterProvider);

      expect(_rutaActual(router), Rutas.home);
      expect(find.byType(ConvertScreen), findsOneWidget);
    });

    testWidgets(
      'DASH-4: el CTA del settings vuelve al dashboard tras la descarga',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final container = await _montar(
          tester,
          modeloListo: false,
          inicio: Rutas.dashboard,
        );
        final router = container.read(appRouterProvider);

        // Modelo no listo: navegar al tab Settings para ver la Card con CTA.
        await tester.tap(find.text('Configuración'));
        await tester.pumpAndSettle();
        expect(find.text('Descargar modelo'), findsOneWidget);

        // Tap del CTA → /modelo (gate abierto, el modelo todavía no está).
        await tester.tap(find.text('Descargar modelo'));
        await tester.pumpAndSettle();
        expect(_rutaActual(router), Rutas.modelo);
        expect(find.byType(ModeloScreen), findsOneWidget);

        // La descarga se dispara desde ModeloScreen: al completarse el modelo
        // queda listo y el redirect devuelve al origen /dashboard.
        await tester.tap(find.text('Descargar modelo'));
        await tester.pumpAndSettle();

        expect(_rutaActual(router), Rutas.dashboard);
        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );
  });
}
