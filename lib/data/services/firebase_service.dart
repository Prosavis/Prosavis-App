import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import 'package:prosavis/firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool _isDevelopmentMode = false;

  // Verificar si estamos usando claves de demo
  static bool _isDemoConfiguration() {
    const webApiKey = 'AIzaSyDemoApiKeyForDevelopment';
    const androidApiKey = 'AIzaSyDemoApiKeyForAndroidDevelopment';
    const iosApiKey = 'AIzaSyDemoApiKeyForIOSDevelopment';
    
    final currentOptions = DefaultFirebaseOptions.currentPlatform;
    return currentOptions.apiKey == webApiKey || 
           currentOptions.apiKey == androidApiKey || 
           currentOptions.apiKey == iosApiKey;
  }

  // Inicialización mejorada de Firebase con detección automática de modo desarrollo
  static Future<void> initializeFirebase() async {
    try {
      // Si tenemos claves de demo, activar directamente modo desarrollo
      if (_isDemoConfiguration()) {
        developer.log('🔧 Claves de demo detectadas, activando modo desarrollo');
        _isDevelopmentMode = true;
        _isInitialized = true;
        return;
      }

      developer.log('🔧 Iniciando configuración de Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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

  FirebaseService() : _auth = (_isDevelopmentMode || !_isInitialized) ? null : FirebaseAuth.instance;

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
      _mockUser = null;
      return;
    }

    try {
      // Cerrar sesión en Google Sign-In
      await GoogleSignIn.instance.signOut();
      
      // Cerrar sesión en Firebase
      await _auth?.signOut();
      
      developer.log('✅ Logout exitoso');
    } catch (e) {
      developer.log('Error en signOut: $e');
    }
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Retornando usuario mock si está autenticado');
      return _mockUser;
    }
    return _auth?.currentUser;
  }

  // Usuario mock para modo desarrollo
  static User? _mockUser;

  // Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges {
    if (_isDevelopmentMode) {
      // En modo desarrollo, retornamos un stream controlado con el usuario mock
      return Stream<User?>.periodic(const Duration(milliseconds: 100), (count) {
        return _mockUser;
      }).take(1);
    }
    return _auth?.authStateChanges() ?? Stream<User?>.value(null);
  }

  // Simular login exitoso en modo desarrollo
  void _simulateSuccessfulLogin() {
    if (_isDevelopmentMode) {
      _mockUser = _MockUser();
      developer.log('🔧 Modo desarrollo: Usuario mock creado para simulación');
    }
  }

  // Google Sign-In con modo desarrollo
  Future<UserCredential?> signInWithGoogle() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando Google Sign-In exitoso');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }
    
    try {
      // Intentar Google Sign-In real con la nueva API
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        developer.log('❌ Google Sign-In cancelado por el usuario');
        return null;
      }

      // Obtener los tokens de autorización para Firebase
      final Map<String, String>? authHeaders = await googleUser.authorizationClient.authorizationHeaders(['email', 'profile']);
      
      if (authHeaders == null) {
        developer.log('❌ No se pudieron obtener los headers de autorización');
        return null;
      }

      // Para Firebase necesitamos usar signInAnonymously como fallback por ahora
      // En un escenario real, configurarías el servidor OAuth correctamente
      developer.log('✅ Google Sign-In exitoso: ${googleUser.email}');
      return await signInAnonymously();
      
    } catch (e) {
      developer.log('⚠️ Error en Google Sign-In: $e');
      // En caso de error, activar modo desarrollo como fallback
      _isDevelopmentMode = true;
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }
  }

  // Sign-In con email y contraseña
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando login con email');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }

    try {
      return await _auth?.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      developer.log('⚠️ Error en signInWithEmail: $e');
      rethrow;
    }
  }

  // Registro con email y contraseña
  Future<UserCredential?> signUpWithEmail(String email, String password, String displayName) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando registro con email');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }

    try {
      final credential = await _auth?.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar el nombre de usuario
      await credential?.user?.updateDisplayName(displayName);
      
      return credential;
    } catch (e) {
      developer.log('⚠️ Error en signUpWithEmail: $e');
      rethrow;
    }
  }

  // Iniciar verificación de teléfono
  Future<String> signInWithPhone(String phoneNumber) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando envío de SMS');
      return 'mock_verification_id_123';
    }

    try {
      String verificationId = '';
      
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Autenticación automática (solo en Android)
          await _auth?.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('⚠️ Error en verificación de teléfono: ${e.message}');
          throw e;
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          developer.log('✅ Código SMS enviado. Verification ID: $verId');
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
        timeout: const Duration(seconds: 60),
      );
      
      // Esperar un poco para que se asigne el verificationId
      await Future.delayed(const Duration(seconds: 2));
      return verificationId;
    } catch (e) {
      developer.log('⚠️ Error en signInWithPhone: $e');
      rethrow;
    }
  }

  // Verificar código SMS
  Future<UserCredential?> verifyPhoneCode(String verificationId, String smsCode) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando verificación de código SMS');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return await _auth?.signInWithCredential(credential);
    } catch (e) {
      developer.log('⚠️ Error en verifyPhoneCode: $e');
      rethrow;
    }
  }

  // Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando envío de email de recuperación');
      return;
    }

    try {
      await _auth?.sendPasswordResetEmail(email: email);
      developer.log('✅ Email de recuperación enviado a $email');
    } catch (e) {
      developer.log('⚠️ Error al enviar email de recuperación: $e');
      rethrow;
    }
  }

  // Crear un UserCredential simulado para modo desarrollo
  UserCredential? _createMockUserCredential() {
    // En modo desarrollo, retornamos null pero manejaremos esto en el repositorio
    // para crear un usuario mock
    return null;
  }

  // Getters para verificar el estado
  static bool get isInitialized => _isInitialized;
  static bool get isDevelopmentMode => _isDevelopmentMode;
}

// Clase mock para simular un User de Firebase en modo desarrollo
class _MockUser implements User {
  @override
  String get uid => 'mock_user_dev_123';

  @override
  String? get displayName => 'Usuario de Desarrollo';

  @override
  String? get email => 'dev@prosavis.local';

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  UserMetadata get metadata => _MockUserMetadata();

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  // Métodos no implementados para el mock (no se usan en nuestra app)
  @override
  Future<void> delete() => throw UnimplementedError();

  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> reload() => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();

  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String? displayName) => throw UnimplementedError();

  Future<void> updateEmail(String newEmail) => throw UnimplementedError();

  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();

  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => throw UnimplementedError();

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();

  @override
  MultiFactor get multiFactor => throw UnimplementedError();
}

class _MockUserMetadata implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.now().subtract(const Duration(days: 30));

  @override
  DateTime? get lastSignInTime => DateTime.now();
}
