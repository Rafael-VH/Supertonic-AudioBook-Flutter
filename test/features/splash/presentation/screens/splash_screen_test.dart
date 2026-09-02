import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/splash/presentation/screens/splash_screen.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

import '../../../../support/fakes.dart';

Future<void> _pump(WidgetTester tester, PreferenciasMemoria preferencias) async {
  // El splash navega con context.go: necesita un router con los destinos.
  final router = GoRouter(
    initialLocation: Rutas.splash,
    routes: [
      GoRoute(path: Rutas.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: Rutas.dashboard,
        builder: (_, __) => const Scaffold(body: Text('Dashboard stub')),
      ),
      GoRoute(
        path: Rutas.onboarding,
        builder: (_, __) => const Scaffold(body: Text('Onboarding stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioPreferenciasProvider.overrideWithValue(preferencias),
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
      ),
    ),
  );
}

void main() {
  testWidgets('muestra la marca mientras dura el splash', (tester) async {
    await _pump(tester, PreferenciasMemoria());

    expect(find.byIcon(Icons.record_voice_over_outlined), findsOneWidget);
    expect(find.text('Convierte tus libros en Markdown a audiolibros'),
        findsOneWidget);

    // Consume el timer de 1200 ms para que no quede pendiente al terminar.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
  });

  testWidgets('con onboarding visto navega al dashboard', (tester) async {
    await _pump(tester, PreferenciasMemoria({'onboarding_visto': true}));

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard stub'), findsOneWidget);
  });

  testWidgets('sin onboarding navega al onboarding', (tester) async {
    await _pump(tester, PreferenciasMemoria());

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding stub'), findsOneWidget);
  });
}