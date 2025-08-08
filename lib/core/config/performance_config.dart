import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';

/// Configuración de rendimiento para la aplicación
class PerformanceConfig {
  
  /// Configurar optimizaciones globales de rendimiento
  static void configurePerformance() {
    if (!kDebugMode) {
      // En release mode, configuraciones específicas para rendimiento
      debugPaintSizeEnabled = false;
    }
    
    // Configurar timings para mejor rendimiento
    SchedulerBinding.instance.addPersistentFrameCallback(_frameCallback);
  }
  
  /// Callback para monitorear frames perdidos
  static void _frameCallback(Duration timeStamp) {
    if (kDebugMode) {
      // Solo en debug mode para evitar overhead en producción
      const frameBudget = Duration(microseconds: 16667); // 60 FPS = 16.67ms por frame
      final lastFrameDuration = SchedulerBinding.instance.currentFrameTimeStamp - timeStamp;
      
      if (lastFrameDuration > frameBudget) {
        debugPrint('⚠️ Frame perdido: ${lastFrameDuration.inMilliseconds}ms');
      }
    }
  }
  
  /// Configuraciones específicas para ListView/GridView
  static const double optimizedCacheExtent = 1000.0;
  static const bool addAutomaticKeepAlives = false;
  static const bool addRepaintBoundaries = true;
  
  /// Configuraciones para carga de imágenes
  static const double defaultImageCacheWidth = 400;
  static const double defaultImageCacheHeight = 400;
  static const double cardImageCacheWidth = 180;
  static const double cardImageCacheHeight = 120;
  
  /// Detener monitoreo de rendimiento
  static void dispose() {
    SchedulerBinding.instance.addPersistentFrameCallback(_frameCallback);
  }
}