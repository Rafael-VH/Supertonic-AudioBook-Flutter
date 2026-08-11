import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/app.dart';

void main() {
  testWidgets('La app arranca y muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SupertonicApp()));

    expect(find.text('Supertonic-AudioBook'), findsOneWidget);
  });
}
