import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
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
        // Log reducido para no saturar arranque
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
      
      if (userCredential?.user == null) {
        developer.log('❌ Google Sign-In cancelado por el usuario');
        return null;
      }

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
          location: existingUser.location, // Preservar ubicación existente
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
      
      final userCredential = await _firebaseService.signUpWithEmail(email, password);
      
      if (userCredential.user == null) {
        developer.log('❌ Error en registro: Usuario no creado');
        return null;
      }

      final firebaseUser = userCredential.user!;
      
      // Actualizar el displayName del usuario
      await firebaseUser.updateDisplayName(name);
      
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
  Future<UserEntity?> verifyPhoneCode(String verificationId, String smsCode, {String? name}) async {
    try {
      developer.log('🚀 Verificando código SMS...');
      
      final userCredential = await _firebaseService.verifyPhoneCode(verificationId, smsCode);
      
      final firebaseUser = userCredential.user!;

      // Si recibimos nombre desde el flujo, actualizar displayName en Auth
      if (name != null && name.trim().isNotEmpty && (firebaseUser.displayName == null || firebaseUser.displayName!.isEmpty)) {
        try {
          await firebaseUser.updateDisplayName(name.trim());
          await firebaseUser.reload();
        } catch (e) {
          developer.log('⚠️ No se pudo actualizar displayName tras verificación de teléfono: $e');
        }
      }
      
      // Verificar si el usuario ya existe en Firestore
      final existingUser = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        developer.log('✅ Usuario autenticado por teléfono: ${existingUser.phoneNumber}');
        // Sincronizar nombre y foto si cambiaron en Auth
        final updatedUser = UserEntity(
          id: existingUser.id,
          name: firebaseUser.displayName ?? existingUser.name,
          email: firebaseUser.email ?? existingUser.email,
          photoUrl: firebaseUser.photoURL ?? existingUser.photoUrl,
          phoneNumber: firebaseUser.phoneNumber ?? existingUser.phoneNumber,
          location: existingUser.location,
          createdAt: existingUser.createdAt,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createOrUpdateUser(updatedUser);
        return updatedUser;
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

  // Método para forzar limpieza completa del estado de autenticación
  @override
  Future<void> forceCompleteSignOut() async {
    try {
      developer.log('🧹 Forzando limpieza completa de autenticación...');
      await _firebaseService.forceCompleteSignOut();
      developer.log('✅ Limpieza completa exitosa');
    } catch (e) {
      developer.log('⚠️ Error en limpieza completa: $e');
      rethrow;
    }
  }

  // Método de diagnóstico
  @override
  void diagnoseAuthState() {
    _firebaseService.diagnoseAuthState();
  }

  // Verificar si el usuario actual es anónimo
  @override
  bool isCurrentUserAnonymous() {
    try {
      final firebaseUser = _firebaseService.getCurrentUser();
      return firebaseUser?.isAnonymous ?? false;
    } catch (e) {
      developer.log('⚠️ Error verificando usuario anónimo: $e');
      return false; // Por seguridad, asumir que no es anónimo
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

  // === AUTENTICACIÓN DE MÚLTIPLES FACTORES (MFA) ===

  @override
  Future<UserEntity?> signInWithEmailAndMFA(String email, String password) async {
    try {
      developer.log('🔐 Iniciando sesión con email y soporte MFA...');
      
      final userCredential = await _firebaseService.signInWithEmailAndMFA(email, password);
      
      final firebaseUser = userCredential.user!;
      
      // Verificar si el usuario ya existe en Firestore
      final existingUser = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        developer.log('✅ Usuario MFA autenticado: ${existingUser.email}');
        return existingUser;
      } else {
        // Usuario nuevo, crear en Firestore
        final newUser = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
        developer.log('✅ Nuevo usuario MFA creado: ${newUser.email}');
        return newUser;
      }
    } catch (e) {
      if (e is MFARequiredException) {
        developer.log('🔐 MFA requerido - lanzando excepción para manejo en UI');
        rethrow; // Permitir que la UI maneje la resolución MFA
      }
      developer.log('⚠️ Error en signInWithEmailAndMFA: $e');
      return null;
    }
  }

  @override
  Future<void> enrollSecondFactor(String phoneNumber) async {
    try {
      developer.log('🔐 Iniciando inscripción de segundo factor...');
      await _firebaseService.enrollSecondFactor(phoneNumber);
      developer.log('✅ Inscripción de segundo factor iniciada');
    } catch (e) {
      developer.log('⚠️ Error al inscribir segundo factor: $e');
      rethrow;
    }
  }

  @override
  Future<void> finalizeSecondFactorEnrollment(String verificationId, String smsCode, String displayName) async {
    try {
      developer.log('🔐 Finalizando inscripción de segundo factor...');
      await _firebaseService.finalizeSecondFactorEnrollment(verificationId, smsCode, displayName);
      developer.log('✅ Segundo factor inscrito exitosamente');
    } catch (e) {
      developer.log('⚠️ Error al finalizar inscripción de segundo factor: $e');
      rethrow;
    }
  }

  @override
  Future<String> sendMFAVerificationCode(MultiFactorResolver resolver, int selectedHintIndex) async {
    try {
      developer.log('🔐 Enviando código de verificación MFA...');
      final verificationId = await _firebaseService.sendMFAVerificationCode(resolver, selectedHintIndex);
      developer.log('✅ Código MFA enviado');
      return verificationId;
    } catch (e) {
      developer.log('⚠️ Error al enviar código MFA: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> resolveMFA(MultiFactorResolver resolver, String verificationId, String smsCode) async {
    try {
      developer.log('🔐 Resolviendo MFA...');
      
      final userCredential = await _firebaseService.resolveMFA(resolver, verificationId, smsCode);
      
      final firebaseUser = userCredential.user!;
      
      // Verificar si el usuario ya existe en Firestore
      final existingUser = await _firestoreService.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        developer.log('✅ MFA resuelto - usuario autenticado: ${existingUser.email}');
        return existingUser;
      } else {
        // Usuario nuevo, crear en Firestore
        final newUser = await _firestoreService.createUserFromFirebaseUser(firebaseUser);
        developer.log('✅ MFA resuelto - nuevo usuario creado: ${newUser.email}');
        return newUser;
      }
    } catch (e) {
      developer.log('⚠️ Error al resolver MFA: $e');
      return null;
    }
  }

  @override
  List<MultiFactorInfo> getEnrolledFactors() {
    return _firebaseService.getEnrolledFactors();
  }

  @override
  Future<void> unenrollFactor(MultiFactorInfo factorInfo) async {
    try {
      developer.log('🔐 Desinscribiendo factor...');
      await _firebaseService.unenrollFactor(factorInfo);
      developer.log('✅ Factor desinscrito exitosamente');
    } catch (e) {
      developer.log('⚠️ Error al desinscribir factor: $e');
      rethrow;
    }
  }

  @override
  bool hasMultiFactorEnabled() {
    return _firebaseService.hasMultiFactorEnabled();
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      developer.log('🗑️ Iniciando proceso de eliminación de cuenta...');
      
      // PASO 1: Eliminar todos los datos del usuario en Firestore
      try {
        await _firestoreService.deleteUserAccount(userId);
        developer.log('✅ Datos de Firestore eliminados correctamente');
      } catch (e) {
        developer.log('⚠️ Error al eliminar datos de Firestore: $e');
        // Continuar con el borrado de Auth aunque falle Firestore parcialmente
      }
      
      // PASO 2: Eliminar la cuenta de Firebase Auth
      try {
        await _firebaseService.deleteUserAccount();
        developer.log('✅ Cuenta de Firebase Auth eliminada');
      } catch (e) {
        developer.log('⚠️ Error al eliminar cuenta de Firebase Auth: $e');
        // Si falla el borrado de Auth, hacer logout forzado
        await _firebaseService.forceCompleteSignOut();
        developer.log('🧹 Logout forzado realizado tras error en borrado de Auth');
      }
      
      // PASO 3: Asegurar logout completo independientemente del resultado anterior
      try {
        await _firebaseService.forceCompleteSignOut();
        developer.log('🧹 Logout completo ejecutado exitosamente');
      } catch (e) {
        developer.log('⚠️ Error en logout final: $e');
      }
      
      developer.log('🎉 Proceso de eliminación de cuenta finalizado');
      
    } catch (e) {
      developer.log('💥 Error crítico durante eliminación de cuenta: $e');
      
      // En caso de error crítico, intentar logout forzado como medida de seguridad
      try {
        await _firebaseService.forceCompleteSignOut();
        developer.log('🧹 Logout de emergencia ejecutado');
      } catch (logoutError) {
        developer.log('❌ Error en logout de emergencia: $logoutError');
      }
      
      rethrow;
    }
  }
}