import 'package:flutter/material.dart';

/// Widget reutilizable para campos de texto en el editor de metadatos.
///
/// Elimina la duplicación de TextFormField con patrones similares.
class MetadataField extends StatelessWidget {
  const MetadataField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
