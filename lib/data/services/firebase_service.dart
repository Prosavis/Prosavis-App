import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import 'package:prosavis/firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool _isDevelopmentMode = false;

  // Firebase Auth instance
  final FirebaseAuth _auth;
  
  // Google Sign-In instance con configuración mejorada
  late final GoogleSignIn _googleSignIn;

  // Inicialización de Firebase
  static Future<void> initializeFirebase() async {
    try {
      if (_isInitialized) return;

      developer.log('🔧 Iniciando configuración de Firebase...');
      
      // Intentar inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _isInitialized = true;
      _isDevelopmentMode = false;
      developer.log('✅ Firebase inicializado correctamente');
      
    } catch (e) {
      developer.log('⚠️ Error al inicializar Firebase: $e');
      _isInitialized = true;
      _isDevelopmentMode = true;
      
      developer.log('🔧 Activando modo desarrollo - Firebase no disponible');
      developer.log('📝 En modo desarrollo: datos se guardarán localmente');
      
      // No relanzar el error, continuar en modo desarrollo
    }
  }

  // Constructor con inicialización de servicios
  FirebaseService() : _auth = FirebaseAuth.instance {
    _initializeGoogleSignIn();
  }

  // Inicializar Google Sign-In con configuración específica del proyecto
  void _initializeGoogleSignIn() {
    // Usar la instancia singleton de GoogleSignIn
    _googleSignIn = GoogleSignIn.instance;
  }

  // Método de logout
  Future<void> signOut() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando logout');
      _mockUser = null;
      return;
    }

    try {
      // Cerrar sesión en Google Sign-In primero
      await _googleSignIn.signOut();
      
      // Cerrar sesión en Firebase
      await _auth.signOut();
      
      developer.log('✅ Logout exitoso');
    } catch (e) {
      developer.log('Error en signOut: $e');
      rethrow;
    }
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Retornando usuario mock si está autenticado');
      return _mockUser;
    }
    return _auth.currentUser;
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
    return _auth.authStateChanges();
  }

  // Simular login exitoso en modo desarrollo
  void _simulateSuccessfulLogin() {
    if (_isDevelopmentMode) {
      _mockUser = _MockUser();
      developer.log('🔧 Modo desarrollo: Usuario mock creado para simulación');
    }
  }

  // Google Sign-In con implementación correcta para Firebase 2025 y google_sign_in 7.x
  Future<UserCredential?> signInWithGoogle() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando Google Sign-In exitoso');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }
    
    try {
      developer.log('🚀 Iniciando flujo de Google Sign-In...');
      
      // Verificar si la plataforma soporta authenticate
      if (!_googleSignIn.supportsAuthenticate()) {
        developer.log('❌ La plataforma actual no soporta authenticate()');
        throw FirebaseAuthException(
          code: 'unsupported-platform',
          message: 'Google Sign-In no está soportado en esta plataforma',
        );
      }
      
      // Iniciar el flujo de Google Sign-In con authenticate (API 7.x)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      developer.log('✅ Usuario de Google autenticado: ${googleUser.email}');

      // Obtener idToken de la autenticación básica
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        developer.log('❌ No se pudo obtener el idToken de Google');
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'No se pudo obtener el idToken de Google',
        );
      }

      // Obtener autorización para los scopes básicos de Firebase para accessToken
      const List<String> firebaseScopes = ['openid', 'email', 'profile'];
      final authorization = await googleUser.authorizationClient.authorizationForScopes(firebaseScopes);
      
      if (authorization == null) {
        developer.log('❌ No se pudo obtener autorización para los scopes necesarios');
        throw FirebaseAuthException(
          code: 'missing-authorization',
          message: 'No se pudo obtener autorización de Google',
        );
      }

      // Verificar que tenemos el accessToken
      if (authorization.accessToken.isEmpty) {
        developer.log('❌ No se pudo obtener el accessToken de Google');
        throw FirebaseAuthException(
          code: 'missing-access-token',
          message: 'No se pudo obtener el accessToken de Google',
        );
      }

      developer.log('✅ Tokens de Google obtenidos correctamente');

      // Crear credencial de Firebase con los tokens de Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('🔐 Iniciando sesión en Firebase con credencial de Google...');

      // Iniciar sesión en Firebase con la credencial de Google
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      developer.log('✅ Google Sign-In exitoso: ${userCredential.user?.email}');
      return userCredential;
      
    } catch (e) {
      developer.log('⚠️ Error en Google Sign-In: $e');
      
      // Manejar errores específicos
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            developer.log('❌ Ya existe una cuenta con este email usando un método diferente');
            break;
          case 'invalid-credential':
            developer.log('❌ Credenciales de Google inválidas');
            break;
          case 'operation-not-allowed':
            developer.log('❌ Google Sign-In no está habilitado en Firebase Console');
            break;
          case 'user-disabled':
            developer.log('❌ Esta cuenta ha sido deshabilitada');
            break;
          case 'unsupported-platform':
            developer.log('❌ Plataforma no soportada para Google Sign-In');
            break;
          case 'missing-id-token':
            developer.log('❌ Fallo al obtener idToken de Google');
            break;
          case 'missing-authorization':
            developer.log('❌ Fallo en la autorización de Google');
            break;
          case 'missing-access-token':
            developer.log('❌ Fallo al obtener accessToken de Google');
            break;
          default:
            developer.log('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
        }
      }
      
      rethrow;
    }
  }

  // Sign-In con email y contraseña
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando login con email');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      developer.log('✅ Sign-In con email exitoso: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en signInWithEmail: ${e.code} - ${e.message}');
      
      // Manejo específico de errores de Firebase Auth
      switch (e.code) {
        case 'user-not-found':
          throw FirebaseAuthException(
            code: e.code,
            message: 'No hay ningún usuario registrado con este correo electrónico.',
          );
        case 'wrong-password':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Contraseña incorrecta.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El formato del correo electrónico no es válido.',
          );
        case 'user-disabled':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Esta cuenta de usuario ha sido deshabilitada.',
          );
        case 'too-many-requests':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Demasiados intentos fallidos. Intenta de nuevo más tarde.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      developer.log('⚠️ Error inesperado en signInWithEmail: $e');
      rethrow;
    }
  }

  // Registro con email y contraseña
  Future<UserCredential> signUpWithEmail(String email, String password, String displayName) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando registro con email');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }

    try {
      developer.log('🔐 Intentando crear usuario con Firebase Auth...');
      
      // Crear el usuario con email y contraseña
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      developer.log('✅ Usuario creado exitosamente en Firebase');
      
      // Actualizar el perfil del usuario con el nombre
      await userCredential.user?.updateDisplayName(displayName.trim());
      
      // Recargar el usuario para obtener la información actualizada
      await userCredential.user?.reload();
      
      developer.log('✅ Registro con email exitoso: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en signUpWithEmail: ${e.code} - ${e.message}');
      
      // Manejo específico de errores de Firebase Auth
      switch (e.code) {
        case 'email-already-in-use':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Ya existe una cuenta con este correo electrónico.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El formato del correo electrónico no es válido.',
          );
        case 'operation-not-allowed':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El registro con email/contraseña no está habilitado.',
          );
        case 'weak-password':
          throw FirebaseAuthException(
            code: e.code,
            message: 'La contraseña debe tener al menos 6 caracteres.',
          );
        case 'too-many-requests':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Demasiados intentos de registro. Intenta de nuevo más tarde.',
          );
        case 'network-request-failed':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Error de conexión. Verifica tu conexión a internet.',
          );
        default:
          developer.log('⚠️ Error no manejado específicamente: ${e.code}');
          rethrow;
      }
    } catch (e) {
      developer.log('⚠️ Error inesperado en signUpWithEmail: $e');
      rethrow;
    }
  }

  // Iniciar verificación de teléfono con implementación mejorada
  Future<String> signInWithPhone(String phoneNumber) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando envío de SMS');
      return 'mock_verification_id_123';
    }

    try {
      // Validar formato del número de teléfono
      final cleanPhoneNumber = phoneNumber.startsWith('+') 
          ? phoneNumber 
          : '+57$phoneNumber'; // Agregar código de Colombia si no está presente

      final completer = Completer<String>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: cleanPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            // Autenticación automática (principalmente en Android)
            await _auth.signInWithCredential(credential);
            developer.log('✅ Autenticación automática completada');
          } catch (e) {
            developer.log('⚠️ Error en autenticación automática: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('⚠️ Error en verificación de teléfono: ${e.code} - ${e.message}');
          
          String userMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              userMessage = 'El número de teléfono no es válido.';
              break;
            case 'too-many-requests':
              userMessage = 'Demasiados intentos. Intenta más tarde.';
              break;
            case 'quota-exceeded':
              userMessage = 'Se ha excedido la cuota de SMS.';
              break;
            default:
              userMessage = 'Error al enviar SMS: ${e.message}';
          }
          
          if (!completer.isCompleted) {
            completer.completeError(FirebaseAuthException(
              code: e.code,
              message: userMessage,
            ));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('✅ Código SMS enviado. Verification ID: $verificationId');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log('⏰ Timeout de auto-recuperación para: $verificationId');
          // No completamos el completer aquí, solo lo registramos
        },
        timeout: const Duration(seconds: 120), // Tiempo extendido
      );
      
      return await completer.future;
    } catch (e) {
      developer.log('⚠️ Error en signInWithPhone: $e');
      rethrow;
    }
  }

  // Verificar código SMS con manejo mejorado de errores
  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando verificación de código SMS');
      _simulateSuccessfulLogin();
      return _createMockUserCredential();
    }

    try {
      // Crear credencial con el código de verificación
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      // Iniciar sesión con la credencial
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      developer.log('✅ Verificación de teléfono exitosa: ${userCredential.user?.phoneNumber}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en verifyPhoneCode: ${e.code} - ${e.message}');
      
      // Manejo específico de errores
      switch (e.code) {
        case 'invalid-verification-code':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El código de verificación es incorrecto.',
          );
        case 'invalid-verification-id':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El ID de verificación no es válido.',
          );
        case 'session-expired':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El código ha expirado. Solicita uno nuevo.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      developer.log('⚠️ Error inesperado en verifyPhoneCode: $e');
      rethrow;
    }
  }

  // Enviar email de recuperación de contraseña con manejo mejorado
  Future<void> sendPasswordResetEmail(String email) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando envío de email de recuperación');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      developer.log('✅ Email de recuperación enviado a $email');
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error al enviar email de recuperación: ${e.code} - ${e.message}');
      
      // Manejo específico de errores
      switch (e.code) {
        case 'user-not-found':
          throw FirebaseAuthException(
            code: e.code,
            message: 'No hay ningún usuario registrado con este correo electrónico.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: e.code,
            message: 'El formato del correo electrónico no es válido.',
          );
        case 'too-many-requests':
          throw FirebaseAuthException(
            code: e.code,
            message: 'Demasiadas solicitudes. Intenta de nuevo más tarde.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      developer.log('⚠️ Error inesperado al enviar email de recuperación: $e');
      rethrow;
    }
  }

  // Crear un UserCredential simulado para modo desarrollo
  UserCredential _createMockUserCredential() {
    return _MockUserCredential();
  }

  // Método para diagnosticar la configuración de Firebase
  static void diagnoseFirebaseConfiguration() {
    developer.log('🔍 Diagnóstico de configuración Firebase:');
    developer.log('  - Inicializado: $_isInitialized');
    developer.log('  - Modo desarrollo: $_isDevelopmentMode');
    
    try {
      final app = Firebase.app();
      developer.log('  - App ID: ${app.options.appId}');
      developer.log('  - Project ID: ${app.options.projectId}');
      developer.log('  - API Key: ${app.options.apiKey.substring(0, 10)}...');
    } catch (e) {
      developer.log('  - Error obteniendo configuración: $e');
    }
  }

  // Getters para verificar el estado
  static bool get isInitialized => _isInitialized;
  static bool get isDevelopmentMode => _isDevelopmentMode;
}

// Clase mock para simular un UserCredential de Firebase en modo desarrollo
class _MockUserCredential implements UserCredential {
  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;

  @override
  User get user => _MockUser();
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
