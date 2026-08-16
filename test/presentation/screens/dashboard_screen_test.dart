import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

import '../../support/fakes.dart';

/// Harness de la pantalla sola (sin router: los botones de función no se
/// tocan en estos tests).
Widget _harness(ModeloGestorFake gestor, {PreferenciasMemoria? preferencias}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider
          .overrideWithValue(preferencias ?? PreferenciasMemoria()),
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
      theme: construirTema(oscuro: false, estilo: AppEstilo.material),
      home: const DashboardScreen(),
    ),
  );
}

/// Bombea el harness en una superficie donde el dashboard entra completo
/// (los botones de función no se tocan en estos tests: sin router).
Future<void> _pump(WidgetTester tester, ModeloGestorFake gestor,
    {PreferenciasMemoria? preferencias}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(gestor, preferencias: preferencias));
}

void main() {
  testWidgets('muestra el estado descargado cuando el modelo está listo',
      (tester) async {
    await _pump(tester, ModeloGestorFake(disponible: true));
    await tester.pumpAndSettle();

    expect(find.text('Modelos: descargado'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('muestra sin descargar cuando el modelo no está en disco',
      (tester) async {
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
  });

  testWidgets('al presionar refrescar re-verifica en disco y muestra el spinner',
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
  });

  testWidgets('la re-verificación persiste el estado del modelo',
      (tester) async {
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
}
