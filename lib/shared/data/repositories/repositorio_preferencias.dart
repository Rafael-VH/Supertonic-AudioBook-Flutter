import 'dart:convert';
import 'dart:io';

import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/shared/domain/entities/app_preferences.dart';

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

  /// Persist an [AppPreferences] to disk.
  void guardarPreferenciasTyped(AppPreferences prefs) {
    final map = <String, Object>{
      for (final e in prefs.toMap().entries)
        if (e.value != null) e.key: e.value!,
    };
    guardar(map);
  }

  /// Load an [AppPreferences] from disk (returns defaults if missing/empty).
  AppPreferences cargarPreferenciasTyped() {
    final map = cargar();
    return AppPreferences.fromMap(map);
  }
}
