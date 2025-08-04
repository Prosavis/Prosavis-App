import 'package:firebase_auth/firebase_auth.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/services/firebase_service.dart';

class SignInWithMFAUseCase {
  final AuthRepository _authRepository;

  const SignInWithMFAUseCase(this._authRepository);

  /// Iniciar sesión con email/password que puede requerir MFA
  Future<SignInMFAResult> signIn(String email, String password) async {
    try {
      final user = await _authRepository.signInWithEmailAndMFA(email, password);
      
      if (user != null) {
        return SignInMFAResult.success(user);
      } else {
        return const SignInMFAResult.error('Error desconocido al iniciar sesión');
      }
    } on MFARequiredException catch (e) {
      // MFA requerido - devolver resolver para continuar en UI
      return SignInMFAResult.mfaRequired(e.resolver);
    } catch (e) {
      return SignInMFAResult.error(e.toString());
    }
  }

  /// Enviar código MFA
  Future<String> sendMFACode(MultiFactorResolver resolver, int selectedHintIndex) async {
    return await _authRepository.sendMFAVerificationCode(resolver, selectedHintIndex);
  }

  /// Resolver MFA con código SMS
  Future<UserEntity?> resolveMFA(MultiFactorResolver resolver, String verificationId, String smsCode) async {
    return await _authRepository.resolveMFA(resolver, verificationId, smsCode);
  }
}

/// Resultado del intento de inicio de sesión con MFA
sealed class SignInMFAResult {
  const SignInMFAResult();

  /// Inicio de sesión exitoso sin MFA
  const factory SignInMFAResult.success(UserEntity user) = SignInMFASuccess;

  /// MFA requerido para completar el inicio de sesión
  const factory SignInMFAResult.mfaRequired(MultiFactorResolver resolver) = SignInMFARequired;

  /// Error en el inicio de sesión
  const factory SignInMFAResult.error(String message) = SignInMFAError;
}

class SignInMFASuccess extends SignInMFAResult {
  final UserEntity user;
  const SignInMFASuccess(this.user);
}

class SignInMFARequired extends SignInMFAResult {
  final MultiFactorResolver resolver;
  const SignInMFARequired(this.resolver);
}

class SignInMFAError extends SignInMFAResult {
  final String message;
  const SignInMFAError(this.message);
}