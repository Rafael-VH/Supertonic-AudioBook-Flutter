import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/screens/biblioteca/biblioteca_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

import '../../../support/fakes.dart';

/// Repositorio cuyo listado falla la primera vez y luego responde (para
/// probar el botón reintentar del estado de error).
class _RepositorioFallaUnaVez extends RepositorioArchivosFake {
  _RepositorioFallaUnaVez(List<String> audios)
    : super(const [], audios: audios);

  bool primera = true;

  @override
  List<String> listarAudios(String carpeta) {
    if (primera) {
      primera = false;
      throw StateError('falla al listar audios');
    }
    return super.listarAudios(carpeta);
  }
}

/// Reproductor que falla al reproducir (BIB-5: archivo faltante o corrupto).
class _ReproductorQueFalla extends ReproductorFake {
  @override
  Future<void> reproducir(String ruta) async =>
      throw Exception('archivo faltante: $ruta');
}

/// Destino de prueba para verificar la navegación del estado vacío.
class _DestinoPrueba extends StatelessWidget {
  const _DestinoPrueba(this.etiqueta);

  final String etiqueta;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(etiqueta)));
}

/// Harness de la pantalla bajo un router mínimo (el estado vacío navega con
/// `context.push`). La ruta `/biblioteca` es la inicial y `/home` es un
/// destino de prueba para verificar la navegación sin arrastrar HomeScreen.
Widget _harness({
  RepositorioArchivos? repositorio,
  ReproductorFake? reproductor,
  List<String> audios = const [],
}) {
  final router = GoRouter(
    initialLocation: Rutas.biblioteca,
    routes: [
      GoRoute(
        path: Rutas.biblioteca,
        builder: (_, __) => const BibliotecaScreen(),
      ),
      GoRoute(
        path: Rutas.home,
        builder: (_, __) => const _DestinoPrueba('Destino /home'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      repositorioPreferenciasProvider.overrideWithValue(
        PreferenciasMemoria({'carpeta_out': 'C:/audio'}),
      ),
      repositorioArchivosProvider.overrideWithValue(
        repositorio ?? RepositorioArchivosFake(const [], audios: audios),
      ),
      reproductorAudioProvider.overrideWithValue(
        reproductor ?? ReproductorFake(),
      ),
      carpetaBaseProvider.overrideWithValue('C:/base'),
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
  );
}

Future<void> _pump(
  WidgetTester tester, {
  RepositorioArchivos? repositorio,
  ReproductorFake? reproductor,
  List<String> audios = const [],
}) async {
  await tester.pumpWidget(
    _harness(
      repositorio: repositorio,
      reproductor: reproductor,
      audios: audios,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista los libros agrupados con su formato (BIB-1/BIB-2)', (
    tester,
  ) async {
    await _pump(tester, audios: ['C:/audio/milibro.mp3', 'C:/audio/otro.wav']);

    expect(
      find.text('Biblioteca'),
      findsOneWidget,
    ); // AppBar (biblioteca_titulo)
    expect(find.text('milibro'), findsOneWidget);
    expect(find.text('otro'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('WAV'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('estado vacío con acción que navega a /home (BIB-4)', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.text('Todavía no generaste ningún audiolibro.'),
      findsOneWidget,
    );
    expect(find.text('Ir a convertir'), findsOneWidget);

    await tester.tap(find.text('Ir a convertir'));
    await tester.pumpAndSettle();

    expect(find.text('Destino /home'), findsOneWidget);
  });

  testWidgets('tap en el tile reproduce y el segundo pausa (BIB-3)', (
    tester,
  ) async {
    final reproductor = ReproductorFake();
    await _pump(
      tester,
      reproductor: reproductor,
      audios: ['C:/audio/libro.mp3'],
    );

    // Reposo: icono play en el tile.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byTooltip('Reproducir'), findsOneWidget);

    // Play: el tile suena y muestra pausa.
    await tester.tap(find.text('libro'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byTooltip('Pausar'), findsOneWidget);

    // Pausa: vuelve a play.
    await tester.tap(find.text('libro'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byTooltip('Reproducir'), findsOneWidget);

    expect(reproductor.rutas, ['C:/audio/libro.mp3']); // una sola carga
    expect(reproductor.pausado, isTrue);
  });

  testWidgets('cambio de tile reemplaza la reproducción (BIB-3)', (
    tester,
  ) async {
    final reproductor = ReproductorFake();
    await _pump(
      tester,
      reproductor: reproductor,
      audios: ['C:/audio/a.mp3', 'C:/audio/b.mp3'],
    );

    await tester.tap(find.text('a'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();

    // Solo el tile b suena; a vuelve a mostrar play.
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(reproductor.rutas, ['C:/audio/a.mp3', 'C:/audio/b.mp3']);
  });

  testWidgets('error de reproducción: SnackBar + estado de error con reintentar'
      ' (BIB-5)', (tester) async {
    await _pump(
      tester,
      reproductor: _ReproductorQueFalla(),
      audios: ['C:/audio/borrado.mp3'],
    );

    await tester.tap(find.text('borrado'));
    await tester.pumpAndSettle();

    // SnackBar con el mensaje localizado del error.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining('No se pudo reproducir'),
      ),
      findsOneWidget,
    );

    // El cuerpo pasa al estado de error con el botón reintentar.
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Refrescar'), findsOneWidget);

    // Reintentar re-lista: vuelve la lista (el fake sigue devolviendo el
    // audio; la carpeta real ya no lo listaría si el archivo no existe).
    await tester.tap(find.text('Refrescar'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('borrado'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('error inicial del listado: estado de error y reintentar re-lista'
      ' (BIB-5)', (tester) async {
    await _pump(
      tester,
      repositorio: _RepositorioFallaUnaVez(['C:/audio/libro.mp3']),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Refrescar'), findsOneWidget);

    await tester.tap(find.text('Refrescar'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('libro'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
  });

  testWidgets('tooltips de play/pausa con área táctil >= 48dp (DASH-10)', (
    tester,
  ) async {
    await _pump(tester, audios: ['C:/audio/libro.mp3']);

    final botonPlay = find.widgetWithIcon(IconButton, Icons.play_arrow);
    expect(botonPlay, findsOneWidget);
    expect(find.byTooltip('Reproducir'), findsOneWidget);

    final tamano = tester.getSize(botonPlay);
    expect(tamano.width, greaterThanOrEqualTo(48));
    expect(tamano.height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('libro'));
    await tester.pumpAndSettle();

    final botonPausa = find.widgetWithIcon(IconButton, Icons.pause);
    expect(botonPausa, findsOneWidget);
    expect(find.byTooltip('Pausar'), findsOneWidget);
    expect(tester.getSize(botonPausa).width, greaterThanOrEqualTo(48));
  });
}
