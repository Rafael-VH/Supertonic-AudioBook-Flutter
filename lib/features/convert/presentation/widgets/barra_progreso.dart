import 'package:flutter/material.dart';

/// Barra de progreso del procesamiento con su porcentaje.
class BarraProgreso extends StatelessWidget {
  const BarraProgreso({super.key, required this.actual, required this.total});

  final int actual;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (actual / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(value: pct),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(pct * 100).round()}%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
