import 'package:flutter/material.dart';
import 'logging_service.dart';

/// Servicio para manejo centralizado de errores con UI feedback
class ErrorHandlerService {
  
  /// Maneja errores de operaciones asíncronas con feedback visual al usuario
  static Future<T?> handleAsyncOperation<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? successMessage,
    String? errorMessage,
    String? operationName,
    bool showSuccessSnackBar = false,
    bool logError = true,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final result = await operation();
      
      // Log exitoso de la operación
      if (operationName != null) {
        LoggingService.logInfo(
          'Operación exitosa: $operationName',
          category: 'Operations',
          data: additionalData,
        );
      }
      
      // Mostrar mensaje de éxito si se requiere
      if (showSuccessSnackBar && successMessage != null && context.mounted) {
        _showSnackBar(
          context,
          successMessage,
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      }
      
      return result;
      
    } catch (error, stackTrace) {
      // Log del error
      if (logError) {
        LoggingService.logError(
          error,
          stackTrace,
          reason: operationName != null 
            ? 'Error en operación: $operationName'
            : 'Error en operación asíncrona',
          additionalData: additionalData,
        );
      }
      
      // Mostrar error al usuario
      if (context.mounted) {
        final displayMessage = errorMessage ?? _getDefaultErrorMessage(error);
        _showSnackBar(
          context,
          displayMessage,
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 5),
        );
      }
      
      return null;
    }
  }
  
  /// Maneja errores síncronos con logging
  static void handleSyncError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) {
    LoggingService.logError(
      error,
      StackTrace.current,
      reason: context ?? 'Error síncrono capturado',
      additionalData: additionalData,
      fatal: fatal,
    );
  }
  
  /// Maneja errores de validación de formularios
  static String? handleValidationError(
    String? value,
    List<String Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error.isNotEmpty) {
        LoggingService.logInfo(
          'Error de validación: $error',
          category: 'Validation',
          data: {'field_value_length': value?.length ?? 0},
        );
        return error;
      }
    }
    return null;
  }
  
  /// Envuelve un widget con manejo de errores
  static Widget wrapWithErrorHandling({
    required Widget child,
    String? errorBoundaryName,
  }) {
    return ErrorBoundary(
      child: child,
      onError: (error, stackTrace) {
        LoggingService.logError(
          error,
          stackTrace,
          reason: errorBoundaryName != null
            ? 'Error en boundary: $errorBoundaryName'
            : 'Error capturado por ErrorBoundary',
          fatal: false,
        );
      },
    );
  }
  
  /// Registra eventos de usuario importantes con manejo de errores
  static Future<void> logUserAction(
    String action, {
    Map<String, dynamic>? parameters,
    String? category,
  }) async {
    try {
      await LoggingService.logUserEvent(action, parameters: parameters);
      LoggingService.logBreadcrumb(
        'User action: $action',
        category: category ?? 'UserActions',
        data: parameters,
      );
    } catch (error) {
      LoggingService.logError(
        error,
        StackTrace.current,
        reason: 'Error al registrar acción de usuario',
        additionalData: {
          'action': action,
          'category': category ?? 'unknown',
        },
      );
    }
  }
  
  /// Método privado para mostrar SnackBar con diseño consistente
  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.red,
    IconData icon = Icons.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Genera mensaje de error amigable basado en el tipo de error
  static String _getDefaultErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
    } else if (errorString.contains('permission')) {
      return 'Sin permisos necesarios. Verifica la configuración de la app.';
    } else if (errorString.contains('timeout')) {
      return 'La operación tardó demasiado. Intenta nuevamente.';
    } else if (errorString.contains('firebase') || errorString.contains('auth')) {
      return 'Error del servidor. Intenta nuevamente en unos momentos.';
    } else {
      return 'Ha ocurrido un error inesperado. Intenta nuevamente.';
    }
  }
}

/// Widget ErrorBoundary para capturar errores en widgets
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace)? onError;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Capturar errores en el widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        
        widget.onError?.call(details.exception, details.stack ?? StackTrace.empty);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Algo salió mal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ha ocurrido un error inesperado. Intenta recargar la pantalla.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                });
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}
