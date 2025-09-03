import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/font_manager.dart';
import '../constants/app_tokens.dart';
import 'package:animations/animations.dart';

class AppTheme {
  // Colores principales de Prosavis basados en el logo
  static const Color primaryColor = Color(0xFF002446); // Azul marino del logo
  static const Color secondaryColor = Color(0xFF00355F); // Azul más claro
  static const Color accentColor = Color(0xFFFF7700); // Naranja del logo
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFF8FAFC); // Alias para backgroundColor
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFFF7700); // Usando el naranja del logo
  static const Color successColor = Color(0xFF10B981);
  
  // Colores de texto para modo claro (deprecated - usar getters adaptativos)
  static const Color textPrimary = Color(0xFF002446); // Usando el azul del logo
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Colores adaptativos para modo oscuro
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE2E8F0);
  static const Color darkTextTertiary = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF475569);
  
  // Getters adaptativos que detectan el tema actual
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextPrimary 
        : textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : textSecondary;
  }
  
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextTertiary 
        : textTertiary;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSurface 
        : surfaceColor;
  }
  
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : backgroundColor;
  }
  
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBorder 
        : Colors.grey.shade200;
  }
  
  static Color getContainerColor(BuildContext context, {double alpha = 1.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
        ? darkSurfaceVariant.withValues(alpha: alpha)
        : Colors.grey.shade100.withValues(alpha: alpha);
  }
  
  // Gradientes actualizados con los colores de Prosavis
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accentColor, Color(0xFFFF8C1A)], // Variaciones del naranja
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente de bienvenida para el onboarding/login
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A1A2B), // Azul marino oscuro
      Color(0xFF002446), // Azul marino marca
      Color(0xFF00355F), // Azul intermedio
      Color(0xFFFF6A00), // Naranja del logo
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  // Variante suave del gradiente de bienvenida (misma dirección, menor opacidad)
  static LinearGradient welcomeGradientSoft({double alpha = 0.14}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF0A1A2B),
        Color(0xFF002446),
        Color(0xFF00355F),
        Color(0xFFFF6A00),
      ].map((c) => c.withValues(alpha: alpha)).toList(growable: false),
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
  }

  // Gradiente base específicamente pensado para títulos de Home (más progresivo)
  static const LinearGradient homeHeadersGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A1A2B), // muy oscuro
      primaryColor,      // azul marca
      secondaryColor,    // azul intermedio
      Color(0xFFFF6A00), // naranja
    ],
    stops: [0.0, 0.25, 0.55, 1.0],
  );

  // --- Utilidades para degradado continuo por segmentos ---
  static LinearGradient continuousHeaderGradientSegment({
    required int index,
    int total = 3,
  }) {
    assert(total > 0 && index >= 0 && index < total);
    // Fronteras no uniformes para asegurar color visible en los 3 bloques
    final List<double> defaultBoundaries = switch (total) {
      3 => <double>[0.0, 0.38, 0.72, 1.0],
      _ => List<double>.generate(total + 1, (i) => i / total),
    };
    final double start = defaultBoundaries[index];
    final double end = defaultBoundaries[index + 1];
    return _sliceLinearGradient(homeHeadersGradient, start, end);
  }

  // Toma un gradiente base y devuelve un sub-rango [start, end] en 0..1
  static LinearGradient _sliceLinearGradient(
    LinearGradient base,
    double start,
    double end,
  ) {
    // Puntos de muestreo dentro del segmento para mantener suavidad
    const List<double> localStops = [0.0, 0.33, 0.66, 1.0];
    final List<Color> colors = localStops
        .map((p) => _sampleGradient(base, start + (end - start) * p))
        .toList(growable: false);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: localStops,
    );
  }

  // Interpola el color del gradiente base en la posición t (0..1)
  static Color _sampleGradient(LinearGradient gradient, double t) {
    final List<double> stops = gradient.stops ??
        List<double>.generate(gradient.colors.length, (i) => i / (gradient.colors.length - 1));
    if (t <= stops.first) return gradient.colors.first;
    if (t >= stops.last) return gradient.colors.last;
    for (int i = 0; i < stops.length - 1; i++) {
      final double a = stops[i];
      final double b = stops[i + 1];
      if (t >= a && t <= b) {
        final double localT = (t - a) / (b - a);
        return Color.lerp(gradient.colors[i], gradient.colors[i + 1], localT)!
            .withAlpha(255);
      }
    }
    return gradient.colors.last;
  }

  static ThemeData get lightTheme {
    // Crear ColorScheme con los tokens y sin tinte de superficies
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.light,
      primary: AppTokens.primary,
      secondary: AppTokens.secondary,
      error: AppTokens.error,
      surface: AppTokens.surface,
      onSurface: AppTokens.textPrimary,
    );
    
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.surface,
      fontFamily: FontManager.fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        },
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: FontManager.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppTokens.textPrimary),
      ),
      
      // Card Theme - SIN tinte de Material 3
      cardTheme: const CardThemeData(
        color: AppTokens.surface,
        surfaceTintColor: Colors.transparent, // <-- CLAVE: elimina el tinte
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        shadowColor: Colors.black,
      ),
      
      // BottomSheet Theme - SIN tinte
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent, // <-- elimina el tinte
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Dialog Theme - SIN tinte  
      dialogTheme: const DialogThemeData(
        surfaceTintColor: Colors.transparent, // <-- elimina el tinte
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: AppTokens.textOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: FontManager.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: FontManager.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTokens.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: AppTokens.textTertiary,
          fontSize: 16,
        ),
      ),
      
      // Text Theme con tokens actualizados
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTokens.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTokens.textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        headlineLarge: FontManager.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        headlineMedium: FontManager.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTokens.textPrimary,
        ),
        headlineSmall: FontManager.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTokens.textPrimary,
        ),
        titleLarge: FontManager.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
        ),
        titleMedium: FontManager.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
        ),
        titleSmall: FontManager.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
        ),
        bodyLarge: FontManager.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppTokens.textPrimary,
        ),
        bodyMedium: FontManager.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppTokens.textSecondary,
        ),
        bodySmall: FontManager.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppTokens.textTertiary,
        ),
        labelMedium: FontManager.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        labelSmall: FontManager.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    // ColorScheme para modo oscuro con tokens y sin tinte
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.dark,
      primary: AppTokens.primary,
      secondary: AppTokens.secondary,
      error: AppTokens.error,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    );
    
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: FontManager.fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        },
      ),
      
      // AppBar Theme para modo oscuro
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: FontManager.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Texto blanco en modo oscuro
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Card Theme para modo oscuro - SIN tinte
      cardTheme: const CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent, // <-- elimina el tinte
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        shadowColor: Colors.black,
      ),
      
      // BottomSheet Theme para modo oscuro - SIN tinte
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent, // <-- elimina el tinte
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Dialog Theme para modo oscuro - SIN tinte
      dialogTheme: const DialogThemeData(
        surfaceTintColor: Colors.transparent, // <-- elimina el tinte
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Elevated Button Theme para modo oscuro
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: FontManager.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Theme con colores ajustados para modo oscuro
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: FontManager.inter(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: FontManager.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineSmall: FontManager.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: FontManager.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: FontManager.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleSmall: FontManager.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: FontManager.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE2E8F0), // Gris claro para mejor contraste
        ),
        bodyMedium: FontManager.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFCBD5E1), // Gris medio para texto secundario
        ),
        bodySmall: FontManager.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF94A3B8), // Gris más suave para texto terciario
        ),
        labelMedium: FontManager.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Input Decoration Theme para modo oscuro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      
      // BottomNavigationBar Theme para modo oscuro (alto contraste)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFE2E8F0),
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
