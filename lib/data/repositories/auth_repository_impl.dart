import 'dart:developer' as developer;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;
  final FirestoreService _firestoreService;

  AuthRepositoryImpl()
      : _firebaseService = FirebaseService(),
        _firestoreService = FirestoreService();

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseService.getCurrentUser();
      
      if (firebaseUser == null) {
        developer.log('📱 No hay usuario autenticado');
        return null;
      }

      // Intentar obtener usuario completo de Firestore
      var userEntity = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (userEntity == null) {
        // Si no existe en Firestore, crear desde Firebase user
        developer.log('📄 Usuario no encontrado en Firestore, creando nuevo registro');
        userEntity = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
      }

      developer.log('✅ Usuario actual obtenido: ${userEntity.email}');
      return userEntity;
    } catch (e) {
      developer.log('⚠️ Error al obtener usuario actual: $e');
      return null;
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      developer.log('🚀 Iniciando Google Sign-In...');
      
      final userCredential = await _firebaseService.signInWithGoogle();
      
      if (userCredential?.user == null && !FirebaseService.isDevelopmentMode) {
        developer.log('❌ Google Sign-In cancelado por el usuario');
        return null;
      }

      // En modo desarrollo, crear usuario mock
      if (FirebaseService.isDevelopmentMode) {
        final mockUser = _firebaseService.getCurrentUser();
        if (mockUser != null) {
          final userEntity = await _firestoreService.createUserFromFirebaseUser(mockUser);
          developer.log('✅ Usuario mock creado: ${userEntity.email}');
          return userEntity;
        }
      }

      // Flujo normal con Firebase
      final firebaseUser = userCredential!.user!;
      
      // Verificar si el usuario ya existe en Firestore
      final existingUser = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        // Usuario existente, actualizar información
        final updatedUser = UserEntity(
          id: existingUser.id,
          name: firebaseUser.displayName ?? existingUser.name,
          email: firebaseUser.email ?? existingUser.email,
          photoUrl: firebaseUser.photoURL ?? existingUser.photoUrl,
          phoneNumber: firebaseUser.phoneNumber ?? existingUser.phoneNumber,
          createdAt: existingUser.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _firestoreService.createOrUpdateUser(updatedUser);
        developer.log('✅ Usuario existente actualizado: ${updatedUser.email}');
        return updatedUser;
      } else {
        // Usuario nuevo, crear en Firestore
        final newUser = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
        developer.log('✅ Nuevo usuario creado: ${newUser.email}');
        return newUser;
      }
    } catch (e) {
      developer.log('⚠️ Error en Google Sign-In: $e');
      return null;
    }
  }

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    try {
      developer.log('🚀 Iniciando sesión con email...');
      
      final userCredential = await _firebaseService.signInWithEmail(email, password);
      
      if (userCredential.user == null && !FirebaseService.isDevelopmentMode) {
        developer.log('❌ Credenciales incorrectas');
        return null;
      }

      // En modo desarrollo, crear usuario mock
      if (FirebaseService.isDevelopmentMode) {
        final mockUser = _firebaseService.getCurrentUser();
        if (mockUser != null) {
          final userEntity = await _firestoreService.createUserFromFirebaseUser(mockUser);
          developer.log('✅ Usuario mock creado: ${userEntity.email}');
          return userEntity;
        }
      }

      // Flujo normal con Firebase
      final firebaseUser = userCredential.user!;
      
      // Verificar si el usuario ya existe en Firestore
      final existingUser = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        developer.log('✅ Usuario autenticado: ${existingUser.email}');
        return existingUser;
      } else {
        // Usuario nuevo, crear en Firestore
        final newUser = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
        developer.log('✅ Nuevo usuario creado: ${newUser.email}');
        return newUser;
      }
    } catch (e) {
      developer.log('⚠️ Error en signInWithEmail: $e');
      return null;
    }
  }

  @override
  Future<UserEntity?> signUpWithEmail(String email, String password, String name) async {
    try {
      developer.log('🚀 Registrando usuario con email...');
      
      final userCredential = await _firebaseService.signUpWithEmail(email, password, name);
      
      if (userCredential.user == null) {
        developer.log('❌ Error en registro: Usuario no creado');
        return null;
      }

      // En modo desarrollo, crear usuario mock
      if (FirebaseService.isDevelopmentMode) {
        final mockUser = _firebaseService.getCurrentUser();
        if (mockUser != null) {
          final userEntity = await _firestoreService.createUserFromFirebaseUser(mockUser);
          developer.log('✅ Usuario mock registrado: ${userEntity.email}');
          return userEntity;
        }
      }

      // Flujo normal con Firebase
      final firebaseUser = userCredential.user!;
      
      // Crear usuario en Firestore
      final newUser = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
      developer.log('✅ Usuario registrado exitosamente: ${newUser.email}');
      return newUser;
    } catch (e) {
      developer.log('⚠️ Error en signUpWithEmail: $e');
      return null;
    }
  }

  @override
  Future<String> signInWithPhone(String phoneNumber) async {
    try {
      developer.log('🚀 Iniciando verificación de teléfono...');
      
      final verificationId = await _firebaseService.signInWithPhone(phoneNumber);
      developer.log('✅ Código SMS enviado al $phoneNumber');
      return verificationId;
    } catch (e) {
      developer.log('⚠️ Error en signInWithPhone: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      developer.log('🚀 Verificando código SMS...');
      
      final userCredential = await _firebaseService.verifyPhoneCode(verificationId, smsCode);
      
      if (userCredential.user == null && !FirebaseService.isDevelopmentMode) {
        developer.log('❌ Código SMS incorrecto');
        return null;
      }

      // En modo desarrollo, crear usuario mock
      if (FirebaseService.isDevelopmentMode) {
        final mockUser = _firebaseService.getCurrentUser();
        if (mockUser != null) {
          final userEntity = await _firestoreService.createUserFromFirebaseUser(mockUser);
          developer.log('✅ Usuario mock verificado: ${userEntity.email}');
          return userEntity;
        }
      }

      // Flujo normal con Firebase
      final firebaseUser = userCredential.user!;
      
      // Verificar si el usuario ya existe en Firestore
      final existingUser = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        developer.log('✅ Usuario autenticado por teléfono: ${existingUser.phoneNumber}');
        return existingUser;
      } else {
        // Usuario nuevo, crear en Firestore
        final newUser = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
        developer.log('✅ Nuevo usuario creado por teléfono: ${newUser.phoneNumber}');
        return newUser;
      }
    } catch (e) {
      developer.log('⚠️ Error en verifyPhoneCode: $e');
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      developer.log('🚀 Enviando email de recuperación...');
      await _firebaseService.sendPasswordResetEmail(email);
      developer.log('✅ Email de recuperación enviado a $email');
    } catch (e) {
      developer.log('⚠️ Error al enviar email de recuperación: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      developer.log('👋 Cerrando sesión...');
      await _firebaseService.signOut();
      developer.log('✅ Sesión cerrada exitosamente');
    } catch (e) {
      developer.log('⚠️ Error al cerrar sesión: $e');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        developer.log('📱 Usuario desautenticado');
        return null;
      }

      try {
        // Obtener usuario completo de Firestore
        var userEntity = await _firestoreService.getUserById(firebaseUser.uid);
        
        userEntity ??= await _firestoreService.createUserFromFirebaseUser(firebaseUser);

        return userEntity;
      } catch (e) {
        developer.log('⚠️ Error en authStateChanges: $e');
        return null;
      }
    });
  }
}
