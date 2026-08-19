import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/contenido_registro.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/vista_log.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

class _MockController extends Mock implements HomeController {}

HomeEstado _estado({List<String> lineasLog = const [], String estado = ''}) =>
    HomeEstado(
      carpetaIn: '',
      carpetaOut: '',
      archivos: const [],
      seleccion: const {},
      voiceConfig: const VoiceConfig(voz: 'default'),
      formatos: const {'wav'},
      ejecutando: false,
      probandoVoz: false,
      cancelar: false,
      progresoActual: 0,
      progresoTotal: 0,
      estado: estado,
      lineasLog: lineasLog,
      snackbar: null,
    );

Widget _wrap(HomeEstado estado) => MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ContenidoRegistro(
          estado: estado,
          controller: _MockController(),
        ),
      ),
    );

void main() {
  group('ContenidoRegistro', () {
    testWidgets('muestra VistaLog cuando lineasLog no está vacío',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_estado(lineasLog: ['línea 1', 'línea 2'])),
      );

      expect(find.byType(VistaLog), findsOneWidget);
      expect(find.text('línea 1'), findsOneWidget);
      expect(find.text('línea 2'), findsOneWidget);
    });

    testWidgets('no muestra VistaLog cuando lineasLog está vacío',
        (tester) async {
      await tester.pumpWidget(_wrap(_estado()));

      expect(find.byType(VistaLog), findsNothing);
    });

    testWidgets('muestra estado cuando no está vacío', (tester) async {
      await tester.pumpWidget(_wrap(_estado(estado: 'Procesando...')));

      expect(find.text('Procesando...'), findsOneWidget);
    });

    testWidgets('muestra "Listo." cuando estado está vacío', (tester) async {
      await tester.pumpWidget(_wrap(_estado()));

      expect(find.text('Listo.'), findsOneWidget);
    });

    testWidgets('muestra ambas secciones: log y estado', (tester) async {
      await tester.pumpWidget(
        _wrap(_estado(lineasLog: ['log'], estado: 'Trabajando')),
      );

      expect(find.byType(VistaLog), findsOneWidget);
      expect(find.text('log'), findsOneWidget);
      expect(find.text('Trabajando'), findsOneWidget);
    });
  });
}
