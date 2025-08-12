import 'package:firebase_auth/firebase_auth.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<UserEntity?> signUpWithEmail(String email, String password, String name);
  Future<String> signInWithPhone(String phoneNumber);
  Future<UserEntity?> verifyPhoneCode(String verificationId, String smsCode, {String? name});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
  
  // === MÉTODOS DE LIMPIEZA Y DIAGNÓSTICO ===
  Future<void> forceCompleteSignOut();
  void diagnoseAuthState();
  bool isCurrentUserAnonymous();
  
  // === AUTENTICACIÓN DE MÚLTIPLES FACTORES (MFA) ===
  
  /// Iniciar sesión con soporte MFA automático
  Future<UserEntity?> signInWithEmailAndMFA(String email, String password);
  
  /// Inscribir un segundo factor (SMS) para el usuario actual
  Future<void> enrollSecondFactor(String phoneNumber);
  
  /// Completar la inscripción del segundo factor con el código SMS
  Future<void> finalizeSecondFactorEnrollment(String verificationId, String smsCode, String displayName);
  
  /// Enviar código SMS para resolver MFA
  Future<String> sendMFAVerificationCode(MultiFactorResolver resolver, int selectedHintIndex);
  
  /// Resolver MFA con código SMS
  Future<UserEntity?> resolveMFA(MultiFactorResolver resolver, String verificationId, String smsCode);
  
  /// Obtener lista de factores inscritos para el usuario actual
  List<MultiFactorInfo> getEnrolledFactors();
  
  /// Desinscribir un factor específico
  Future<void> unenrollFactor(MultiFactorInfo factorInfo);
  
  /// Verificar si el usuario actual tiene MFA habilitado
  bool hasMultiFactorEnabled();
} 