import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/screens/biblioteca/biblioteca_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/home/home_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/modelo/modelo_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/seleccion/seleccion_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/settings/settings_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/splash/splash_screen.dart';

/// Nombres de ruta centralizados para que ninguna screen importe otra.
abstract final class Rutas {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const home = '/home';
  static const modelo = '/modelo';
  static const settings = '/settings';
  static const seleccion = '/seleccion';
  static const biblioteca = '/biblioteca';
}

/// Notifica a go_router que re-evalúe los redirects cuando cambia el modelo.
class _RefrescoModelo extends ChangeNotifier {
  void refrescar() => notifyListeners();
}

/// Router declarativo. Concentra la navegación y los gates:
/// - `/` nunca se visita: [SplashScreen] decide entre onboarding y dashboard.
/// - El gate del modelo: `/home` sin modelo redirige a `/modelo`, y al quedar
///   listo vuelve solo a `/home` (antes era el widget privado `_ModeloGate`).
///   La pantalla de selección no tiene gate: solo avisa al procesar (decisión
///   del usuario), y si viene de `/seleccion` el redirect vuelve ahí.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresco = _RefrescoModelo();
  ref.listen(
    modeloControllerProvider.select((s) => s.listo),
    (previo, _) => refresco.refrescar(),
  );
  ref.onDispose(refresco.dispose);

  return GoRouter(
    initialLocation: Rutas.splash,
    refreshListenable: refresco,
    redirect: (context, state) {
      final destino = state.matchedLocation;
      final listo = ref.read(modeloControllerProvider).listo;
      if (destino == Rutas.home && !listo) return Rutas.modelo;
      if (destino == Rutas.modelo && listo) {
        // Volver a donde se pidió el modelo: /seleccion (procesar archivos
        // sueltos) o /home (gate normal).
        return state.extra == Rutas.seleccion ? Rutas.seleccion : Rutas.home;
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
      GoRoute(path: Rutas.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: Rutas.modelo, builder: (_, __) => const ModeloScreen()),
      GoRoute(
        path: Rutas.seleccion,
        builder: (_, __) => const SeleccionScreen(),
      ),
      GoRoute(
        path: Rutas.biblioteca,
        builder: (_, __) => const BibliotecaScreen(),
      ),
      GoRoute(path: Rutas.settings, builder: (_, __) => const SettingsScreen()),
    ],
  );
});
