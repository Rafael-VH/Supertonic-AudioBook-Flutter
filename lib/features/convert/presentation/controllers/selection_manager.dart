import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';

/// Manages file selection state for the convert screen.
///
/// This class encapsulates all selection-related logic, including:
/// - Toggling individual file selection
/// - Selecting all files
/// - Clearing selection
/// - Managing external file additions and removals
class SelectionManager {
  /// Current selection state (set of selected file paths).
  Set<String> seleccion;

  SelectionManager({Set<String>? initial}) : seleccion = initial ?? {};

  /// Toggle selection for a file path.
  ///
  /// Returns the updated selection set.
  Set<String> alternarSeleccion(String ruta) {
    final updated = {...seleccion};
    if (!updated.add(ruta)) updated.remove(ruta);
    seleccion = updated;
    return seleccion;
  }

  /// Select all files from the provided list.
  ///
  /// Returns the updated selection set containing all file paths.
  Set<String> seleccionarTodo(List<Archivo> archivos) {
    seleccion = archivos.map((a) => a.ruta).toSet();
    return seleccion;
  }

  /// Clear all selections.
  ///
  /// Returns an empty selection set.
  Set<String> limpiarSeleccion() {
    seleccion = const {};
    return seleccion;
  }

  /// Merge external files into the current selection, preserving existing marks.
  ///
  /// Only updates selection for files that still exist in the new list.
  /// Returns the updated selection set.
  Set<String> mergeArchivosExternos(List<Archivo> archivos) {
    final rutas = archivos.map((a) => a.ruta).toSet();
    seleccion = seleccion.where(rutas.contains).toSet();
    return seleccion;
  }

  /// Filter selection to only include files that exist in the provided list.
  ///
  /// Used when the file list is refreshed to remove stale selections.
  Set<String> filtrarSeleccion(List<Archivo> archivos) {
    final rutas = archivos.map((a) => a.ruta).toSet();
    seleccion = seleccion.where(rutas.contains).toSet();
    return seleccion;
  }
}
