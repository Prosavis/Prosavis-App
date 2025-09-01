import 'package:flutter/material.dart';

/// Constantes de marca para Prosavis
/// Contiene colores, tipografías y estilos de la marca
class BrandConstants {
  // Prevenir instanciación
  BrandConstants._();

  // ========== COLORES DE MARCA PROSAVIS ==========
  
  /// Color primario de Prosavis - Azul marino del logo
  static const Color primaryColor = Color(0xFF002446);
  
  /// Color secundario - Azul intermedio
  static const Color secondaryColor = Color(0xFF00355F);
  
  /// Color de acento - Naranja energía del logo
  static const Color accentColor = Color(0xFFFF7700);
  
  /// Variaciones del color primario
  static const Color primaryLight = Color(0xFF004D7F);
  static const Color primaryDark = Color(0xFF001A33);
  
  /// Variaciones del color de acento
  static const Color accentLight = Color(0xFFFF8C1A);
  static const Color accentDark = Color(0xFFE66A00);
  
  /// Colores de estado
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFFF7700); // Usando el naranja del logo
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF004D7F);
  
  /// Colores de texto
  static const Color textPrimary = Color(0xFF002446); // Usando el azul del logo
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFFFFFFF);
  
  /// Colores de fondo
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);
  
  /// Colores de superficie
  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8FAFC);
  static const Color surfaceTertiary = Color(0xFFE2E8F0);

  // ========== GRADIENTES DE PROSAVIS ==========
  
  /// Gradiente principal de Prosavis
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight],
  );
  
  /// Gradiente secundario - naranja
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, accentLight],
  );
  
  /// Gradiente de bienvenida
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, primaryLight, Color(0xFF4A8BC2)],
  );

  // ========== TIPOGRAFÍA ==========
  
  /// Familia de fuente principal - Archivo (la fuente de Prosavis)
  static const String primaryFontFamily = 'Archivo';
  
  /// Estilos de texto predefinidos
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.2,
    letterSpacing: -0.5,
    color: textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.3,
    letterSpacing: -0.25,
    color: textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.3,
    color: textPrimary,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: textTertiary,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    height: 1.3,
    letterSpacing: 0.5,
    color: textSecondary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    height: 1.3,
    letterSpacing: 0.5,
    color: textTertiary,
  );

  // ========== ASSETS DE LOGO PROSAVIS ==========
  
  /// Logo principal - Ícono limpio (PNG)
  static const String logoColorSvg = 'assets/branding/logos/logo-icon-clean.svg';
  
  /// Rutas de los logos PNG - Todas unificadas al ícono limpio
  static const String logoColor = 'assets/branding/logos/logo-icon-clean.png';
  static const String logoGrayscale = 'assets/branding/logos/logo-icon-clean.png';
  static const String logoGrayscaleInverted = 'assets/branding/logos/logo-icon-clean.png';
  static const String logoNoBackground = 'assets/branding/logos/logo-icon-clean.png';
  
  /// Rutas de los logos SVG - Todas unificadas al ícono limpio
  static const String logoGrayscaleSvg = 'assets/branding/logos/logo-icon-clean.svg';
  static const String logoGrayscaleInvertedSvg = 'assets/branding/logos/logo-icon-clean.svg';
  static const String logoNoBackgroundSvg = 'assets/branding/logos/logo-icon-clean.svg';

  // ========== ESPACIADO ==========
  
  /// Espaciado estándar de la marca
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  static const double space3xl = 64.0;

  // ========== RADIOS DE BORDE ==========
  
  /// Radios de borde estándar
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 9999.0;

  // ========== SOMBRAS ==========
  
  /// Sombras predefinidas
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x19000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  // ========== UTILIDADES ==========
  
  /// Obtiene el logo adecuado según el tema (siempre ícono limpio PNG)
  static String getLogoForTheme(Brightness brightness) {
    return logoNoBackground; // Siempre usar ícono limpio
  }
  
  /// Obtiene el color de texto adecuado según el fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textLight;
  }
} 