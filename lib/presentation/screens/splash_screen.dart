import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/onboarding_screen.dart';

/// Pantalla de arranque. Muestra la marca mientras decide el destino:
/// onboarding en la primera ejecución, dashboard en las siguientes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _duracionMinima = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _decidirDestino();
  }

  Future<void> _decidirDestino() async {
    await Future<void>.delayed(_duracionMinima);
    if (!mounted) return;
    final prefs = ref.read(repositorioPreferenciasProvider).cargar();
    final destino = prefs['onboarding_visto'] == true
        ? const DashboardScreen()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destino),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over_outlined, size: 72, color: colores.primary),
            const SizedBox(height: 16),
            Text(t.ventana_titulo, style: texto.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(t.splash_descripcion, style: texto.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
