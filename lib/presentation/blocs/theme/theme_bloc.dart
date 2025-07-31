import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_mode';
  
  ThemeBloc() : super(const ThemeInitial()) {
    on<ThemeChanged>(_onThemeChanged);
    on<ThemeToggled>(_onThemeToggled);
    on<ThemeSystemChanged>(_onThemeSystemChanged);
    
    _loadTheme();
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    if (event.isDark) {
      emit(const ThemeDark());
    } else {
      emit(const ThemeLight());
    }
    await _saveTheme(event.isDark ? 'dark' : 'light');
  }

  void _onThemeToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    if (state is ThemeLight) {
      emit(const ThemeDark());
      await _saveTheme('dark');
    } else if (state is ThemeDark) {
      emit(const ThemeLight());
      await _saveTheme('light');
    } else {
      // Si está en system, cambiar a light por defecto
      emit(const ThemeLight());
      await _saveTheme('light');
    }
  }

  void _onThemeSystemChanged(ThemeSystemChanged event, Emitter<ThemeState> emit) async {
    emit(const ThemeSystem());
    await _saveTheme('system');
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeMode = prefs.getString(_themeKey) ?? 'system';
      
      switch (themeMode) {
        case 'light':
          add(ThemeChanged(false));
          break;
        case 'dark':
          add(ThemeChanged(true));
          break;
        case 'system':
        default:
          add(ThemeSystemChanged());
          break;
      }
    } catch (e) {
      add(ThemeSystemChanged());
    }
  }

  Future<void> _saveTheme(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeMode);
    } catch (e) {
      // Manejar error de guardado silenciosamente
    }
  }
}