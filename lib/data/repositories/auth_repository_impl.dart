import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepositoryImpl(this._firebaseService);

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      
      if (userCredential?.user == null) {
        return null;
      }

      final firebaseUser = userCredential!.user!;
      
      // Verificar si el usuario ya existe en Firestore
      final userDoc = await _firebaseService
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      UserEntity userEntity;

      if (userDoc.exists) {
        // Usuario existente
        userEntity = UserModel.fromJson({
          ...userDoc.data()!,
          'id': firebaseUser.uid,
        });
      } else {
        // Nuevo usuario - crear en Firestore
        userEntity = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          phoneNumber: firebaseUser.phoneNumber,
          userType: UserType.client, // Por defecto cliente
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          bio: null,
          skills: [],
          rating: 0.0,
          reviewCount: 0,
          address: null,
          location: null,
        );

        await createUser(userEntity);
      }

      return userEntity;
    } catch (e) {
      print('❌ Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      print('❌ Error en signOut: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseService.getCurrentUser();
      
      if (firebaseUser == null) {
        return null;
      }

      final userDoc = await _firebaseService
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson({
        ...userDoc.data()!,
        'id': firebaseUser.uid,
      });
    } catch (e) {
      print('❌ Error en getCurrentUser: $e');
      return null;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final userDoc = await _firebaseService
            .collection(AppConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) {
          return null;
        }

        return UserModel.fromJson({
          ...userDoc.data()!,
          'id': firebaseUser.uid,
        });
      } catch (e) {
        print('❌ Error en authStateChanges: $e');
        return null;
      }
    });
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      
      await _firebaseService
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(userModel.toJson());

      return user;
    } catch (e) {
      print('❌ Error en createUser: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(
        user.copyWith(updatedAt: DateTime.now()),
      );
      
      await _firebaseService
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(userModel.toJson());

      return userModel;
    } catch (e) {
      print('❌ Error en updateUser: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseService
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      print('❌ Error en deleteUser: $e');
      rethrow;
    }
  }
} 