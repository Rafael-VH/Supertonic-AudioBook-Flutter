import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/shared/data/repositories/print_logger.dart';

/// Captura las líneas que el código imprime con `print` en la zona actual.
List<String> _capturarImpresiones(void Function() cuerpo) {
  final lineas = <String>[];
  runZoned(
    cuerpo,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lineas.add(line),
    ),
  );
  return lineas;
}

void main() {
  test('PrintLogger con habilitado: false no imprime nada', () {
    final lineas = _capturarImpresiones(() {
      const logger = PrintLogger(habilitado: false);
      logger.i('info');
      logger.d('debug');
      logger.w('warn');
      logger.e('error');
    });

    expect(lineas, isEmpty);
  });

  test('PrintLogger con habilitado: true imprime con prefijo de nivel', () {
    final lineas = _capturarImpresiones(() {
      const logger = PrintLogger(habilitado: true);
      logger.i('mensaje');
      logger.e('fallo');
    });

    expect(lineas, ['[INFO] mensaje', '[ERROR] fallo']);
  });

  test('PrintLogger usa kDebugMode por defecto (release = silencio)', () {
    const logger = PrintLogger();
    expect(logger.habilitado, kDebugMode);
  });
}