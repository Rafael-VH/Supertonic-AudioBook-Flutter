import 'package:flutter/material.dart';

import 'presentation/screens/home_screen.dart';

class SupertonicApp extends StatelessWidget {
  const SupertonicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supertonic-AudioBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
