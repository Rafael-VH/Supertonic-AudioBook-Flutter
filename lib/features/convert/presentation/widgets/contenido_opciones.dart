import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/shared/domain/constants/producto.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/formato.dart';
import 'package:supertonic_audiobook/features/convert/presentation/constants/muestra_voz.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Contenido de las opciones de síntesis (formato, voz, sliders, idioma).
class ContenidoOpciones extends StatelessWidget {
  const ContenidoOpciones({
    super.key,
    required this.estado,
    required this.controller,
  });

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final habilitado = !estado.ejecutando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final f in formatosNativos)
              FilterChip(
                label: Text(f.toUpperCase()),
                selected: estado.formatos.contains(f),
                onSelected: habilitado
                    ? (_) => controller.alternarFormato(f)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(t.voz, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: estado.voiceConfig.voz,
          decoration: InputDecoration(
            helperText: t.modelo_supertonic,
            helperStyle: Theme.of(context).textTheme.bodySmall,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
          items: [
            for (final v in voces) DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: habilitado ? (v) => controller.cambiarVoz(v!) : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(t.pasos, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: estado.voiceConfig.steps.toDouble(),
                min: 5,
                max: 12,
                divisions: 7,
                label: '${estado.voiceConfig.steps}',
                onChanged: habilitado
                    ? (v) => controller.cambiarSteps(v.round())
                    : null,
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '${estado.voiceConfig.steps}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Text(t.calidad_lento, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(t.velocidad, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: estado.voiceConfig.speed,
                min: 0.7,
                max: 2.0,
                label: '${estado.voiceConfig.speed.toStringAsFixed(2)}x',
                onChanged: habilitado ? controller.cambiarSpeed : null,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${estado.voiceConfig.speed.toStringAsFixed(2)}x',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Text(t.rapido_lento, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Text(t.idioma_voz, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: estado.voiceConfig.langVoz,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
          items: [
            for (final l in languagesVoz)
              DropdownMenuItem(
                value: l,
                child: Text(
                  l == 'na' ? t.idioma_voz_auto : idiomasVozNativos[l] ?? l,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: habilitado ? (v) => controller.cambiarLangVoz(v!) : null,
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: habilitado && !estado.probandoVoz
              ? () => controller.escuchar(t)
              : null,
          icon: const Icon(Icons.headphones),
          label: Text(t.escuchar),
        ),
      ],
    );
  }
}
