import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late FirebaseApp _app;
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late GoogleSignIn _googleSignIn;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  GoogleSignIn get googleSignIn => _googleSignIn;

  // Initialize Firebase
  Future<void> initializeFirebase() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      
      _app = await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        ),
      );

      _auth = FirebaseAuth.instanceFor(app: _app);
      _firestore = FirebaseFirestore.instanceFor(app: _app);
      
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );

      // Configure Firestore settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint('✅ Firebase inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // El usuario canceló el inicio de sesión
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('❌ Error en Google Sign In: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore operations
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  // Batch operations
  WriteBatch batch() {
    return _firestore.batch();
  }

  // Transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) {
    return _firestore.runTransaction(updateFunction);
  }
}
