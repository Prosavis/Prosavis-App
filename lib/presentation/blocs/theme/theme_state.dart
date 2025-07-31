import 'package:flutter/material.dart';

abstract class ThemeState {
  final ThemeMode themeMode;
  final bool isDark;
  
  const ThemeState({
    required this.themeMode,
    required this.isDark,
  });
}

class ThemeInitial extends ThemeState {
  const ThemeInitial() : super(
    themeMode: ThemeMode.system,
    isDark: false,
  );
}

class ThemeLight extends ThemeState {
  const ThemeLight() : super(
    themeMode: ThemeMode.light,
    isDark: false,
  );
}

class ThemeDark extends ThemeState {
  const ThemeDark() : super(
    themeMode: ThemeMode.dark,
    isDark: true,
  );
}

class ThemeSystem extends ThemeState {
  const ThemeSystem() : super(
    themeMode: ThemeMode.system,
    isDark: false,
  );
}