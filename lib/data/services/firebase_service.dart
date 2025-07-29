import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FirebaseService {
  // 1) Inicialización de Firebase - simplificada para MVP
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService();

  // 2) Método de login simplificado para MVP - sin Google Sign-In por ahora
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      developer.log('Error en signInAnonymously: $e');
      return null;
    }
  }

  // 3) Método de logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      developer.log('Error en signOut: $e');
    }
  }

  // 4) Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 5) Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // TODO: Implementar Google Sign-In cuando se configure correctamente
  Future<UserCredential?> signInWithGoogle() async {
    developer.log('Google Sign-In no implementado aún - usando signInAnonymously para MVP');
    return await signInAnonymously();
  }
}
