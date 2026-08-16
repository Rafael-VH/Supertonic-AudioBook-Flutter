import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

import '../../support/fakes.dart';

/// Destino de prueba para verificar la navegación sin arrastrar otra screen.
class _DestinoPrueba extends StatelessWidget {
  const _DestinoPrueba(this.etiqueta);

  final String etiqueta;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(etiqueta)));
}

/// Harness de la pantalla sola (sin router: la navegación se prueba en
/// [_harnessRouter]).
Widget _harness(
  ModeloGestorFake gestor, {
  PreferenciasMemoria? preferencias,
  AppEstilo estilo = AppEstilo.material,
}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        preferencias ?? PreferenciasMemoria(),
      ),
      modeloManagerProvider.overrideWithValue(gestor),
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
      theme: construirTema(oscuro: false, estilo: estilo),
      home: const DashboardScreen(),
    ),
  );
}

/// Harness con router mínimo: la card Biblioteca navega con `context.push`
/// (DASH-1) y necesita un GoRouter real.
Widget _harnessRouter(ModeloGestorFake gestor) {
  final router = GoRouter(
    initialLocation: Rutas.dashboard,
    routes: [
      GoRoute(
        path: Rutas.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: Rutas.biblioteca,
        builder: (_, __) => const _DestinoPrueba('Destino /biblioteca'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(PreferenciasMemoria()),
      modeloManagerProvider.overrideWithValue(gestor),
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
      theme: construirTema(oscuro: false, estilo: AppEstilo.material),
    ),
  );
}

/// Bombea el harness en una superficie donde el dashboard entra completo
/// (los botones de función no se tocan en estos tests: sin router).
Future<void> _pump(
  WidgetTester tester,
  ModeloGestorFake gestor, {
  PreferenciasMemoria? preferencias,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(gestor, preferencias: preferencias));
}

void main() {
  testWidgets('muestra el estado descargado cuando el modelo está listo', (
    tester,
  ) async {
    await _pump(tester, ModeloGestorFake(disponible: true));
    await tester.pumpAndSettle();

    expect(find.text('Modelos: descargado'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('muestra sin descargar cuando el modelo no está en disco', (
    tester,
  ) async {
    await _pump(tester, ModeloGestorFake());
    await tester.pumpAndSettle();

    expect(find.text('Modelos: sin descargar'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets(
    'el optimismo de preferencia se corrige si el modelo ya no está',
    (tester) async {
      // Preferencia dice "descargado" pero el disco está vacío (el modelo se
      // borró o corrompió): arranca mostrando "descargado" (optimismo) y la
      // verificación de fondo lo corrige a "sin descargar" sin esperar al
      // usuario.
      final gestor = ModeloGestorFake()..verificacionLenta = Completer<void>();
      await _pump(
        tester,
        gestor,
        preferencias: PreferenciasMemoria({'modelo_descargado': true}),
      );
      await tester.pump();

      // Primer frame: muestra "descargado" al instante, sin spinner (el
      // veredicto optimista ya está publicado).
      expect(find.text('Modelos: descargado'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // La verificación de fondo termina: corrige a "sin descargar".
      gestor.verificacionLenta!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Modelos: sin descargar'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    },
  );

  testWidgets(
    'al presionar refrescar re-verifica en disco y muestra el spinner',
    (tester) async {
      final gestor = ModeloGestorFake();
      await _pump(tester, gestor);
      await tester.pumpAndSettle();
      expect(find.text('Modelos: sin descargar'), findsOneWidget);

      // El modelo aparece en disco (p. ej. se restauró manualmente) y el
      // usuario pide re-verificar: la verificación queda bloqueada para poder
      // observar el estado intermedio.
      gestor.disponible = true;
      gestor.verificacionLenta = Completer<void>();
      await tester.tap(find.byTooltip('Refrescar'));
      await tester.pump();

      expect(find.text('Modelos: verificando…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gestor.verificacionLenta!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Modelos: descargado'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    },
  );

  testWidgets('la re-verificación persiste el estado del modelo', (
    tester,
  ) async {
    final gestor = ModeloGestorFake();
    final preferencias = PreferenciasMemoria();
    await _pump(tester, gestor, preferencias: preferencias);
    await tester.pumpAndSettle();
    expect(preferencias.datos['modelo_descargado'], false);

    gestor.disponible = true;
    await tester.tap(find.byTooltip('Refrescar'));
    await tester.pumpAndSettle();

    expect(find.text('Modelos: descargado'), findsOneWidget);
    expect(preferencias.datos['modelo_descargado'], true);
  });

  // ─── WO-4a: hero, cards, grid, biblioteca activa ────────────────────────

  testWidgets(
    'el hero muestra título y subtítulo antes de las cards (DASH-8)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      expect(find.text('¿Qué quieres hacer hoy?'), findsOneWidget);
      expect(find.text('Elegí una función y empezá.'), findsOneWidget);

      final dyTitulo = tester
          .getTopLeft(find.text('¿Qué quieres hacer hoy?'))
          .dy;
      final dySubtitulo = tester
          .getTopLeft(find.text('Elegí una función y empezá.'))
          .dy;
      final dyCard = tester
          .getTopLeft(find.text('Convertir archivos a audio'))
          .dy;
      expect(dyTitulo, lessThan(dySubtitulo));
      expect(dySubtitulo, lessThan(dyCard));
    },
  );

  testWidgets(
    'la card Biblioteca está activa y navega a /biblioteca (DASH-1)',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harnessRouter(ModeloGestorFake()));
      await tester.pumpAndSettle();

      // El placeholder "Próximamente" desaparece; la card usa el icono nuevo.
      expect(find.text('Próximamente'), findsNothing);
      expect(find.byIcon(Icons.library_books_outlined), findsOneWidget);

      await tester.tap(find.text('Biblioteca'));
      await tester.pumpAndSettle();

      expect(find.text('Destino /biblioteca'), findsOneWidget);
    },
  );

  testWidgets('en móvil las cards se apilan en una columna (DASH-9, 400dp)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_harness(ModeloGestorFake()));
    await tester.pumpAndSettle();

    final dyConvertir = tester
        .getTopLeft(find.text('Convertir archivos a audio'))
        .dy;
    final dySueltos = tester
        .getTopLeft(find.text('Procesar archivos sueltos'))
        .dy;
    expect(dySueltos, greaterThan(dyConvertir));
  });

  testWidgets(
    'desde 600dp las cards forman un grid de 2 columnas (DASH-9, 800dp)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      final dyConvertir = tester
          .getTopLeft(find.text('Convertir archivos a audio'))
          .dy;
      final dySueltos = tester
          .getTopLeft(find.text('Procesar archivos sueltos'))
          .dy;
      expect(dyConvertir, dySueltos);
    },
  );

  testWidgets(
    'las cards heredan el cardTheme sin color ni shape propios (DASH-3)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards.length, 3);
      for (final card in cards) {
        expect(
          card.color,
          isNull,
          reason: 'Card no debe fijar color propio (hereda cardTheme)',
        );
        expect(
          card.shape,
          isNull,
          reason: 'Card no debe fijar shape propio (hereda cardTheme)',
        );
        expect(
          card.elevation,
          isNull,
          reason: 'Card no debe fijar elevación propia (hereda cardTheme)',
        );
      }
    },
  );

  testWidgets(
    'el círculo del icono usa el acento primarioClaro (DASH-3, material)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      final circulos = _circulosDeIcono(tester);
      expect(circulos.length, 3);
      final paleta = Paleta.para(oscuro: false, estilo: AppEstilo.material);
      for (final circulo in circulos) {
        expect(circulo.color, paleta.primarioClaro);
      }
    },
  );

  testWidgets(
    'con neumorfismo el acento usa biseles primarioLuz/sombra (DASH-3)',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _harness(ModeloGestorFake(), estilo: AppEstilo.neumo),
      );
      await tester.pumpAndSettle();

      final paleta = Paleta.para(oscuro: false, estilo: AppEstilo.neumo);
      final circulos = _circulosDeIcono(tester);
      expect(circulos.length, 3);
      for (final circulo in circulos) {
        expect(circulo.color, paleta.primarioLuz);
      }
      final icono = tester.widget<Icon>(
        find.byIcon(Icons.auto_awesome_outlined),
      );
      expect(icono.color, paleta.primarioSombra);
    },
  );
}

/// Círculos decorativos de los iconos de las cards de función (accento
/// `PaletaExt` de la card).
List<BoxDecoration> _circulosDeIcono(WidgetTester tester) {
  final contenedores = tester
      .widgetList<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      )
      .toList();
  return contenedores.map((c) => c.decoration! as BoxDecoration).toList();
}
