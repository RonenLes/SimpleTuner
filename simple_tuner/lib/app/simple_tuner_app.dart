import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tuner/presentation/tuner_screen.dart';
import 'package:simple_tuner/shared/theme/app_theme.dart';

class SimpleTunerApp extends StatelessWidget {
  const SimpleTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Tuner',
      theme: AppTheme.dark,
      home: const TunerScreen(),
    );
  }
}
