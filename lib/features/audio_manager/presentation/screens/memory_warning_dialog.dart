import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Diálogo de advertencia de memoria antes de procesar un lote grande.
/// Retorna `true` si el usuario confirma, `false` si cancela.
Future<bool> showMemoryWarningDialog({
  required BuildContext context,
  required int estimatedBytes,
  required int availableBytes,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _MemoryWarningBody(
      estimatedBytes: estimatedBytes,
      availableBytes: availableBytes,
    ),
  );
  return result ?? false;
}

class _MemoryWarningBody extends StatelessWidget {
  const _MemoryWarningBody({
    required this.estimatedBytes,
    required this.availableBytes,
  });

  final int estimatedBytes;
  final int availableBytes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(t.memory_warning_title),
      content: Text(
        '${t.memory_warning_estimated(_formatBytes(estimatedBytes))}\n'
        '${t.memory_warning_available(_formatBytes(availableBytes))}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.memory_warning_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.memory_warning_proceed),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
