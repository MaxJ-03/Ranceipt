import 'package:flutter/material.dart';

class AppColors {
  // Base: deep obsidian purple
  static const bg = Color(0xFF0B0712);
  static const bgSoft = Color(0xFF120D1D);

  // Surfaces
  static const surface = Color(0xFF181123);
  static const surfaceSoft = Color(0xFF21172F);
  static const surfaceLift = Color(0xFF271C38);
  static const border = Color(0xFF342944);

  // Small, calm palette
  static const primary = Color(0xFF8C6CF2);
  static const aqua = Color(0xFF64D8C3);
  static const amber = Color(0xFFE8B96D);
  static const rose = Color(0xFFE77B93);
  static const green = Color(0xFF78D99A);

  // Text
  static const text = Color(0xFFF8F5FF);
  static const muted = Color(0xFFCFC5DE);
  static const faint = Color(0xFF9588A8);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7A4FE8), Color(0xFF32224D), Color(0xFF181123)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF64D8C3), Color(0xFF8C6CF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
