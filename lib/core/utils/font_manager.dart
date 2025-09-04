import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Gestor de fuentes que usa Inter desde assets con fallbacks automáticos por plataforma
class FontManager {
  /// Obtiene TextStyle de Inter desde assets con fallback automático por plataforma
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: _normalizeWeight(fontWeight),
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Obtiene el nombre de la familia de fuente con fallback por plataforma
  static String get fontFamily {
    // iOS: usar fuente del sistema (San Francisco)
    if (!kIsWeb && Platform.isIOS) {
      return '.SF Pro Display'; // iOS system font
    }
    
    // Android/Web: usar Inter desde assets
    return 'Inter';
  }

  /// Normaliza pesos de fuente para Inter Variable Font
  /// Solo usamos weights 400 (Regular), 500 (Medium), 600 (SemiBold)
  static FontWeight? _normalizeWeight(FontWeight? fontWeight) {
    if (fontWeight == null) return null;
    
    // Mapear a los weights disponibles en nuestro setup
    if (fontWeight.index <= FontWeight.w400.index) {
      return FontWeight.w400; // Regular
    } else if (fontWeight.index <= FontWeight.w500.index) {
      return FontWeight.w500; // Medium  
    } else {
      return FontWeight.w600; // SemiBold (máximo para diseño corporativo)
    }
  }

  /// Obtiene TextStyle optimizado para títulos
  static TextStyle get headline1 => inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static TextStyle get headline2 => inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static TextStyle get headline3 => inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// Obtiene TextStyle optimizado para cuerpo de texto
  static TextStyle get body1 => inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get body2 => inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Obtiene TextStyle optimizado para subtítulos
  static TextStyle get subtitle1 => inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get subtitle2 => inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// Obtiene TextStyle optimizado para botones
  static TextStyle get button => inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
  );

  /// Obtiene TextStyle optimizado para captions
  static TextStyle get caption => inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  /// Información de debug sobre fuentes
  static void logFontInfo() {
    developer.log('🔤 FontManager configurado:');
    developer.log('   Plataforma: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    developer.log('   Familia: $fontFamily');
    developer.log('   Fuente: ${!kIsWeb && Platform.isIOS ? "Sistema iOS" : "Inter desde assets"}');
  }
}