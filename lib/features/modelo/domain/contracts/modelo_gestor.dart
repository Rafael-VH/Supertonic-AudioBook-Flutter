/// Gestión del modelo supertonic-3 (descarga y verificación en runtime).
///
/// Es la cara que ve la presentación (plan §5.5): verificar, asegurar y
/// cancelar. La implementación concreta vive en `data/modelo/` (`dio` +
/// `path_provider`) y se inyecta desde la composición (`main.dart`).
abstract class ModeloGestor {
  /// Comprueba si el modelo ya está completo y verificado en disco,
  /// sin descargar nada.
  Future<bool> verificarDisponible();

  /// Garantiza el modelo descargado y verificado. Devuelve la ruta del
  /// directorio raíz.
  ///
  /// [onProgreso] recibe `(bytesDescargados, bytesTotales, archivoActual)` y
  /// se invoca a medida que avanza cada descarga. Es resumible: ante una
  /// interrupción se retoma desde donde quedó.
  Future<String> asegurarModelo({
    void Function(int bytes, int total, String archivo)? onProgreso,
  });

  /// Cancela una descarga en curso (no-op si no hay ninguna activa).
  void cancelar();
}
