import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FirebaseService {
  static bool _isInitialized = false;
  static bool _isDevelopmentMode = false;

  // Inicialización mejorada de Firebase con modo desarrollo
  static Future<void> initializeFirebase() async {
    try {
      // Intentar inicializar Firebase sin opciones específicas por ahora
      await Firebase.initializeApp();
      _isInitialized = true;
      _isDevelopmentMode = false;
      developer.log('✅ Firebase inicializado correctamente');
    } catch (e) {
      developer.log('⚠️ Error al inicializar Firebase, activando modo desarrollo: $e');
      _isDevelopmentMode = true;
      _isInitialized = true;
    }
  }

  final FirebaseAuth? _auth;

  FirebaseService() : _auth = _isDevelopmentMode ? null : FirebaseAuth.instance;

  // Método de login con soporte para modo desarrollo
  Future<UserCredential?> signInAnonymously() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando login anónimo exitoso');
      return null; // En modo desarrollo retornamos null pero manejamos el estado
    }

    try {
      return await _auth?.signInAnonymously();
    } catch (e) {
      developer.log('Error en signInAnonymously: $e');
      return null;
    }
  }

  // Método de logout
  Future<void> signOut() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando logout');
      return;
    }

    try {
      await _auth?.signOut();
    } catch (e) {
      developer.log('Error en signOut: $e');
    }
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Sin usuario actual');
      return null;
    }
    return _auth?.currentUser;
  }

  // Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges {
    if (_isDevelopmentMode) {
      // En modo desarrollo, retornamos un stream que nunca emite usuarios autenticados
      return Stream<User?>.value(null);
    }
    return _auth?.authStateChanges() ?? Stream<User?>.value(null);
  }

  // Google Sign-In con modo desarrollo
  Future<UserCredential?> signInWithGoogle() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Google Sign-In no disponible');
      return null;
    }
    
    developer.log('Google Sign-In no implementado aún - usando signInAnonymously para MVP');
    return await signInAnonymously();
  }

  // Getters para verificar el estado
  static bool get isInitialized => _isInitialized;
  static bool get isDevelopmentMode => _isDevelopmentMode;
}
