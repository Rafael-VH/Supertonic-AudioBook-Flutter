import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/convert/presentation/widgets/vista_log.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(height: 200, child: child)),
    );

void main() {
  group('VistaLog', () {
    testWidgets('renderiza todas las líneas', (tester) async {
      await tester.pumpWidget(
        _wrap(const VistaLog(lineas: ['a', 'b', 'c'])),
      );

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('muestra la última línea primero (reverse: true)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VistaLog(lineas: ['primera', 'segunda', 'tercera'])),
      );

      // Con reverse: true, index 0 del ListView = última línea del array.
      // El SelectableText de "tercera" debe estar antes que "primera" en el árbol.
      final texts = tester.widgetList<SelectableText>(find.byType(SelectableText));
      final values = texts.map((w) => w.data).toList();
      expect(values, ['tercera', 'segunda', 'primera']);
    });

    testWidgets('lista vacía no muestra nada', (tester) async {
      await tester.pumpWidget(_wrap(const VistaLog(lineas: [])));

      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('cada línea es SelectableText con fuente monospace',
        (tester) async {
      await tester.pumpWidget(_wrap(const VistaLog(lineas: ['x'])));

      final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(selectable.style?.fontFamily, 'monospace');
    });
  });
}
