import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

/// Onboarding de primera ejecución. Explica cómo generar audio en 4 pasos
/// (modelo → archivos → voz → procesar) antes de entrar al dashboard.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _paso = 0;
  String? _carpetaSeleccionada;

  static const _totalPasos = 5;

  void _irA(int pagina) {
    _pageController.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _elegirCarpeta() async {
    final carpeta = await FilePicker.getDirectoryPath();
    if (carpeta != null) {
      setState(() => _carpetaSeleccionada = carpeta);
      final repo = ref.read(repositorioPreferenciasProvider);
      final current = repo.cargarPreferenciasTyped();
      repo.guardarPreferenciasTyped(
        current.copyWith(carpetaSalida: carpeta),
      );
    }
  }

  void _finalizar() {
    final repo = ref.read(repositorioPreferenciasProvider);
    final current = repo.cargarPreferenciasTyped();
    repo.guardarPreferenciasTyped(
      current.copyWith(onboardingVisto: true),
    );
    context.go(Rutas.dashboard);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colores = Theme.of(context).colorScheme;

    final pasos = [
      _PasoOnboarding(
        icono: Icons.download_outlined,
        titulo: t.onboarding_paso1_titulo,
        descripcion: t.onboarding_paso1_descripcion,
      ),
      _PasoOnboarding(
        icono: Icons.folder_open_outlined,
        titulo: t.onboarding_paso2_titulo,
        descripcion: t.onboarding_paso2_descripcion,
      ),
      _PasoOnboarding(
        icono: Icons.record_voice_over_outlined,
        titulo: t.onboarding_paso3_titulo,
        descripcion: t.onboarding_paso3_descripcion,
      ),
      _PasoOnboarding(
        icono: Icons.graphic_eq_outlined,
        titulo: t.onboarding_paso4_titulo,
        descripcion: t.onboarding_paso4_descripcion,
      ),
    ];

    final esUltimo = _paso == _totalPasos - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _finalizar,
                  child: Text(t.onboarding_saltar),
                ),
              ),
            ),
            Text(
              t.onboarding_titulo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPasos,
                onPageChanged: (pagina) => setState(() => _paso = pagina),
                itemBuilder: (context, indice) {
                  if (indice == 4) {
                    return _PasoOnboardingCarpeta(
                      ruta: _carpetaSeleccionada,
                      onElegir: _elegirCarpeta,
                    );
                  }
                  return pasos[indice];
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPasos,
                (indice) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: indice == _paso ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: indice == _paso
                        ? colores.primary
                        : colores.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: esUltimo
                    ? FilledButton.icon(
                        onPressed: _finalizar,
                        icon: const Icon(Icons.check),
                        label: Text(t.onboarding_empezar),
                      )
                    : FilledButton(
                        onPressed: () => _irA(_paso + 1),
                        child: Text(t.onboarding_siguiente),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoOnboarding extends StatelessWidget {
  const _PasoOnboarding({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 48, color: colores.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(
            titulo,
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            descripcion,
            style: texto.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PasoOnboardingCarpeta extends StatelessWidget {
  const _PasoOnboardingCarpeta({
    required this.ruta,
    required this.onElegir,
  });

  final String? ruta;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: colores.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            t.onboarding_paso5_titulo,
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            t.onboarding_paso5_descripcion,
            style: texto.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: onElegir,
            icon: const Icon(Icons.folder_open),
            label: Text(t.onboarding_paso5_examinar),
          ),
          if (ruta != null) ...[
            const SizedBox(height: 12),
            Text(
              t.onboarding_paso5_ruta(ruta!),
              style: texto.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
