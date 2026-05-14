import 'package:flutter/material.dart';

import 'features/map/presentation/map_screen.dart';

class PawsApp extends StatelessWidget {
  const PawsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1565C0);
    return MaterialApp(
      title: 'PAWS - Toilet & Aire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          primary: seed,
          secondary: const Color(0xFF43A047),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
      home: const MapScreen(),
    );
  }
}
