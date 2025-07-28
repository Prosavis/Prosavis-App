import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/firebase_options.dart';

class FirebaseService {
  // 1) Inicialización de Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Usar GoogleSignIn.instance en lugar de crear nueva instancia
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  FirebaseService();

  // 2) Método de login con Google - implementación simplificada
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 2.1 Para la nueva API, intentamos authenticate() si está disponible
      GoogleSignInAccount? googleUser;
      
      if (_googleSignIn.supportsAuthenticate()) {
        googleUser = await _googleSignIn.authenticate();
      } else {
        // Fallback para plataformas que no soportan authenticate()
        // Esto podría ser necesario en versiones de transición
        throw UnsupportedError('La plataforma actual no soporta authenticate()');
      }

      if (googleUser == null) return null; // usuario canceló

      // 2.2 Obtener los tokens directamente del usuario autenticado
      // Para Firebase, necesitamos idToken y accessToken
      final scopes = ['email', 'profile'];
      final authorization = await googleUser.authorizationClient.authorizeScopes(scopes);

      // 2.3 Construir credencial de Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: authorization.idToken,
        accessToken: authorization.accessToken,
      );

      // 2.4 Hacer sign-in en Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Log del error pero no lanzar excepción para manejar errores gracefully
      print('Error en signInWithGoogle: $e');
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
