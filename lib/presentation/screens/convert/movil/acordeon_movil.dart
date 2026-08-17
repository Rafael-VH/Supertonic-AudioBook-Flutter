import 'package:flutter/material.dart';

/// Encabezado de sección de la vista móvil. El contenido activo se muestra en
/// un único `Expanded` del padre (uno abierto a la vez ocupando todo el alto).
class EncabezadoAcordeon extends StatelessWidget {
  const EncabezadoAcordeon({
    super.key,
    required this.titulo,
    required this.activo,
    required this.onTap,
  });

  final String titulo;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(titulo, style: texto.titleMedium),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  activo ? Icons.expand_less : Icons.expand_more,
                  key: ValueKey(activo),
                  color: activo ? colores.primary : colores.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
