import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/core/widgets/memory_warning_dialog.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Monta un botón que abre el diálogo y entrega el resultado del Future.
Future<void> _abrir(WidgetTester tester, ValueChanged<bool?> onResult) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              onResult(await showMemoryWarningDialog(
                context: context,
                estimatedBytes: 1610612736,
                availableBytes: 536870912,
              ));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la RAM estimada y disponible formateada', (tester) async {
    await _abrir(tester, (_) {});

    expect(find.text('Advertencia de memoria'), findsOneWidget);
    // El contenido es un solo Text con \n; _formatBytes usa 2 decimales en GB.
    expect(find.textContaining('RAM estimada: 1.50 GB'), findsOneWidget);
    expect(find.textContaining('RAM disponible: 512.0 MB'), findsOneWidget);
  });

  testWidgets('procesar de todos modos devuelve true', (tester) async {
    bool? resultado;
    await _abrir(tester, (r) => resultado = r);

    await tester.tap(find.text('Procesar de todos modos'));
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
  });

  testWidgets('cancelar devuelve false', (tester) async {
    bool? resultado;
    await _abrir(tester, (r) => resultado = r);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resultado, isFalse);
  });
}