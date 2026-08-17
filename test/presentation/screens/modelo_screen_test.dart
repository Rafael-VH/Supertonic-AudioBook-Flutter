import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/modelo/modelo_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';

import '../../support/fakes.dart';

/// Harness de la pantalla sola (sin gate de la app).
Widget _harness(ModeloGestorFake gestor) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(PreferenciasMemoria()),
      modeloManagerProvider.overrideWithValue(gestor),
      carpetaBaseProvider.overrideWithValue('/tmp/base'),
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
        home: const ModeloScreen(),
      );
    }),
  );
}

/// Harness de la app completa: splash → dashboard → gate decide Home o Modelo.
Widget _harnessApp(ModeloGestorFake gestor) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider
          .overrideWithValue(PreferenciasMemoria({'onboarding_visto': true})),
      repositorioArchivosProvider
          .overrideWithValue(RepositorioArchivosFake(const [])),
      motorTtsProvider.overrideWithValue(MotorFake()),
      exportadorAudioProvider.overrideWithValue(ExportadorFake()),
      reproductorAudioProvider.overrideWithValue(ReproductorFake()),
      carpetaBaseProvider.overrideWithValue('C:/base'),
      modeloManagerProvider.overrideWithValue(gestor),
    ],
    child: const App(),
  );
}

/// Bombea al menos un frame y espera a que aparezca el texto buscado.
Future<void> _hasta(WidgetTester tester, String texto) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (tester.any(find.text(texto))) return;
  }
  fail('No apareció el texto "$texto"');
}

/// Salta el splash (1200 ms). El dashboard ahora muestra ConvertBody (tab 0)
/// directamente, sin necesidad de tocar una card de navegación.
Future<void> _arrancarYProcesar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin modelo muestra aviso y botón de descarga', (tester) async {
    await tester.pumpWidget(_harness(ModeloGestorFake()));

    await _hasta(tester, 'Descargar modelo');
    expect(find.text('Modelo de voz'), findsOneWidget);
    expect(find.text('Descargar modelo'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('descargando muestra progreso, archivo y Cancelar',
      (tester) async {
    final gestor = ModeloGestorFake()..espera = Completer<void>();
    await tester.pumpWidget(_harness(gestor));

    await _hasta(tester, 'Descargar modelo');
    await tester.tap(find.text('Descargar modelo'));
    await _hasta(tester, 'Cancelar');

    expect(find.text('1 MB de 10 MB'), findsOneWidget);
    expect(find.text('onnx/vocoder.onnx'), findsOneWidget);

    gestor.espera!.complete();
    await tester.pumpAndSettle();
    // Al terminar (sin gate) queda pendiente otra vez: botón disponible.
    expect(find.text('Descargar modelo'), findsOneWidget);
  });

  testWidgets('cancelar detiene la descarga y vuelve al botón', (tester) async {
    final gestor = ModeloGestorFake()..espera = Completer<void>();
    await tester.pumpWidget(_harness(gestor));

    await _hasta(tester, 'Descargar modelo');
    await tester.tap(find.text('Descargar modelo'));
    await _hasta(tester, 'Cancelar');

    await tester.tap(find.text('Cancelar'));
    // La cancelación real hace que dio rechace la descarga; acá se simula
    // resolviendo la espera del fake para que el controlador vuelva a pendiente.
    gestor.espera!.complete();
    await _hasta(tester, 'Descargar modelo');
    expect(gestor.cancelaciones, 1);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('si la descarga falla muestra error y permite reintentar',
      (tester) async {
    await tester.pumpWidget(_harness(ModeloGestorFake(fallar: true)));

    await _hasta(tester, 'Descargar modelo');
    await tester.tap(find.text('Descargar modelo'));
    await _hasta(tester, 'Descargar modelo');

    expect(find.textContaining('Error de descarga:'), findsOneWidget);
  });

  group('gate de arranque (SupertonicApp)', () {
    testWidgets('con modelo en disco entra directo a Home', (tester) async {
      await tester.pumpWidget(_harnessApp(ModeloGestorFake(disponible: true)));

      await _arrancarYProcesar(tester);
      await _hasta(tester, 'Carpeta de origen');
      expect(find.text('Descargar modelo'), findsNothing);
    });

    testWidgets('sin modelo muestra el CTA de descarga en el dashboard',
        (tester) async {
      await tester.pumpWidget(_harnessApp(ModeloGestorFake()));

      await _arrancarYProcesar(tester);
      // El CTA del modelo está en SettingsBody (tab 2 del NavigationBar).
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();
      await _hasta(tester, 'Descargar modelo');
      // El dashboard ahora embebe ConvertBody siempre; la card del modelo
      // en SettingsBody muestra el CTA de descarga sin bloquear la pantalla.
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
