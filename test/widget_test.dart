import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/app.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

import 'support/fakes.dart';

/// Preferencias en memoria para los tests de widget (sin disco).
class _PreferenciasMemoria implements RepositorioPreferencias {
  _PreferenciasMemoria([Map<String, Object>? inicial])
      : _datos = Map.of(inicial ?? {});

  final Map<String, Object> _datos;

  @override
  Map<String, Object> cargar() => Map.of(_datos);

  @override
  void guardar(Map<String, Object> preferencias) {
    _datos..clear()..addAll(preferencias);
  }
}

/// Repositorio de archivos falso (carpeta fija sin .md).
class _ArchivosVacios implements RepositorioArchivos {
  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {}

  @override
  List<Archivo> listarArchivosMd(String carpeta) => const [];

  @override
  String leerArchivo(String ruta) => '';
}

/// Construye la app con dependencias falsas y preferencias opcionales.
Widget _construirApp({Map<String, Object>? preferencias}) {
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider
          .overrideWithValue(_PreferenciasMemoria(preferencias)),
      repositorioArchivosProvider.overrideWithValue(_ArchivosVacios()),
      carpetaBaseProvider.overrideWithValue('C:/base'),
      modeloManagerProvider
          .overrideWithValue(ModeloGestorFake(disponible: true)),
    ],
    child: const App(),
  );
}

/// Salta el splash (1200 ms) y la transición de página.
Future<void> _saltarSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la primera ejecución muestra el onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(_construirApp());

    await _saltarSplash(tester);

    expect(find.text('Cómo generar audio'), findsOneWidget);
    expect(find.text('Descarga el modelo de voz'), findsOneWidget);
  });

  testWidgets('completar el onboarding lleva al dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(_construirApp());

    await _saltarSplash(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('Supertonic'), findsWidgets);
    expect(find.text('Convertir archivos a audio'), findsOneWidget);
  });

  testWidgets('con el onboarding visto arranca directo al dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(_construirApp(preferencias: {
      'onboarding_visto': true,
    }));

    await _saltarSplash(tester);

    expect(find.text('Convertir archivos a audio'), findsOneWidget);
    expect(find.text('¿Qué quieres hacer hoy?'), findsOneWidget);
  });

  testWidgets('el botón de ajustes abre la pantalla de configuración',
      (WidgetTester tester) async {
    await tester.pumpWidget(_construirApp(preferencias: {
      'onboarding_visto': true,
    }));

    await _saltarSplash(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
  });

  testWidgets('Procesar desde el dashboard llega a la pantalla de conversión',
      (WidgetTester tester) async {
    await tester.pumpWidget(_construirApp(preferencias: {
      'onboarding_visto': true,
    }));

    await _saltarSplash(tester);
    await tester.tap(find.text('Convertir archivos a audio'));
    await tester.pumpAndSettle();

    expect(find.text('Supertonic-AudioBook — Conversor de archivos a audio'),
        findsOneWidget);
  });
}
