import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

import '../../../../support/fakes.dart';

Future<void> _pump(WidgetTester tester, PreferenciasMemoria preferencias) async {
  final router = GoRouter(
    initialLocation: Rutas.onboarding,
    routes: [
      GoRoute(
        path: Rutas.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Rutas.dashboard,
        builder: (_, __) => const Scaffold(body: Text('Dashboard stub')),
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
        theme: construirTema(oscuro: false, estilo: AppEstilo.material),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Avanza los 4 pasos iniciales hasta llegar al paso de carpeta (5.º).
Future<void> _avanzarHastaElFinal(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('muestra el primer paso y avanza hasta el quinto', (tester) async {
    await _pump(tester, PreferenciasMemoria());

    expect(find.text('Cómo generar audio'), findsOneWidget);
    expect(find.text('Descarga el modelo de voz'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    await _avanzarHastaElFinal(tester);

    expect(find.text('Elegí dónde guardar'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Siguiente'), findsNothing);
  });

  testWidgets('Comenzar persiste onboardingVisto y navega al dashboard',
      (tester) async {
    final preferencias = PreferenciasMemoria();
    await _pump(tester, preferencias);
    await _avanzarHastaElFinal(tester);

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard stub'), findsOneWidget);
    expect(preferencias.cargar()['onboarding_visto'], isTrue);
  });

  testWidgets('Omitir finaliza y navega al dashboard', (tester) async {
    final preferencias = PreferenciasMemoria();
    await _pump(tester, preferencias);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard stub'), findsOneWidget);
    expect(preferencias.cargar()['onboarding_visto'], isTrue);
  });
}