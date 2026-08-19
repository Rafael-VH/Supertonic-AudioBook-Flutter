/// Contract for domain-layer logging.
///
/// This abstraction allows the domain layer to log messages without depending
/// on concrete logging implementations (like `dart:io` stdout or `package:logger`).
///
/// Implementations should be provided via dependency injection in the
/// composition root (providers.dart).
abstract class DomainLogger {
  /// Log an informational message.
  void i(String message);

  /// Log a debug message.
  void d(String message);

  /// Log a warning message.
  void w(String message);

  /// Log an error message.
  void e(String message);
}
