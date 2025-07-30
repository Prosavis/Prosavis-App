import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';

class FirestoreService {
  static FirebaseFirestore? _firestore;
  static bool _isDevelopmentMode = false;
  static final Map<String, UserModel> _mockUsers = {};

  static void setDevelopmentMode(bool isDev) {
    _isDevelopmentMode = isDev;
    if (!isDev) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  static FirebaseFirestore? get firestore => _isDevelopmentMode ? null : _firestore;

  // === USUARIOS ===

  /// Crear o actualizar usuario en Firestore
  Future<void> createOrUpdateUser(UserEntity user) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Guardando usuario mock');
      _mockUsers[user.id] = UserModel.fromEntity(user);
      return;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final userModel = UserModel.fromEntity(user);
      await _firestore!
          .collection('users')
          .doc(user.id)
          .set(userModel.toJson(), SetOptions(merge: true));
      
      developer.log('✅ Usuario guardado en Firestore: ${user.email}');
    } catch (e) {
      developer.log('⚠️ Error al guardar usuario en Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      _mockUsers[user.id] = UserModel.fromEntity(user);
    }
  }

  /// Obtener usuario por ID
  Future<UserEntity?> getUserById(String userId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Obteniendo usuario mock');
      return _mockUsers[userId];
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final doc = await _firestore!.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        developer.log('📄 Usuario no encontrado en Firestore: $userId');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id; // Asegurar que el ID esté incluido
      
      final userModel = UserModel.fromJson(data);
      developer.log('✅ Usuario obtenido de Firestore: ${userModel.email}');
      
      return userModel;
    } catch (e) {
      developer.log('⚠️ Error al obtener usuario de Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      return _mockUsers[userId];
    }
  }

  /// Obtener usuario por email
  Future<UserEntity?> getUserByEmail(String email) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Buscando usuario mock por email');
      try {
        return _mockUsers.values.firstWhere((user) => user.email == email);
      } catch (e) {
        return null;
      }
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final querySnapshot = await _firestore!
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('📄 Usuario no encontrado por email en Firestore: $email');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Asegurar que el ID esté incluido

      final userModel = UserModel.fromJson(data);
      developer.log('✅ Usuario encontrado por email en Firestore: ${userModel.email}');
      
      return userModel;
    } catch (e) {
      developer.log('⚠️ Error al buscar usuario por email en Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      try {
        return _mockUsers.values.firstWhere((user) => user.email == email);
      } catch (e) {
        return null;
      }
    }
  }

  /// Crear usuario desde FirebaseUser
  Future<UserEntity> createUserFromFirebaseUser(User firebaseUser) async {
    final now = DateTime.now();
    
    final userEntity = UserEntity(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Usuario',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: now,
      updatedAt: now,
    );

    await createOrUpdateUser(userEntity);
    return userEntity;
  }

  /// Eliminar usuario
  Future<void> deleteUser(String userId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Eliminando usuario mock');
      _mockUsers.remove(userId);
      return;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      await _firestore!.collection('users').doc(userId).delete();
      developer.log('✅ Usuario eliminado de Firestore: $userId');
    } catch (e) {
      developer.log('⚠️ Error al eliminar usuario de Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      _mockUsers.remove(userId);
    }
  }

  // === UTILIDADES ===

  /// Verificar conectividad con Firestore
  Future<bool> testConnection() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando conexión exitosa');
      return true;
    }

    try {
      if (_firestore == null) {
        return false;
      }

      // Intentar hacer una consulta simple
      await _firestore!.collection('_test').limit(1).get();
      developer.log('✅ Conexión con Firestore exitosa');
      return true;
    } catch (e) {
      developer.log('⚠️ Error de conectividad con Firestore: $e');
      return false;
    }
  }

  /// Limpiar datos de desarrollo
  static void clearMockData() {
    _mockUsers.clear();
    developer.log('🔧 Datos mock limpiados');
  }

  // === GETTERS ===
  static bool get isDevelopmentMode => _isDevelopmentMode;
  static Map<String, UserModel> get mockUsers => Map.from(_mockUsers);
}