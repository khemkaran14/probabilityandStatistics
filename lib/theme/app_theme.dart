import 'package:flutter/material.dart';

/// Light, bright, colourful palette.
class AppColors {
  AppColors._();

  // Grounds
  static const bg = Color(0xFFFFF9F2); // warm white page
  static const card = Color(0xFFFFFFFF);
  static const board = Color(0xFFF2EEFF); // soft lavender animation stage
  static const chip = Color(0xFFF3F0FA);
  static const peg = Color(0xFFA79FD9);

  // Text
  static const ink = Color(0xFF1E1B3A);
  static const muted = Color(0xFF625E86);

  // Accents
  static const pink = Color(0xFFFF3D8B);
  static const orange = Color(0xFFFF7A1A);
  static const yellow = Color(0xFFFFC93C);
  static const green = Color(0xFF2BC46F);
  static const cyan = Color(0xFF14C3D0);
  static const blue = Color(0xFF4C7DFF);
  static const violet = Color(0xFF9B5CFF);

  static const rainbow = <Color>[pink, orange, yellow, green, cyan, blue, violet];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.pink,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.orange,
      inactiveTrackColor: AppColors.chip,
      thumbColor: AppColors.orange,
      overlayColor: AppColors.orange.withValues(alpha: 0.15),
      trackHeight: 8,
    ),
  );
}

/// Shared heavy display style for titles.
const TextStyle kDisplay = TextStyle(
  fontSize: 30,
  height: 1.08,
  fontWeight: FontWeight.w900,
  letterSpacing: -0.6,
  color: AppColors.ink,
);
