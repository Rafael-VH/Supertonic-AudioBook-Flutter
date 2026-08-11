import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Metadatos del producto (plan §6.4 — contenido EXACTO).
const appNombre = 'Supertonic-AudioBook';
const appVersion = '1.0.3';
const repositorioUrl = 'https://github.com/Rafael-VH/Supertonic-AudioBook';
const modeloUrl = 'https://huggingface.co/Supertone/supertonic-3';
const modeloGithubUrl = 'https://github.com/supertone-inc/supertonic';

/// Sección "Acerca de" (paridad con el LabelFrame del desktop).
class AcercaDeSection extends StatelessWidget {
  const AcercaDeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primario = Theme.of(context).colorScheme.primary;
    final texto = Theme.of(context).colorScheme.onSurface;
    final secundario = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appNombre,
            style: TextStyle(color: primario, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${t?.acerca_version ?? 'Versión'} $appVersion',
            style: TextStyle(color: secundario)),
        const SizedBox(height: 4),
        Text(t?.acerca_descripcion ?? '', style: TextStyle(color: texto)),
        const SizedBox(height: 4),
        Text(t?.acerca_creditos ?? '', style: TextStyle(color: texto)),
        const SizedBox(height: 4),
        _Enlace(
          etiqueta: t?.acerca_ver_modelo ?? 'Ver el modelo en Hugging Face',
          url: modeloUrl,
          color: primario,
        ),
        _Enlace(
          etiqueta: t?.acerca_ver_codigo ?? 'Código fuente del modelo',
          url: modeloGithubUrl,
          color: primario,
        ),
        const SizedBox(height: 4),
        Text(t?.acerca_licencia ?? 'Licencia MIT',
            style: TextStyle(color: texto)),
        const SizedBox(height: 8),
        _Enlace(
          etiqueta:
              t?.acerca_abrir_repositorio ?? 'Abrir repositorio en GitHub',
          url: repositorioUrl,
          color: primario,
        ),
      ],
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace({
    required this.etiqueta,
    required this.url,
    required this.color,
  });

  final String etiqueta;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: TextButton(
        onPressed: () => launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: color,
        ),
        child: Text(etiqueta,
            style: const TextStyle(decoration: TextDecoration.underline)),
      ),
    );
  }
}
