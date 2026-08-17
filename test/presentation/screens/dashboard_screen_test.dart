import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard/dashboard_screen.dart';

import '../../support/fakes.dart';

/// Harness de la pantalla sola (sin router). Provee los providers que
/// ConvertBody, BibliotecaBody y SettingsBody necesitan al estar embebidos
/// en el dashboard.
Widget _harness(
  ModeloGestorFake gestor, {
  PreferenciasMemoria? preferencias,
}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        preferencias ?? PreferenciasMemoria(),
      ),
      modeloManagerProvider.overrideWithValue(gestor),
      repositorioArchivosProvider.overrideWithValue(
        RepositorioArchivosFake([]),
      ),
      carpetaBaseProvider.overrideWithValue('/tmp/test'),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
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
      home: const DashboardScreen(),
    ),
  );
}

/// Bombea el harness en una superficie donde el dashboard entra completo.
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

/// Inicia la descarga del modelo desde el test. El CTA del settings solo
/// navega a `/modelo` (la descarga la dispara `ModeloScreen`), así que para
/// probar los estados de la Card se invoca al controller directamente a
/// través del ProviderScope del harness.
void _iniciarDescarga(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DashboardScreen)),
  );
  unawaited(container.read(modeloControllerProvider.notifier).descargar());
}

/// Finder del Card del modelo: el Card que contiene el texto de estado del
/// modelo (aislado de otros Cards que pueda haber en ConvertBody/BibliotecaBody).
Finder get _modeloCard => find.ancestor(
  of: find.textContaining('Modelos:'),
  matching: find.byType(Card),
).first;

void main() {
  // ─── NavigationBar ─────────────────────────────────────────────────────────

  testWidgets(
    'la NavigationBar tiene tres destinations: Inicio, Biblioteca y Configuración',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
    },
  );

  testWidgets(
    'el destino Inicio está seleccionado por defecto',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);
    },
  );

  testWidgets(
    'tocar Biblioteca cambia a índice 1 (BibliotecaBody)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Biblioteca'));
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 1);
    },
  );

  testWidgets(
    'tocar Configuración cambia a índice 2 (SettingsBody)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 2);
    },
  );

  testWidgets(
    'tocar Inicio vuelve a índice 0 (ConvertBody)',
    (tester) async {
      await _pump(tester, ModeloGestorFake());
      await tester.pumpAndSettle();

      // Navegar a Configuración primero.
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      // Volver a Inicio.
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);
    },
  );

  // ─── Card de estado del modelo (movida a SettingsBody) ──────────────────────

  testWidgets('muestra el estado descargado cuando el modelo está listo', (
    tester,
  ) async {
    await _pump(tester, ModeloGestorFake(disponible: true));
    await tester.pumpAndSettle();

    // Navegar a Settings para ver la card.
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(find.text('Modelos: descargado'), findsOneWidget);
    expect(
      find.descendant(
        of: _modeloCard,
        matching: find.byIcon(Icons.refresh),
      ),
      findsOneWidget,
    );
  });

  testWidgets('muestra sin descargar cuando el modelo no está en disco', (
    tester,
  ) async {
    await _pump(tester, ModeloGestorFake());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(find.text('Modelos: sin descargar'), findsOneWidget);
    expect(
      find.descendant(
        of: _modeloCard,
        matching: find.byIcon(Icons.refresh),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'el optimismo de preferencia se corrige si el modelo ya no está',
    (tester) async {
      final gestor = ModeloGestorFake()..verificacionLenta = Completer<void>();
      await _pump(
        tester,
        gestor,
        preferencias: PreferenciasMemoria({'modelo_descargado': true}),
      );
      await tester.pump();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      expect(find.text('Modelos: descargado'), findsOneWidget);
      expect(
        find.descendant(
          of: _modeloCard,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );

      gestor.verificacionLenta!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Modelos: sin descargar'), findsOneWidget);
      expect(
        find.descendant(
          of: _modeloCard,
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'al presionar refrescar re-verifica en disco y muestra el spinner',
    (tester) async {
      final gestor = ModeloGestorFake();
      await _pump(tester, gestor);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      expect(find.text('Modelos: sin descargar'), findsOneWidget);

      gestor.disponible = true;
      gestor.verificacionLenta = Completer<void>();

      // Tocar el refresh SOLO dentro de la Card del modelo.
      await tester.tap(
        find.descendant(
          of: _modeloCard,
          matching: find.byTooltip('Refrescar'),
        ),
      );
      await tester.pump();

      expect(find.text('Modelos: verificando…'), findsOneWidget);
      expect(
        find.descendant(
          of: _modeloCard,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      gestor.verificacionLenta!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Modelos: descargado'), findsOneWidget);
      expect(
        find.descendant(
          of: _modeloCard,
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('la re-verificación persiste el estado del modelo', (
    tester,
  ) async {
    final gestor = ModeloGestorFake();
    final preferencias = PreferenciasMemoria();
    await _pump(tester, gestor, preferencias: preferencias);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(preferencias.datos['modelo_descargado'], false);

    gestor.disponible = true;
    await tester.tap(
      find.descendant(
        of: _modeloCard,
        matching: find.byTooltip('Refrescar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modelos: descargado'), findsOneWidget);
    expect(preferencias.datos['modelo_descargado'], true);
  });

  testWidgets(
    'durante la descarga muestra progreso veraz y sin CTA (DASH-5/DASH-6)',
    (tester) async {
      final gestor = ModeloGestorFake()..espera = Completer<void>();
      await _pump(tester, gestor);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      // Estado idle: el CTA de descarga está disponible en la card.
      expect(find.text('Descargar modelo'), findsOneWidget);

      _iniciarDescarga(tester);
      await tester.pump();

      // Progreso real dentro de la Card del modelo y sin CTA.
      expect(
        find.descendant(
          of: _modeloCard,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text('1 MB de 10 MB'), findsOneWidget);
      expect(find.text('Modelos: descargando…'), findsOneWidget);
      expect(find.text('Modelos: sin descargar'), findsNothing);
      expect(find.text('Descargar modelo'), findsNothing);

      // Al completar la descarga, la Card pasa a "descargado".
      gestor.espera!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Modelos: descargado'), findsOneWidget);
      expect(
        find.descendant(
          of: _modeloCard,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'tras un error de descarga muestra el mensaje y el CTA vuelve (DASH-5)',
    (tester) async {
      final gestor = ModeloGestorFake(fallar: true);
      await _pump(tester, gestor);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      _iniciarDescarga(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Error de descarga: Exception: fallo simulado'),
        findsOneWidget,
      );
      expect(find.text('Descargar modelo'), findsOneWidget);
      expect(find.text('Modelos: sin descargar'), findsNothing);
      // Al haber error, la card muestra el mensaje de error en vez del
      // prefijo "Modelos:", así que el finder se adapta al texto real.
      final cardError = find.ancestor(
        of: find.text('Error de descarga: Exception: fallo simulado'),
        matching: find.byType(Card),
      ).first;
      expect(
        find.descendant(
          of: cardError,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('el refresh de la Card mide al menos 48×48 (DASH-6/DASH-10)', (
    tester,
  ) async {
    await _pump(tester, ModeloGestorFake());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    final tam = tester.getSize(
      find.descendant(
        of: _modeloCard,
        matching: find.byTooltip('Refrescar'),
      ),
    );
    expect(tam.width, greaterThanOrEqualTo(48));
    expect(tam.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
    'los ticks del modelo no reconstruyen ConvertBody ni BibliotecaBody (DASH-7)',
    (tester) async {
      final gestor = ModeloGestorFake()..espera = Completer<void>();
      await _pump(tester, gestor);
      await tester.pumpAndSettle();

      // Referencia al DashboardScreen ANTES de la descarga.
      final elementoDashboard = tester.element(
        find.byType(DashboardScreen),
      );
      final widgetDashboardAntes = elementoDashboard.widget;

      _iniciarDescarga(tester);
      await tester.pump();

      // Navegar a Settings para ver el progreso.
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      // El tick SÍ llegó (el progreso se renderiza).
      expect(find.text('1 MB de 10 MB'), findsOneWidget);

      // Pero el DashboardScreen (StatefulWidget) no se reconstruyó.
      expect(
        identical(elementoDashboard.widget, widgetDashboardAntes),
        isTrue,
        reason: 'el DashboardScreen no debe reconstruirse en cada tick del modelo',
      );

      gestor.espera!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Modelos: descargado'), findsOneWidget);
      expect(identical(elementoDashboard.widget, widgetDashboardAntes), isTrue);
    },
  );
}
