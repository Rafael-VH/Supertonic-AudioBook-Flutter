import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/biblioteca/biblioteca_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/convert_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/settings/settings_screen.dart';

/// Shell principal de la app con BottomNavigationBar. Alterna entre
/// [ConvertBody] (conversión), [BibliotecaBody] (audiolibros) y
/// [SettingsBody] (configuración + estado del modelo).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          ConvertBody(),
          BibliotecaBody(),
          SettingsBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.nav_home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_books_outlined),
            selectedIcon: const Icon(Icons.library_books),
            label: t.nav_biblioteca,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t.nav_settings,
          ),
        ],
      ),
    );
  }
}
