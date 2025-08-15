import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;

/// Configuración central de la aplicación
/// Maneja el entorno (desarrollo/producción) y configuraciones específicas
class AppConfig {
  // Configuración del entorno
  static const bool _isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: false);
  static const bool _isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  
  /// Indica si la app está en modo desarrollo
  static bool get isDevelopment => _isDevelopment || (!_isProduction && kDebugMode);
  
  /// Indica si la app está en modo producción
  static bool get isProduction => _isProduction || kReleaseMode;
  
  /// Configuración de Firebase
  static bool get useFirebaseEmulator => isDevelopment;
  static bool get enableFirebaseLogging => isDevelopment;
  
  /// URLs de base
  static String get baseUrl {
    if (isProduction) {
      return 'https://api.prosavis.com';
    } else {
      return 'http://localhost:3000';
    }
  }
  
  /// Configuración de Storage
  static String get storageBasePath {
    if (isProduction) {
      return 'production';
    } else {
      return 'development';
    }
  }
  
  /// Configuración de logs
  static void log(String message, {String? name}) {
    if (isDevelopment) {
      developer.log(message, name: name ?? 'AppConfig');
    }
  }
  
  /// Configuración de debugging
  static bool get enableDetailedLogs => const bool.fromEnvironment('VERBOSE_LOGS', defaultValue: false);
  static bool get enablePerformanceLogging => const bool.fromEnvironment('PERF_LOGS', defaultValue: false);
  static bool get enableSplashSound => const bool.fromEnvironment('SPLASH_SOUND', defaultValue: false);
  
  /// Configuración de características
  static bool get enableBetaFeatures => isDevelopment;
  static bool get enableAnalytics => isProduction;
  
  /// Información del entorno actual
  static void printEnvironmentInfo() {
    log('🚀 Prosavis App - Información del Entorno:');
    log('   - Modo: ${isDevelopment ? "Desarrollo" : "Producción"}');
    log('   - Firebase Emulator: $useFirebaseEmulator');
    log('   - Base URL: $baseUrl');
    log('   - Storage Path: $storageBasePath');
    log('   - Logs detallados: $enableDetailedLogs');
    log('   - Analytics: $enableAnalytics');
  }
}