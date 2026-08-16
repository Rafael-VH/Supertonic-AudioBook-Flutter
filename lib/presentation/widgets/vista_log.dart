import 'package:flutter/material.dart';

/// Log virtualizado: renderiza solo las líneas visibles (el log puede llegar
/// a miles de entradas; un `SelectableText` con el texto completo re-layout
/// todo el contenido en cada actualización y congela la UI).
class VistaLog extends StatelessWidget {
  const VistaLog({super.key, required this.lineas});

  final List<String> lineas;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.zero,
      itemCount: lineas.length,
      itemBuilder: (context, index) {
        // Con reverse: true el índice 0 es la última línea (la más nueva).
        final linea = lineas[lineas.length - 1 - index];
        return SelectableText(
          linea,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
        );
      },
    );
  }
}
