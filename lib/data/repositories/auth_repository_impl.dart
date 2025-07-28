import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepositoryImpl(this._firebaseService);

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseService.getCurrentUser();
      if (firebaseUser == null) return null;

      return _mapFirebaseUserToEntity(firebaseUser);
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      if (userCredential?.user == null) return null;

      final firebaseUser = userCredential!.user!;
      
      // Crear o actualizar usuario en Firestore
      final userEntity = _mapFirebaseUserToEntity(firebaseUser);
      await _saveUserToFirestore(userEntity);
      
      return userEntity;
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseService.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToEntity(firebaseUser);
    });
  }

  UserEntity _mapFirebaseUserToEntity(User firebaseUser) {
    return UserEntity(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveUserToFirestore(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _firebaseService
          .collection('users')
          .doc(user.id)
          .set(userModel.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Log error but don't throw - user can still be authenticated
      print('Error al guardar usuario en Firestore: $e');
    }
  }
} 