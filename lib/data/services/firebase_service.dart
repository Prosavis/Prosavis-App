import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/firebase_options.dart';
import 'dart:developer' as developer;

class FirebaseService {
  // 1) Inicialización de Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Usar GoogleSignIn.instance en lugar de crear nueva instancia
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseService();

  // 2) Método de login con Google - implementación simplificada
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // usuario canceló

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Log del error pero no lanzar excepción para manejar errores gracefully
      developer.log('Error en signInWithGoogle: $e');
      return null;
    }
  }

  // 3) Método de logout
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // 4) Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 5) Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
