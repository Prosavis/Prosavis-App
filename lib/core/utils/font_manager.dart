import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gestor de fuentes que maneja fallbacks automáticos cuando Google Fonts falla
class FontManager {
  static bool _googleFontsAvailable = true;
  static bool _hasLoggedWarning = false;

  /// Obtiene TextStyle de Inter con fallback automático a Archivo o system fonts
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    try {
      if (_googleFontsAvailable) {
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          decoration: decoration,
          fontStyle: fontStyle,
        );
      }
    } catch (e) {
      _googleFontsAvailable = false;
      if (!_hasLoggedWarning) {
        developer.log('⚠️ Google Fonts no disponible, usando fallback local: $e');
        _hasLoggedWarning = true;
      }
    }

    // Fallback a fuentes locales
    return _getFallbackTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Obtiene el nombre de la familia de fuente con fallback
  static String get fontFamily {
    if (_googleFontsAvailable) {
      try {
        return GoogleFonts.inter().fontFamily ?? _fallbackFontFamily;
      } catch (e) {
        _googleFontsAvailable = false;
        if (!_hasLoggedWarning) {
          developer.log('⚠️ Google Fonts no disponible para fontFamily, usando fallback: $e');
          _hasLoggedWarning = true;
        }
      }
    }
    return _fallbackFontFamily;
  }

  /// Familia de fuente de fallback
  static const String _fallbackFontFamily = 'Archivo';

  /// TextStyle de fallback usando fuentes del sistema
  static TextStyle _getFallbackTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    // Mapear pesos de fuente para Archivo (que solo tiene weight 900)
    FontWeight? adjustedWeight = fontWeight;
    if (fontWeight != null && fontWeight.index > FontWeight.w600.index) {
      adjustedWeight = FontWeight.w900; // Usar Archivo Black para pesos pesados
    }

    return TextStyle(
      fontFamily: _fallbackFontFamily,
      fontSize: fontSize,
      fontWeight: adjustedWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      // Fallback adicional a fuentes del sistema
      fontFamilyFallback: const [
        'SF Pro Display', // iOS
        'Roboto',        // Android
        'Segoe UI',      // Windows
        'Arial',         // Universal fallback
      ],
    );
  }

  /// Reinicia el estado de disponibilidad de Google Fonts (para testing)
  static void resetAvailability() {
    _googleFontsAvailable = true;
    _hasLoggedWarning = false;
  }

  /// Verifica si Google Fonts está disponible
  static bool get isGoogleFontsAvailable => _googleFontsAvailable;

  /// Preintenta cargar Google Fonts para detectar disponibilidad temprano
  static Future<void> preloadGoogleFonts() async {
    try {
      // Intenta cargar un estilo básico de Inter
      await GoogleFonts.pendingFonts([
        GoogleFonts.inter(),
        GoogleFonts.inter(fontWeight: FontWeight.w600),
        GoogleFonts.inter(fontWeight: FontWeight.bold),
      ]);
      _googleFontsAvailable = true;
      developer.log('✅ Google Fonts precargado exitosamente');
    } catch (e) {
      _googleFontsAvailable = false;
      developer.log('⚠️ No se pudo precargar Google Fonts, usando fallbacks: $e');
    }
  }
}
