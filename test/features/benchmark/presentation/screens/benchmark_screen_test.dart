import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/screens/benchmark_screen.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

import '../../../../support/fakes.dart';

/// Harness con el modelo listo para que el gate no redirija a /modelo.
Widget _harness({Map<String, Object>? preferencias, Map<String, Object>? benchmark}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        PreferenciasMemoria(preferencias ?? {'modelo_descargado': true}),
      ),
      repositorioBenchmarkProvider.overrideWithValue(
        PreferenciasMemoria(benchmark ?? const {}),
      ),
      repositorioHistorialProvider.overrideWithValue(PreferenciasMemoria()),
      motorTtsProvider.overrideWithValue(MotorFake()),
      domainLoggerProvider.overrideWithValue(NoOpLogger()),
      modeloManagerProvider.overrideWithValue(
        ModeloGestorFake(disponible: true),
      ),
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
      home: const BenchmarkScreen(),
    ),
  );
}

Future<void> _pump(WidgetTester tester,
    {Map<String, Object>? preferencias, Map<String, Object>? benchmark}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      _harness(preferencias: preferencias, benchmark: benchmark));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la tabla con los 6 tamaños fijos', (tester) async {
    await _pump(tester);

    expect(find.text(benchmarkTamanios.first.toString()), findsOneWidget);
    expect(find.text(benchmarkTamanios.last.toString()), findsOneWidget);
    // Headers duplicados: info card + tabla.
    expect(find.text('Tamaño'), findsNWidgets(2));
    expect(find.text('Tiempo'), findsNWidgets(2));
    expect(find.text('Chars/seg'), findsNWidgets(2));
    // Sin resultados: cada fila muestra "—" en tiempo y chars/seg.
    expect(find.text('—'), findsNWidgets(benchmarkTamanios.length * 2));
  });

  testWidgets('ejecutar una fila rellena tiempo y chars/seg', (tester) async {
    await _pump(tester);

    await tester.tap(find.byIcon(Icons.play_arrow).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // MotorFake sintetiza en 0 ms; el controller clampa a 1 ms.
    expect(find.text('0 seg'), findsOneWidget);
    expect(find.text('2500000.0'), findsOneWidget);
    expect(find.text('—'), findsNWidgets((benchmarkTamanios.length - 1) * 2));
  });

  testWidgets('carga resultados persistidos del benchmark', (tester) async {
    await _pump(tester, benchmark: {
      'benchmark_results': {
        'tamanios': {'2500': 2000},
        'voice_config': {'voz': 'M1', 'steps': 5, 'speed': 1.1, 'langVoz': 'es'},
        'fecha': '2026-09-01T00:00:00.000',
      },
    });

    expect(find.text('2 seg'), findsOneWidget);
    expect(find.text('1250.0'), findsOneWidget);
  });

  testWidgets('el historial vacío muestra su estado', (tester) async {
    await _pump(tester);

    expect(find.text('Sin conversiones registradas'), findsOneWidget);
    expect(find.text('Historial de conversiones'), findsNothing);
  });
}