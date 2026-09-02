import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_preferencias.dart';

/// Prepend conversion entries to history, cap at 100, save.
class RegistrarConversionEnHistorial {
  RegistrarConversionEnHistorial(this._repo);
  final RepositorioPreferencias _repo;

  void call(List<Map<String, Object?>> entradas) {
    final datos = _repo.cargar();
    final raw = datos['conversion_history'];
    final historial = <Map<String, Object?>>[];
    if (raw is List) {
      historial.addAll(raw.whereType<Map>().cast<Map<String, Object?>>());
    }
    historial.insertAll(0, entradas);
    if (historial.length > 100) {
      historial.removeRange(100, historial.length);
    }
    datos['conversion_history'] = historial;
    _repo.guardar(datos);
  }
}
