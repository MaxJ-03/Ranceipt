import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFF0B0714);
  static const Color surface = Color(0xFF171022);
  static const Color surfaceSoft = Color(0xFF21182E);
  static const Color border = Color(0xFF2C2140);

  static const Color text = Color(0xFFF5F1FA);
  static const Color muted = Color(0xFFB8AEC9);
  static const Color faint = Color(0xFF8A7FA0);

  static const Color primary = Color(0xFF7C5CFF);
  static const Color aqua = Color(0xFF67D6C3);
  static const Color amber = Color(0xFFF0BE62);
  static const Color green = Color(0xFF69D98F);
  static const Color rose = Color(0xFFFF7D8F);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6F3FF5),
      Color(0xFF2A1B4D),
      Color(0xFF140C23),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B6BFF),
      Color(0xFF67D6C3),
    ],
  );
}