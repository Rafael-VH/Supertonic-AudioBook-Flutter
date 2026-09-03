import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/device_spec.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/screens/benchmark_screen.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

import '../../../../support/fakes.dart';

/// Harness con el modelo listo para que el gate no redirija a /modelo.
Widget _harness({
  Map<String, Object>? preferencias,
  Map<String, Object>? benchmark,
  DeviceSpec? deviceSpec,
}) {
  return ProviderScope(
    overrides: [
      deviceSpecProvider.overrideWithValue(deviceSpec),
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
    {Map<String, Object>? preferencias,
    Map<String, Object>? benchmark,
    DeviceSpec? deviceSpec}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(
      preferencias: preferencias, benchmark: benchmark, deviceSpec: deviceSpec));
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

    // The text is at the bottom of a ListView; scroll it into view.
    await tester.scrollUntilVisible(
      find.text('Sin conversiones registradas'),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Sin conversiones registradas'), findsOneWidget);
    expect(find.text('Historial de conversiones'), findsNothing);
  });

  group('_DeviceSpecCard', () {
    testWidgets('se muestra con deviceSpec completo (Android)', (tester) async {
      const device = DeviceSpec(
        brand: 'Google',
        model: 'Pixel 8',
        board: 'cheetah',
        hardware: 'cheetah',
        ramBytes: 8589934592,
      );
      await _pump(tester, deviceSpec: device);

      // brand + model
      expect(find.text('Google Pixel 8'), findsOneWidget);
      // processor row shows board (cheetah)
      expect(find.text('cheetah'), findsOneWidget);
      // RAM shows "8.0 GB"
      expect(find.text('8.0 GB'), findsOneWidget);
      // label text
      expect(find.text('Dispositivo'), findsOneWidget);
      expect(find.text('Procesador'), findsOneWidget);
      expect(find.text('RAM'), findsOneWidget);
    });

    testWidgets('oculta fila procesador cuando board/hardware son null (iOS)',
        (tester) async {
      const device = DeviceSpec(
        brand: 'Apple',
        model: 'iPhone 15',
        ramBytes: 8589934592,
      );
      await _pump(tester, deviceSpec: device);

      expect(find.text('Apple iPhone 15'), findsOneWidget);
      expect(find.text('8.0 GB'), findsOneWidget);
      expect(find.text('Procesador'), findsNothing);
    });

    testWidgets('oculta card cuando deviceSpec es null', (tester) async {
      await _pump(tester, deviceSpec: null);

      expect(find.text('Dispositivo'), findsNothing);
      expect(find.text('Procesador'), findsNothing);
      expect(find.text('RAM'), findsNothing);
    });

    testWidgets('oculta card cuando todos los campos son null (all-null)',
        (tester) async {
      await _pump(tester, deviceSpec: const DeviceSpec());

      expect(find.text('Dispositivo'), findsNothing);
    });

    testWidgets('formatea RAM en MB cuando < 1 GB', (tester) async {
      const device = DeviceSpec(
        brand: 'Test',
        model: 'X1',
        ramBytes: 512 * 1024 * 1024, // 512 MB
      );
      await _pump(tester, deviceSpec: device);

      expect(find.text('Test X1'), findsOneWidget);
      expect(find.text('512 MB'), findsOneWidget);
    });

    testWidgets('oculta fila RAM cuando ramBytes es null', (tester) async {
      const device = DeviceSpec(
        brand: 'Test',
        model: 'X1',
      );
      await _pump(tester, deviceSpec: device);

      expect(find.text('Test X1'), findsOneWidget);
      expect(find.text('RAM'), findsNothing);
    });
  });
}