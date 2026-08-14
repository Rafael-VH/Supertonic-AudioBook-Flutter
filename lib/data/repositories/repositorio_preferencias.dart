import 'dart:convert';
import 'dart:io';

import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';

/// Preferencias persistidas en un JSON local legible (indentado).
class PreferenciasJsonLocal implements RepositorioPreferencias {
  PreferenciasJsonLocal({required this._ruta});

  final String _ruta;

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Map<String, Object> cargar() {
    try {
      final archivo = File(_ruta);
      if (!archivo.existsSync()) return {};
      final datos = jsonDecode(archivo.readAsStringSync());
      if (datos is Map<String, dynamic>) return datos.cast<String, Object>();
    } catch (_) {
      // JSON corrupto → empezar de cero.
    }
    return {};
  }

  @override
  void guardar(Map<String, Object> preferencias) {
    try {
      final archivo = File(_ruta);
      archivo.parent.createSync(recursive: true);
      archivo.writeAsStringSync(_encoder.convert(preferencias));
    } catch (_) {
      // Sin permiso / ruta inválida → no puede persistir, no abortar.
    }
  }
}
