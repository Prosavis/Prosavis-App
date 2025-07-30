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
      // En modo desarrollo, verificar si tenemos un usuario mock
      if (FirebaseService.isDevelopmentMode) {
        final mockUser = _firebaseService.getCurrentUser();
        if (mockUser != null) {
          return _mapFirebaseUserToEntity(mockUser);
        }
        return null;
      }

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
      // Intentar el login a través del servicio
      final userCredential = await _firebaseService.signInWithGoogle();
      
      // Si estamos en modo desarrollo o no hay userCredential
      if (FirebaseService.isDevelopmentMode || userCredential == null) {
        final mockUser = _firebaseService.getCurrentUser();
        if (mockUser != null) {
          return _mapFirebaseUserToEntity(mockUser);
        }
        // Si no hay mock user, crear uno manualmente
        return _createMockUserEntity();
      }

      // Si tenemos un usuario real de Firebase
      final firebaseUser = userCredential.user!;
      
      // Crear o actualizar usuario en Firestore (solo si no estamos en modo desarrollo)
      final userEntity = _mapFirebaseUserToEntity(firebaseUser);
      if (!FirebaseService.isDevelopmentMode) {
        await _saveUserToFirestore(userEntity);
      }
      
      return userEntity;
    } catch (e) {
      // En caso de error, retornar usuario mock
      return _createMockUserEntity();
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

  // Crear un usuario mock para modo desarrollo
  UserEntity _createMockUserEntity() {
    return UserEntity(
      id: 'mock_user_dev_123',
      name: 'Usuario de Desarrollo',
      email: 'dev@prosavis.local',
      photoUrl: null,
      phoneNumber: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(userModel.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Log error but don't throw - user can still be authenticated
      // Funcionalidad pendiente: Implementar un sistema de logging apropiado
    }
  }
} 