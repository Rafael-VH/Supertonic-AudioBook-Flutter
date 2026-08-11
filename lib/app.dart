import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/controllers/settings_controller.dart';
import 'presentation/l10n/app_localizations.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_theme.dart';

class SupertonicApp extends ConsumerWidget {
  const SupertonicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(settingsControllerProvider);
    final titulo = AppLocalizations.of(context)?.ventana_titulo ??
        'Supertonic-AudioBook';

    return MaterialApp(
      title: titulo,
      theme: construirTema(oscuro: false, estilo: ajustes.estilo),
      darkTheme: construirTema(oscuro: true, estilo: ajustes.estilo),
      themeMode: ajustes.temaOscuro ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      locale: Locale(ajustes.idioma),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
