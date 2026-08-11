/// Lectura y escritura de preferencias de la interfaz (contrato de dominio).
abstract class RepositorioPreferencias {
  /// Devuelve las preferencias guardadas (vacío si no hay ninguna).
  Map<String, Object> cargar();

  /// Persiste las preferencias dadas (valores serializables).
  void guardar(Map<String, Object> preferencias);
}
