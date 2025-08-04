import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';

class EnrollMFAUseCase {
  final AuthRepository _authRepository;

  const EnrollMFAUseCase(this._authRepository);

  /// Paso 1: Iniciar inscripción de MFA
  Future<void> startEnrollment(String phoneNumber) async {
    return await _authRepository.enrollSecondFactor(phoneNumber);
  }

  /// Paso 2: Completar inscripción con código SMS
  Future<void> completeEnrollment(String verificationId, String smsCode, String displayName) async {
    return await _authRepository.finalizeSecondFactorEnrollment(verificationId, smsCode, displayName);
  }

  /// Obtener factores inscritos
  List<MultiFactorInfo> getEnrolledFactors() {
    return _authRepository.getEnrolledFactors();
  }

  /// Desinscribir un factor
  Future<void> unenrollFactor(MultiFactorInfo factorInfo) async {
    return await _authRepository.unenrollFactor(factorInfo);
  }

  /// Verificar si tiene MFA habilitado
  bool hasMultiFactorEnabled() {
    return _authRepository.hasMultiFactorEnabled();
  }
}