import 'package:flutter/material.dart';

/// Tokens de diseño para mantener consistencia cromática y eliminar
/// el tinte de Material 3 que contamina los colores personalizados
class AppTokens {
  // === COLORES DE MARCA ===
  static const Color primary = Color(0xFFFF8A00);     // Naranja principal
  static const Color secondary = Color(0xFF00AFA3);   // Azul-verde secundario
  static const Color primaryDark = Color(0xFF1976D2); // Azul oscuro para acentos
  
  // === SUPERFICIES NEUTRAS ===
  static const Color surface = Color(0xFFFFFFFF);         // Blanco puro
  static const Color surfaceAlt = Color(0xFFF7F8FA);      // Fondo de listas/secciones
  static const Color surfaceAccent = Color(0xFFF1F3F6);   // Chips/headers suaves
  static const Color surfaceElevated = Color(0xFFFAFBFC); // Tarjetas elevadas
  
  // === TEXTOS ===
  static const Color textPrimary = Color(0xFF1F2937);     // Texto principal
  static const Color textSecondary = Color(0xFF6B7280);   // Texto secundario
  static const Color textTertiary = Color(0xFF9CA3AF);    // Texto terciario
  static const Color textOnPrimary = Colors.white;        // Texto sobre primario
  
  // === BORDES Y DIVISORES ===
  static const Color outline = Color(0xFFE5E7EB);         // Bordes sutiles
  static const Color outlineVariant = Color(0xFFF3F4F6);  // Bordes muy sutiles
  static const Color divider = Color(0xFFEFEFEF);         // Divisores
  
  // === ESTADOS ===
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // === SOMBRAS ===
  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );
  
  static final BoxShadow elevatedShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 15,
    offset: const Offset(0, 4),
  );
  
  // === GRADIENTES SUTILES MODO CLARO ===
  
  /// Gradiente suave para sección de Categorías (azul claro → naranja muy sutil)
  static const LinearGradient categoriesGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF1F8FF), // Azul muy claro
      Color(0xFFFFF8F1), // Naranja muy claro
      surface,           // Blanco puro
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Gradiente suave para Servicios Destacados (naranja muy sutil → blanco)
  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8F1), // Naranja muy claro
      Color(0xFFFFFBF7), // Naranja casi imperceptible
      surface,           // Blanco puro
    ],
    stops: [0.0, 0.4, 1.0],
  );
  
  /// Gradiente suave para Cerca de ti (azul muy sutil → blanco)
  static const LinearGradient nearbyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF1F8FF), // Azul muy claro
      Color(0xFFF8FCFF), // Azul casi imperceptible
      surface,           // Blanco puro
    ],
    stops: [0.0, 0.4, 1.0],
  );
  
  // === GRADIENTES SUTILES MODO OSCURO ===
  
  /// Gradiente suave para sección de Categorías en modo oscuro
  static const LinearGradient categoriesGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E3A8A), // Azul oscuro sutil
      Color(0xFF1F2937), // Gris azulado
      Color(0xFF111827), // Fondo oscuro
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Gradiente suave para Servicios Destacados en modo oscuro
  static const LinearGradient featuredGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF7C2D12), // Naranja oscuro sutil
      Color(0xFF1F2937), // Gris neutral
      Color(0xFF111827), // Fondo oscuro
    ],
    stops: [0.0, 0.4, 1.0],
  );
  
  /// Gradiente suave para Cerca de ti en modo oscuro
  static const LinearGradient nearbyGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E40AF), // Azul oscuro
      Color(0xFF1F2937), // Gris azulado
      Color(0xFF111827), // Fondo oscuro
    ],
    stops: [0.0, 0.4, 1.0],
  );
  
  /// Acento superior para secciones (franja colorida sutil)
  static LinearGradient getAccentStripe(Color baseColor) {
    return LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.18),
        baseColor.withValues(alpha: 0.12),
        Colors.transparent,
      ],
    );
  }
  
  // === COLORES DE CHIPS PARA CATEGORÍAS ===
  static Color getCategoryChipColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'limpieza':
        return const Color(0xFF64B5F6).withValues(alpha: 0.1);
      case 'belleza':
        return const Color(0xFFE91E63).withValues(alpha: 0.1);
      case 'plomería':
        return const Color(0xFF2196F3).withValues(alpha: 0.1);
      case 'electricidad':
        return const Color(0xFFFFC107).withValues(alpha: 0.1);
      case 'pintura':
        return const Color(0xFF9C27B0).withValues(alpha: 0.1);
      case 'carpintería':
        return const Color(0xFF795548).withValues(alpha: 0.1);
      case 'jardinería':
        return const Color(0xFF4CAF50).withValues(alpha: 0.1);
      case 'mecánica':
        return const Color(0xFF607D8B).withValues(alpha: 0.1);
      default:
        return surfaceAccent;
    }
  }
  
  static Color getCategoryIconColor(String categoryName, {bool isDarkMode = false}) {
    if (isDarkMode) {
      // Colores más brillantes para modo oscuro
      switch (categoryName.toLowerCase()) {
        case 'limpieza':
          return const Color(0xFF64B5F6);
        case 'belleza':
          return const Color(0xFFE91E63);
        case 'plomería':
          return const Color(0xFF42A5F5);
        case 'electricidad':
          return const Color(0xFFFFB74D);
        case 'pintura':
          return const Color(0xFFBA68C8);
        case 'carpintería':
          return const Color(0xFF8D6E63);
        case 'jardinería':
          return const Color(0xFF66BB6A);
        case 'mecánica':
          return const Color(0xFF78909C);
        default:
          return Colors.white;
      }
    } else {
      // Colores originales para modo claro
      switch (categoryName.toLowerCase()) {
        case 'limpieza':
          return const Color(0xFF1976D2);
        case 'belleza':
          return const Color(0xFFC2185B);
        case 'plomería':
          return const Color(0xFF1565C0);
        case 'electricidad':
          return const Color(0xFFF57C00);
        case 'pintura':
          return const Color(0xFF7B1FA2);
        case 'carpintería':
          return const Color(0xFF5D4037);
        case 'jardinería':
          return const Color(0xFF388E3C);
        case 'mecánica':
          return const Color(0xFF455A64);
        default:
          return textPrimary;
      }
    }
  }
}
