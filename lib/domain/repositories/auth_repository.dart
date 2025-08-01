import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<UserEntity?> signUpWithEmail(String email, String password, String name);
  Future<String> signInWithPhone(String phoneNumber);
  Future<UserEntity?> verifyPhoneCode(String verificationId, String smsCode);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
} 