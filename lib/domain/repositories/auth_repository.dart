import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity> createUser(UserEntity user);
  Future<UserEntity> updateUser(UserEntity user);
  Future<void> deleteUser(String userId);
} 