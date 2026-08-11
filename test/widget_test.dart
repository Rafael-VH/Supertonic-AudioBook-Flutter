import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Preferencias en memoria para los tests de widget (sin disco).
class _PreferenciasMemoria implements RepositorioPreferencias {
  final Map<String, Object> _datos = {};

  @override
  Map<String, Object> cargar() => Map.of(_datos);

  @override
  void guardar(Map<String, Object> preferencias) {
    _datos..clear()..addAll(preferencias);
  }
}

void main() {
  testWidgets('La app arranca y muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(_PreferenciasMemoria()),
        ],
        child: const SupertonicApp(),
      ),
    );

    expect(find.text('Supertonic-AudioBook'), findsOneWidget);
  });

  testWidgets('el botón de ajustes abre la pantalla de configuración',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(_PreferenciasMemoria()),
        ],
        child: const SupertonicApp(),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
  });
}
