import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../config/app_config.dart';
import 'dart:developer' as developer;

/// Servicio centralizado de logging que integra Firebase Crashlytics
/// con logging local para desarrollo y producción
class LoggingService {
  
  /// Registra un error no fatal en Crashlytics
  static Future<void> logError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) async {
    try {
      // Log local para desarrollo
      if (AppConfig.isDevelopment) {
        developer.log(
          'ERROR: $error',
          name: 'LoggingService',
          error: error,
          stackTrace: stackTrace,
        );
        if (reason != null) {
          developer.log('Reason: $reason', name: 'LoggingService');
        }
        if (additionalData != null) {
          developer.log('Additional data: $additionalData', name: 'LoggingService');
        }
      }
      
      // Enviar a Crashlytics en producción
      if (!AppConfig.isDevelopment) {
        // Agregar datos adicionales como custom keys
        if (additionalData != null) {
          for (final entry in additionalData.entries) {
            await FirebaseCrashlytics.instance.setCustomKey(
              entry.key, 
              entry.value.toString(),
            );
          }
        }
        
        // Registrar el error
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: fatal,
          information: [reason ?? 'Error registrado por LoggingService'],
        );
      }
    } catch (e) {
      // Fallback si falla el logging
      developer.log(
        'Error en LoggingService: $e',
        name: 'LoggingService',
        error: e,
      );
    }
  }
  
  /// Registra un mensaje de información/debug
  static void logInfo(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (AppConfig.enableDetailedLogs) {
      developer.log(
        message,
        name: category ?? 'App',
      );
      
      if (data != null) {
        developer.log(
          'Data: $data',
          name: category ?? 'App',
        );
      }
    }
  }
  
  /// Registra un warning
  static Future<void> logWarning(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Log local
      developer.log(
        'WARNING: $message',
        name: category ?? 'App',
      );
      
      // En producción, enviar como evento no fatal a Crashlytics
      if (!AppConfig.isDevelopment) {
        if (data != null) {
          for (final entry in data.entries) {
            await FirebaseCrashlytics.instance.setCustomKey(
              entry.key, 
              entry.value.toString(),
            );
          }
        }
        
        await FirebaseCrashlytics.instance.log(message);
      }
    } catch (e) {
      developer.log(
        'Error al registrar warning: $e',
        name: 'LoggingService',
      );
    }
  }
  
  /// Establece información del usuario para rastreo en Crashlytics
  static Future<void> setUserInfo({
    required String userId,
    String? email,
    String? name,
  }) async {
    try {
      if (!AppConfig.isDevelopment) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
        
        if (email != null) {
          await FirebaseCrashlytics.instance.setCustomKey('user_email', email);
        }
        
        if (name != null) {
          await FirebaseCrashlytics.instance.setCustomKey('user_name', name);
        }
      }
      
      logInfo('Información de usuario configurada para logging', category: 'Auth');
    } catch (e) {
      developer.log(
        'Error al configurar información de usuario: $e',
        name: 'LoggingService',
      );
    }
  }
  
  /// Registra un breadcrumb (rastro de navegación/acciones)
  static Future<void> logBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!AppConfig.isDevelopment) {
        final logMessage = category != null ? '[$category] $message' : message;
        await FirebaseCrashlytics.instance.log(logMessage);
        
        if (data != null) {
          for (final entry in data.entries) {
            await FirebaseCrashlytics.instance.setCustomKey(
              'breadcrumb_${entry.key}', 
              entry.value.toString(),
            );
          }
        }
      }
      
      if (AppConfig.enableDetailedLogs) {
        developer.log(
          'BREADCRUMB: $message',
          name: category ?? 'Navigation',
        );
      }
    } catch (e) {
      developer.log(
        'Error al registrar breadcrumb: $e',
        name: 'LoggingService',
      );
    }
  }
  
  /// Fuerza el envío de un crash de prueba (solo para testing)
  static void forceCrashForTesting() {
    if (AppConfig.isDevelopment) {
      developer.log('⚠️ Forzando crash de prueba para Crashlytics', name: 'LoggingService');
      FirebaseCrashlytics.instance.crash();
    } else {
      logWarning('Intento de forzar crash en producción (ignorado)');
    }
  }
  
  /// Registra eventos de usuario importantes
  static Future<void> logUserEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      logInfo('USER EVENT: $eventName', data: parameters);
      
      if (!AppConfig.isDevelopment && parameters != null) {
        for (final entry in parameters.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            'event_${entry.key}', 
            entry.value.toString(),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error al registrar evento de usuario: $e',
        name: 'LoggingService',
      );
    }
  }
}
