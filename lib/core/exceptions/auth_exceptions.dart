import 'package:firebase_auth/firebase_auth.dart';

/// Excepción personalizada para manejar errores de autenticación
/// con información adicional para mostrar en la UI
class AuthException implements Exception {
  final String code;
  final String message;
  final String? originalCode;

  const AuthException({
    required this.code,
    required this.message,
    this.originalCode,
  });

  /// Crear AuthException desde FirebaseAuthException
  factory AuthException.fromFirebaseAuthException(FirebaseAuthException e) {
    return AuthException(
      code: e.code,
      message: e.message ?? 'Error de autenticación desconocido',
      originalCode: e.code,
    );
  }

  /// Crear AuthException desde cualquier otra excepción
  factory AuthException.fromException(Exception e, {String? customCode}) {
    return AuthException(
      code: customCode ?? 'unknown-error',
      message: e.toString(),
    );
  }

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Excepción específica para cuando se requiere MFA
class MFARequiredException implements Exception {
  final MultiFactorResolver resolver;

  const MFARequiredException(this.resolver);

  @override
  String toString() => 'MFARequiredException: Multi-factor authentication required';
}
