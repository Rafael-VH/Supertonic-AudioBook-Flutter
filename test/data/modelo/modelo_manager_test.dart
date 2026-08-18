import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/modelo/data/repositories/modelo_manager.dart';

/// Adaptador HTTP falso: sin `Range` devuelve [respuestaCompleta]; con
/// `Range` (resumen de una descarga previa) devuelve cuerpo vacío, como un
/// servidor que no tuviera más bytes que servir.
class _AdaptadorFalso implements HttpClientAdapter {
  _AdaptadorFalso(this.respuestaCompleta);

  final String respuestaCompleta;
  final List<String?> rangos = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final range = options.headers['range'] as String?;
    rangos.add(range);
    return ResponseBody.fromString(
      range == null ? respuestaCompleta : '',
      200,
    );
  }

  @override
  void close({bool force = false}) {}
}

/// JSON válido de exactamente [n] bytes (ASCII).
String _jsonDe(int n) {
  // '{"comentario":"' (15) + contenido + '"}' (2) = 17 bytes de fijos.
  final contenido = 'a' * (n - 17);
  return '{"comentario":"$contenido"}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const jsonConfig = ArchivoModelo('onnx/tts.json', 8253, null);
  late Directory soporte;

  setUp(() {
    soporte = Directory.systemTemp.createTempSync('modelo_manager_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => soporte.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (soporte.existsSync()) soporte.deleteSync(recursive: true);
  });

  File destinoArchivo(String ruta) =>
      File('${soporte.path}${Platform.pathSeparator}modelo'
          '${Platform.pathSeparator}$ruta');

  test('descarga y verifica un JSON de configuración', () async {
    final json = _jsonDe(8253);
    final adapter = _AdaptadorFalso(json);
    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: const [jsonConfig],
    );

    final raiz = await manager.asegurarModelo();

    expect(raiz, destinoArchivo('onnx/tts.json').parent.parent.path);
    final destino = destinoArchivo('onnx/tts.json');
    expect(destino.existsSync(), isTrue);
    expect(destino.readAsStringSync(), json);
    expect(adapter.rangos, [null]);
  });

  test(
      'un .part del tamaño completo y corrupto se descarta y se baja desde '
      'cero', () async {
    final json = _jsonDe(8253);
    final adapter = _AdaptadorFalso(json);

    // Descarga previa corrupta de tamaño íntegro (p. ej. app cerrada tras una
    // bajada inválida): reanudar con `Range: bytes=8253-` es insatisfacible
    // (el servidor respondería 416) y el fallo se repetiría sin recuperación.
    // El .part debe descartarse y volver a bajarse desde cero.
    final part = destinoArchivo('onnx/tts.json.part');
    await part.parent.create(recursive: true);
    await part.writeAsString('x' * 8253);

    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: const [jsonConfig],
    );

    await manager.asegurarModelo();

    final destino = destinoArchivo('onnx/tts.json');
    expect(destino.existsSync(), isTrue);
    expect(destino.readAsStringSync(), json);
    expect(part.existsSync(), isFalse);
    // Sin Range: el .part íntegro se descartó antes de intentar resumir.
    expect(adapter.rangos, [null]);
  });

  test('un .part parcial corrupto se descarta tras verificar y se reintenta',
      () async {
    final json = _jsonDe(8253);
    final adapter = _AdaptadorFalso(json);

    // Descarga previa truncada (parcial): se reanuda con Range, la
    // verificación descubre el contenido corrupto y se reintenta desde cero.
    final part = destinoArchivo('onnx/tts.json.part');
    await part.parent.create(recursive: true);
    await part.writeAsString('x' * 100);

    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: const [jsonConfig],
    );

    await manager.asegurarModelo();

    final destino = destinoArchivo('onnx/tts.json');
    expect(destino.existsSync(), isTrue);
    expect(destino.readAsStringSync(), json);
    expect(part.existsSync(), isFalse);
    // 1er intento resumiendo (Range) + 2º intento completo desde cero.
    expect(adapter.rangos, ['bytes=100-', null]);
  });

  test('corrupción persistente tras 3 intentos lanza y no publica el destino',
      () async {
    // El servidor devuelve SIEMPRE basura del tamaño correcto: cada intento
    // descarga, la verificación falla y el .part se descarta. Al agotar los
    // reintentos la corrupción debe ser un error visible, no un éxito mudo.
    final adapter = _AdaptadorFalso('x' * 8253);
    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: const [jsonConfig],
    );

    await expectLater(
      manager.asegurarModelo(),
      throwsA(isA<ModeloCorruptoException>()),
    );

    expect(destinoArchivo('onnx/tts.json').existsSync(), isFalse);
    expect(destinoArchivo('onnx/tts.json.part').existsSync(), isFalse);
    // 3 reintentos completos desde cero (sin Range: el .part se descartó).
    expect(adapter.rangos, [null, null, null]);
  });

  test('verifica el SHA-256 de un binario calculándolo en un isolate',
      () async {
    final bytes = utf8.encode('modelo binario de prueba');
    final hash = sha256.convert(bytes).toString();
    final adapter = _AdaptadorFalso('modelo binario de prueba');
    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: [ArchivoModelo('onnx/duration_predictor.onnx', bytes.length, hash)],
    );

    await manager.asegurarModelo();

    final destino = destinoArchivo('onnx/duration_predictor.onnx');
    expect(destino.existsSync(), isTrue);
    expect(await destino.readAsBytes(), bytes);
  });

  test('verificarDisponible refleja el estado real en disco', () async {
    final adapter = _AdaptadorFalso(_jsonDe(8253));
    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: const [jsonConfig],
    );

    expect(await manager.verificarDisponible(), isFalse);

    await manager.asegurarModelo();

    expect(await manager.verificarDisponible(), isTrue);
    expect(adapter.rangos, [null]);
  });

  test('asegurarModelo deja los temporales .part limpios al terminar',
      () async {
    final adapter = _AdaptadorFalso(_jsonDe(8253));
    final manager = ModeloManager(
      dio: Dio()..httpClientAdapter = adapter,
      archivos: const [jsonConfig],
    );

    await manager.asegurarModelo();

    final sobrantes = soporte
        .listSync(recursive: true)
        .where((e) => e.path.endsWith('.part'));
    expect(sobrantes, isEmpty);
  });
}
