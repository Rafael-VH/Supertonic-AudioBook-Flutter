import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/features/convert/domain/entities/archivo.dart';

/// Fila de un archivo `.md` con su checkbox de selección.
class ArchivoTile extends StatelessWidget {
  const ArchivoTile({
    super.key,
    required this.archivo,
    required this.seleccionado,
    required this.onChanged,
    this.habilitado = true,
  });

  final Archivo archivo;
  final bool seleccionado;
  final bool habilitado;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: seleccionado,
      onChanged: habilitado
          ? (v) => onChanged(v ?? false)
          : null,
      title: Text(
        archivo.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
