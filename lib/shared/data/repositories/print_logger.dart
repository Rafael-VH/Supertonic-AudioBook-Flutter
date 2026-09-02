import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:supertonic_audiobook/shared/domain/contracts/domain_logger.dart';

/// A logger that prints to console only in debug builds.
///
/// In release builds this logger is a silent no-op: console printing is
/// development-only noise (auditoría 2026-09-01, hallazgo H2).
class PrintLogger implements DomainLogger {
  const PrintLogger({this.habilitado = kDebugMode});

  /// False in release builds; overridable for tests.
  final bool habilitado;

  void _imprimir(String nivel, String mensaje) {
    if (!habilitado) return;
    debugPrint('$nivel $mensaje');
  }

  @override
  void i(String message) => _imprimir('[INFO]', message);

  @override
  void d(String message) => _imprimir('[DEBUG]', message);

  @override
  void w(String message) => _imprimir('[WARN]', message);

  @override
  void e(String message) => _imprimir('[ERROR]', message);
}
