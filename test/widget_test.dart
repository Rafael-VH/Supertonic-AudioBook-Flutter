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
  final Map<String, Object> _datos = {};

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

void main() {
  testWidgets('La app arranca y muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(_PreferenciasMemoria()),
          repositorioArchivosProvider.overrideWithValue(_ArchivosVacios()),
          carpetaBaseProvider.overrideWithValue('C:/base'),
          modeloManagerProvider
              .overrideWithValue(ModeloGestorFake(disponible: true)),
        ],
        child: const SupertonicApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Supertonic-AudioBook — Conversor de archivos a audio'),
        findsOneWidget);
  });

  testWidgets('el botón de ajustes abre la pantalla de configuración',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(_PreferenciasMemoria()),
          repositorioArchivosProvider.overrideWithValue(_ArchivosVacios()),
          carpetaBaseProvider.overrideWithValue('C:/base'),
          modeloManagerProvider
              .overrideWithValue(ModeloGestorFake(disponible: true)),
        ],
        child: const SupertonicApp(),
      ),
    );

    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
  });
}
