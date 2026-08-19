import 'package:supertonic_audiobook/shared/domain/contracts/domain_logger.dart';

/// A simple logger that prints to console.
///
/// This is the default implementation for development/testing.
/// In production, this could be replaced with a more sophisticated logger
/// (e.g., Crashlytics, Sentry, or a file-based logger).
class PrintLogger implements DomainLogger {
  const PrintLogger();

  @override
  void i(String message) => print('[INFO] $message');

  @override
  void d(String message) => print('[DEBUG] $message');

  @override
  void w(String message) => print('[WARN] $message');

  @override
  void e(String message) => print('[ERROR] $message');
}
