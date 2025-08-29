import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';

enum AuthErrorType {
  userNotFound,
  wrongPassword,
  emailInUse,
  weakPassword,
  invalidEmail,
  networkError,
  invalidPhoneNumber,
  invalidSmsCode,
  tooManyRequests,
  userDisabled,
  unknown,
}

class AuthErrorInfo {
  final AuthErrorType type;
  final String title;
  final String message;
  final String primaryActionText;
  final String? secondaryActionText;
  final VoidCallback? primaryAction;
  final VoidCallback? secondaryAction;
  final IconData icon;
  final Color iconColor;

  const AuthErrorInfo({
    required this.type,
    required this.title,
    required this.message,
    required this.primaryActionText,
    this.secondaryActionText,
    this.primaryAction,
    this.secondaryAction,
    required this.icon,
    required this.iconColor,
  });
}

class AuthErrorDialog extends StatelessWidget {
  final AuthErrorInfo errorInfo;

  const AuthErrorDialog({
    super.key,
    required this.errorInfo,
  });

  static AuthErrorType _getErrorTypeFromCode(String? errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return AuthErrorType.userNotFound;
      case 'wrong-password':
        return AuthErrorType.wrongPassword;
      case 'email-already-in-use':
        return AuthErrorType.emailInUse;
      case 'weak-password':
        return AuthErrorType.weakPassword;
      case 'invalid-email':
        return AuthErrorType.invalidEmail;
      case 'network-request-failed':
        return AuthErrorType.networkError;
      case 'invalid-phone-number':
        return AuthErrorType.invalidPhoneNumber;
      case 'invalid-verification-code':
        return AuthErrorType.invalidSmsCode;
      case 'too-many-requests':
        return AuthErrorType.tooManyRequests;
      case 'user-disabled':
        return AuthErrorType.userDisabled;
      default:
        return AuthErrorType.unknown;
    }
  }

  static AuthErrorInfo _createErrorInfo(
    AuthErrorType type,
    BuildContext context, {
    String? customMessage,
    bool isSignUp = false,
  }) {
    switch (type) {
      case AuthErrorType.userNotFound:
        return AuthErrorInfo(
          type: type,
          title: 'Cuenta no encontrada',
          message: 'No existe ninguna cuenta registrada con este correo electrónico.',
          icon: Symbols.person_search,
          iconColor: Colors.orange,
          primaryActionText: 'Crear cuenta',
          secondaryActionText: 'Intentar de nuevo',
          primaryAction: () {
            Navigator.of(context).pop();
            context.go('/auth/login?mode=signup');
          },
          secondaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.wrongPassword:
        return AuthErrorInfo(
          type: type,
          title: 'Contraseña incorrecta',
          message: 'La contraseña ingresada no es correcta. Verifica e intenta nuevamente.',
          icon: Symbols.lock_open,
          iconColor: Colors.red,
          primaryActionText: 'Olvidé mi contraseña',
          secondaryActionText: 'Intentar de nuevo',
          primaryAction: () {
            Navigator.of(context).pop();
            context.push('/auth/forgot-password');
          },
          secondaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.emailInUse:
        return AuthErrorInfo(
          type: type,
          title: 'Correo ya registrado',
          message: 'Ya existe una cuenta con este correo electrónico. ¿Quieres iniciar sesión?',
          icon: Symbols.email,
          iconColor: Colors.blue,
          primaryActionText: 'Iniciar sesión',
          secondaryActionText: 'Usar otro correo',
          primaryAction: () {
            Navigator.of(context).pop();
            context.go('/auth/login?mode=signin');
          },
          secondaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.weakPassword:
        return AuthErrorInfo(
          type: type,
          title: 'Contraseña muy débil',
          message: 'La contraseña debe tener al menos 6 caracteres y ser segura.',
          icon: Symbols.security,
          iconColor: Colors.orange,
          primaryActionText: 'Entendido',
          primaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.invalidEmail:
        return AuthErrorInfo(
          type: type,
          title: 'Correo inválido',
          message: 'El formato del correo electrónico no es válido. Verifica e intenta nuevamente.',
          icon: Symbols.email,
          iconColor: Colors.red,
          primaryActionText: 'Entendido',
          primaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.networkError:
        return AuthErrorInfo(
          type: type,
          title: 'Error de conexión',
          message: 'No se pudo conectar al servidor. Verifica tu conexión a internet.',
          icon: Symbols.wifi_off,
          iconColor: Colors.grey,
          primaryActionText: 'Reintentar',
          secondaryActionText: 'Cancelar',
          primaryAction: () => Navigator.of(context).pop(),
          secondaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.invalidPhoneNumber:
        return AuthErrorInfo(
          type: type,
          title: 'Número de teléfono inválido',
          message: 'El número de teléfono ingresado no tiene un formato válido.',
          icon: Symbols.phone_disabled,
          iconColor: Colors.red,
          primaryActionText: 'Entendido',
          primaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.invalidSmsCode:
        return AuthErrorInfo(
          type: type,
          title: 'Código SMS incorrecto',
          message: 'El código de verificación ingresado no es válido o ha expirado.',
          icon: Symbols.sms_failed,
          iconColor: Colors.red,
          primaryActionText: 'Enviar nuevo código',
          secondaryActionText: 'Intentar de nuevo',
          primaryAction: () {
            // Este callback se sobrescribirá cuando se use el dialog
            Navigator.of(context).pop();
          },
          secondaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.tooManyRequests:
        return AuthErrorInfo(
          type: type,
          title: 'Demasiados intentos',
          message: 'Has realizado demasiados intentos. Espera unos minutos antes de intentar nuevamente.',
          icon: Symbols.timer,
          iconColor: Colors.orange,
          primaryActionText: 'Entendido',
          primaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.userDisabled:
        return AuthErrorInfo(
          type: type,
          title: 'Cuenta deshabilitada',
          message: 'Esta cuenta ha sido deshabilitada. Contacta al soporte para más información.',
          icon: Symbols.person_off,
          iconColor: Colors.red,
          primaryActionText: 'Contactar soporte',
          secondaryActionText: 'Entendido',
          primaryAction: () {
            Navigator.of(context).pop();
            // Aquí podrías abrir un enlace de soporte o navegar a una página de contacto
          },
          secondaryAction: () => Navigator.of(context).pop(),
        );

      case AuthErrorType.unknown:
        return AuthErrorInfo(
          type: type,
          title: 'Error inesperado',
          message: customMessage ?? 'Ha ocurrido un error inesperado. Intenta nuevamente.',
          icon: Symbols.error,
          iconColor: Colors.red,
          primaryActionText: 'Entendido',
          primaryAction: () => Navigator.of(context).pop(),
        );
    }
  }

  static void show(
    BuildContext context, {
    required String? errorCode,
    String? customMessage,
    bool isSignUp = false,
    VoidCallback? onResendCode,
  }) {
    final errorType = _getErrorTypeFromCode(errorCode);
    final errorInfo = _createErrorInfo(
      errorType,
      context,
      customMessage: customMessage,
      isSignUp: isSignUp,
    );

    // Si es un error de SMS y tenemos callback de reenvío, lo sobrescribimos
    if (errorType == AuthErrorType.invalidSmsCode && onResendCode != null) {
      final updatedErrorInfo = AuthErrorInfo(
        type: errorInfo.type,
        title: errorInfo.title,
        message: errorInfo.message,
        icon: errorInfo.icon,
        iconColor: errorInfo.iconColor,
        primaryActionText: errorInfo.primaryActionText,
        secondaryActionText: errorInfo.secondaryActionText,
        primaryAction: () {
          Navigator.of(context).pop();
          onResendCode();
        },
        secondaryAction: errorInfo.secondaryAction,
      );
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AuthErrorDialog(errorInfo: updatedErrorInfo),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AuthErrorDialog(errorInfo: errorInfo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: errorInfo.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                errorInfo.icon,
                color: errorInfo.iconColor,
                size: 32,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Título
            Text(
              errorInfo.title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Mensaje
            Text(
              errorInfo.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Column(
              children: [
                // Botón primario
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: errorInfo.primaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      errorInfo.primaryActionText,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // Botón secundario (si existe)
                if (errorInfo.secondaryActionText != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: errorInfo.secondaryAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        errorInfo.secondaryActionText!,
                        style: GoogleFonts.inter(
                          color: AppTheme.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
