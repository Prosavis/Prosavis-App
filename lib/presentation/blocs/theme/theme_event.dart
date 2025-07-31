abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final bool isDark;
  
  ThemeChanged(this.isDark);
}

class ThemeToggled extends ThemeEvent {}

class ThemeSystemChanged extends ThemeEvent {}