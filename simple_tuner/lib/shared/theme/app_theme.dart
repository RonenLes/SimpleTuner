import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const seed = Color(0xFF67E8A5);

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF101512),
      useMaterial3: true,
    );
  }
}
