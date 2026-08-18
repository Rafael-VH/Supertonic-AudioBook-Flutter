import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/screens/biblioteca/biblioteca_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/convert_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/modelo/modelo_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/settings/settings_screen.dart';
import 'package:supertonic_audiobook/features/editor_metadata/presentation/screens/metadata_editor_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/splash/splash_screen.dart';

/// Nombres de ruta centralizados para que ninguna screen importe otra.
abstract final class Rutas {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const home = '/home';
  static const modelo = '/modelo';
  static const settings = '/settings';
  static const biblioteca = '/biblioteca';
  static const editorMetadata = '/editor-metadata';
}

/// Orígenes admitidos para el redirect del gate del modelo (D5): el modelo se
/// solicita desde `/home` (gate normal) o `/dashboard` (CTA de la card).
/// Cualquier otro origen cae al fallback `/home`.
const _origenesValidos = {Rutas.home, Rutas.dashboard};

/// Notifica a go_router que re-evalúe los redirects cuando cambia el modelo.
class _RefrescoModelo extends ChangeNotifier {
  void refrescar() => notifyListeners();
}

/// Router declarativo. Concentra la navegación y los gates:
/// - `/` nunca se visita: [SplashScreen] decide entre onboarding y dashboard.
/// - El gate del modelo: `/home` sin modelo redirige a `/modelo`, y al quedar
///   listo vuelve al origen conocido (`/home` o `/dashboard`, ver
///   `_origenesValidos`) o a `/home` como fallback.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresco = _RefrescoModelo();
  final router = GoRouter(
    initialLocation: Rutas.splash,
    refreshListenable: refresco,
      redirect: (context, state) {
      final destino = state.matchedLocation;
      final listo = ref.read(modeloControllerProvider).listo;
      if (destino == Rutas.home && !listo) return Rutas.modelo;
      if (destino == Rutas.modelo && listo) {
        // Volver a donde se pidió el modelo: `/dashboard` (CTA de la card)
        // o `/home` (gate normal). Origen desconocido → fallback `/home`.
        final origen = state.extra;
        if (origen is String && _origenesValidos.contains(origen)) {
          return origen;
        }
        return Rutas.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Rutas.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: Rutas.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Rutas.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(path: Rutas.home, builder: (_, __) => const ConvertScreen()),
      GoRoute(path: Rutas.modelo, builder: (_, __) => const ModeloScreen()),
      GoRoute(
        path: Rutas.biblioteca,
        builder: (_, __) => const BibliotecaScreen(),
      ),
      GoRoute(path: Rutas.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: Rutas.editorMetadata,
        builder: (_, __) => const MetadataEditorScreen(),
      ),
    ],
  );

  // Al quedar listo con `/modelo` como ruta tope, el redirect (W-1) decide el
  // destino. go_router solo re-evalúa redirects al re-parsear la URI, y una
  // ruta imperativa (el push del CTA del dashboard, D7) no cambia la URI
  // (re-parsea la base `/dashboard`): se re-navega a `/modelo` con su extra
  // para que el redirect resuelva. Con ruta tope distinta, el refresh basta.
  ref.listen(
    modeloControllerProvider.select((s) => s.listo),
    (previo, listo) {
      if (!listo) return;
      final estado = router.routerDelegate.state;
      if (estado.matchedLocation == Rutas.modelo) {
        router.go(Rutas.modelo, extra: estado.extra);
      } else {
        refresco.refrescar();
      }
    },
  );
  ref.onDispose(refresco.dispose);

  return router;
});
