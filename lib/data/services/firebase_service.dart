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
  final GoogleSignIn googleSignIn = GoogleSignIn();

  FirebaseService();

  // 2) Método de login con Google
  Future<UserCredential?> signInWithGoogle() async {
    // 2.1 Dispara el flujo de Google Sign‑In
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // usuario canceló

    // 2.2 Obtiene los tokens
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 2.3 Construye credencial de Firebase
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    // 2.4 Hace sign‑in en Firebase
    return await _auth.signInWithCredential(credential);
  }

  // …otros métodos de tu servicio (logout, observables, etc.)
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      googleSignIn.signOut(),
    ]);
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
