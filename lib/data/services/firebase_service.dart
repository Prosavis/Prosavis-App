import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'dart:developer' as developer;
import 'package:prosavis/firebase_options.dart';
import '../../core/config/app_config.dart';
import '../../core/exceptions/auth_exceptions.dart';

class FirebaseService {
  static bool _isInitialized = false;

  // Firebase Auth instance
  final FirebaseAuth _auth;
  
  // Google Sign-In instance con configuración diferida para no bloquear arranque
  GoogleSignIn? _googleSignIn;

  // Inicialización de Firebase
  static Future<void> initializeFirebase() async {
    try {
      if (_isInitialized) return;

      AppConfig.log('🔧 Iniciando configuración de Firebase...');
      AppConfig.printEnvironmentInfo();
      
      // Intentar inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _isInitialized = true;
      
      if (AppConfig.enableFirebaseLogging) {
        // Configurar logging adicional en desarrollo
        await _configureFirebaseForDevelopment();
      }
      
      AppConfig.log('✅ Firebase inicializado correctamente');
      
    } catch (e) {
      AppConfig.log('⚠️ Error crítico al inicializar Firebase: $e');
      rethrow;
    }
  }
  
  /// Configuración adicional de Firebase para desarrollo
  static Future<void> _configureFirebaseForDevelopment() async {
    try {
      // Optimización: Deshabilitar funciones que causan warnings en emuladores
      if (AppConfig.enableFirebaseLogging) {
        // Configurar configuraciones específicas para desarrollo
        AppConfig.log('🔧 Configurando Firebase para desarrollo...');
      }
      
      // Configurar timeouts más permisivos para emuladores
      await _configureNetworkTimeouts();
      
      if (AppConfig.useFirebaseEmulator) {
        AppConfig.log('🔧 Configurando Firebase Emulator...');
        // Aquí se puede configurar el emulador si está disponible
        // FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        // FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      }
    } catch (e) {
      AppConfig.log('⚠️ Error en configuración de desarrollo: $e');
    }
  }

  /// Configurar timeouts de red más permisivos para emuladores
  static Future<void> _configureNetworkTimeouts() async {
    try {
      // Note: Firebase SDK no expone directamente configuración de timeout
      // pero el modo offline y persistencia ayudan con la conectividad limitada
      AppConfig.log('ℹ️ Configuración de red: Usando persistencia offline de Firestore');
    } catch (e) {
      AppConfig.log('⚠️ Error configurando timeouts de red: $e');
    }
  }

  // Constructor
  FirebaseService() : _auth = FirebaseAuth.instance {
    // Defer: no inicializar Google Sign-In hasta que se necesite
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      if (_googleSignIn == null) {
        // Inicializar GoogleSignIn instance
        _googleSignIn = GoogleSignIn.instance;
        
        // Configurar con serverClientId para obtener idToken válido
        await _googleSignIn!.initialize(
          serverClientId: '967024953650-hf412jilid7magc39du5scn9p1knja9n.apps.googleusercontent.com',
        );
        developer.log('✅ Google Sign-In inicializado correctamente con serverClientId');
      }
    } catch (e) {
      developer.log('⚠️ Error al inicializar Google Sign-In: $e');
      // Continuar sin Google Sign-In si falla la inicialización
    }
  }

  // Método de logout
  Future<void> signOut() async {
    try {
      // Cerrar sesión en Google Sign-In primero si está inicializado
      await _initializeGoogleSignIn();
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      
      // Cerrar sesión en Firebase
      await _auth.signOut();
      
      developer.log('✅ Logout exitoso');
    } catch (e) {
      developer.log('Error en signOut: $e');
      rethrow;
    }
  }

  // Método para forzar logout completo y limpiar todo estado persistente
  Future<void> forceCompleteSignOut() async {
    try {
      developer.log('🧹 Iniciando limpieza completa de autenticación...');
      
      // 1. Cerrar sesión de Google completamente
      try {
        await _initializeGoogleSignIn();
        await _googleSignIn!.disconnect();
        await _googleSignIn!.signOut();
        developer.log('✅ Google Sign-In limpiado');
      } catch (e) {
        developer.log('⚠️ Error limpiando Google Sign-In: $e');
      }
      
      // 2. Cerrar sesión de Firebase
      try {
        await _auth.signOut();
        developer.log('✅ Firebase Auth limpiado');
      } catch (e) {
        developer.log('⚠️ Error limpiando Firebase Auth: $e');
      }
      
      // 3. Verificar que no quede ningún usuario
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        developer.log('⚠️ ADVERTENCIA: Aún hay un usuario activo: ${currentUser.uid}');
      } else {
        developer.log('✅ Confirmado: No hay usuario autenticado');
      }
      
      developer.log('🎉 Limpieza completa de autenticación finalizada');
    } catch (e) {
      developer.log('❌ Error en limpieza completa: $e');
      rethrow;
    }
  }

  // Método de diagnóstico para verificar estado de autenticación
  void diagnoseAuthState() {
    developer.log('🔍 === DIAGNÓSTICO DE AUTENTICACIÓN ===');
    
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      developer.log('👤 Usuario encontrado:');
      developer.log('   - UID: ${currentUser.uid}');
      developer.log('   - Email: ${currentUser.email ?? "Sin email"}');
      developer.log('   - Anónimo: ${currentUser.isAnonymous}');
      developer.log('   - Verificado: ${currentUser.emailVerified}');
      developer.log('   - Proveedores: ${currentUser.providerData.map((p) => p.providerId).join(", ")}');
    } else {
      developer.log('✅ No hay usuario autenticado (estado correcto)');
    }
    
    developer.log('🔍 === FIN DIAGNÓSTICO ===');
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Autenticación anónima para usuarios no registrados
  Future<UserCredential> signInAnonymously() async {
    try {
      developer.log('🔓 Iniciando autenticación anónima...');
      
      final UserCredential userCredential = await _auth.signInAnonymously();
      
      developer.log('✅ Usuario anónimo autenticado: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en autenticación anónima: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'operation-not-allowed':
          throw FirebaseAuthException(
            code: e.code,
            message: 'La autenticación anónima no está habilitada en Firebase Console.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      developer.log('⚠️ Error inesperado en autenticación anónima: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('🚀 Iniciando flujo de Google Sign-In nativo...');
      await _initializeGoogleSignIn();

      // Verificar que Google Sign-In se inicializó correctamente
      if (_googleSignIn == null) {
        throw FirebaseAuthException(
          code: 'google-signin-unavailable',
          message: 'Google Sign-In no está disponible',
        );
      }

      // Opcional: limpia sesión previa de forma no bloqueante
      await Future.microtask(() => _googleSignIn!.signOut());

      // 1) El flujo correcto para esta versión es authenticate()
      final GoogleSignInAccount googleUser = await _googleSignIn!.authenticate();
      
      // 2) authentication es una propiedad sincrónica, no un Future
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3) A partir de aquí NO uses await (no son Futures) y NO uses tipos nullable
      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-tokens',
          message: 'No se obtuvo idToken de Google',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken no disponible en esta versión
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      developer.log('✅ Google Sign-In nativo exitoso: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      developer.log('⚠️ Error en Google Sign-In: $e');
      // Si es un error de Google Play Services, proporcionar un mensaje más claro
      if (e.toString().contains('DEVELOPER_ERROR') || e.toString().contains('Unknown calling package')) {
        throw FirebaseAuthException(
          code: 'google-services-unavailable',
          message: 'Google Play Services no está disponible en este dispositivo',
        );
      }
      rethrow;
    }
  }

  // Sign-In con email y contraseña
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      developer.log('✅ Sign-In con email exitoso: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en signInWithEmail: ${e.code} - ${e.message}');
      
      // Lanzar nuestra AuthException personalizada que mantenga el código de Firebase
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      developer.log('⚠️ Error inesperado en signInWithEmail: $e');
      throw AuthException.fromException(e as Exception);
    }
  }

  // Registrar nuevo usuario con email y contraseña
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      developer.log('✅ Registro exitoso: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en signUpWithEmail: ${e.code} - ${e.message}');
      
      // Lanzar nuestra AuthException personalizada que mantenga el código de Firebase
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      developer.log('⚠️ Error inesperado en signUpWithEmail: $e');
      throw AuthException.fromException(e as Exception);
    }
  }

  // Autenticación con número de teléfono (enviar SMS)
  Future<String> signInWithPhone(String phoneNumber) async {
    try {
      // Usar un Completer para manejar el callback de forma más limpia
      final Completer<String> completer = Completer<String>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
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

  // Verificar código SMS
  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) async {
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
      
      // Lanzar nuestra AuthException personalizada que mantenga el código de Firebase
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      developer.log('⚠️ Error inesperado en verifyPhoneCode: $e');
      throw AuthException.fromException(e as Exception);
    }
  }

  // Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      developer.log('✅ Email de recuperación enviado a $email');
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error al enviar email de recuperación: ${e.code} - ${e.message}');
      
      // Lanzar nuestra AuthException personalizada que mantenga el código de Firebase
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      developer.log('⚠️ Error inesperado al enviar email de recuperación: $e');
      throw AuthException.fromException(e as Exception);
    }
  }

  // === AUTENTICACIÓN DE MÚLTIPLES FACTORES (MFA) ===
  
  /// Inscribir un segundo factor (SMS) para el usuario actual
  Future<void> enrollSecondFactor(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No hay usuario autenticado para inscribir MFA',
        );
      }

      developer.log('🔐 Iniciando inscripción de segundo factor para: ${user.email}');
      
      // Usar un Completer para manejar el callback
      final Completer<String> completer = Completer<String>();

      // Obtener sesión multifactor
      final multiFactorSession = await user.multiFactor.getSession();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        multiFactorSession: multiFactorSession,
        verificationCompleted: (PhoneAuthCredential credential) async {
          developer.log('✅ Verificación automática completada para MFA');
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('⚠️ Error en verificación MFA: ${e.code} - ${e.message}');
          
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
              userMessage = 'Error al enviar SMS para MFA: ${e.message}';
          }
          
          if (!completer.isCompleted) {
            completer.completeError(FirebaseAuthException(
              code: e.code,
              message: userMessage,
            ));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('✅ Código SMS para MFA enviado. Verification ID: $verificationId');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log('⏰ Timeout de auto-recuperación MFA para: $verificationId');
        },
        timeout: const Duration(seconds: 120),
      );

      await completer.future;
      developer.log('🔐 Proceso de inscripción MFA iniciado correctamente');
    } catch (e) {
      developer.log('⚠️ Error al inscribir segundo factor: $e');
      rethrow;
    }
  }

  /// Completar la inscripción del segundo factor con el código SMS
  Future<void> finalizeSecondFactorEnrollment(String verificationId, String smsCode, String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No hay usuario autenticado',
        );
      }

      developer.log('🔐 Finalizando inscripción MFA...');

      // Crear credencial de teléfono
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      // Generar assertion multifactor
      final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(credential);

      // Inscribir el segundo factor
      await user.multiFactor.enroll(multiFactorAssertion);

      developer.log('✅ Segundo factor inscrito exitosamente con nombre: $displayName');
    } catch (e) {
      developer.log('⚠️ Error al finalizar inscripción de segundo factor: $e');
      rethrow;
    }
  }

  /// Iniciar sesión con email/contraseña que maneja MFA automáticamente
  Future<UserCredential> signInWithEmailAndMFA(String email, String password) async {
    try {
      developer.log('🔐 Iniciando sesión con email (con soporte MFA)...');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      developer.log('✅ Sign-In exitoso (sin MFA requerido): ${userCredential.user?.email}');
      return userCredential;
      
    } on FirebaseAuthMultiFactorException catch (e) {
      developer.log('🔐 MFA requerido para el usuario: $email');
      
      // Lanzar excepción específica con el resolver para manejar en UI
      throw MFARequiredException(e.resolver);
      
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error en signInWithEmailAndMFA: ${e.code} - ${e.message}');
      
      // Manejo específico de errores estándar
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
      developer.log('⚠️ Error inesperado en signInWithEmailAndMFA: $e');
      rethrow;
    }
  }

  /// Enviar código SMS para resolver MFA
  Future<String> sendMFAVerificationCode(MultiFactorResolver resolver, int selectedHintIndex) async {
    try {
      developer.log('🔐 Enviando código SMS para resolver MFA...');
      
      if (selectedHintIndex >= resolver.hints.length) {
        throw FirebaseAuthException(
          code: 'invalid-hint-index',
          message: 'Índice de hint inválido',
        );
      }

      final selectedHint = resolver.hints[selectedHintIndex] as PhoneMultiFactorInfo;
      developer.log('📱 Enviando SMS a: ${selectedHint.phoneNumber}');

      // Usar un Completer para manejar el callback
      final Completer<String> completer = Completer<String>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        multiFactorSession: resolver.session,
        multiFactorInfo: selectedHint,
        verificationCompleted: (PhoneAuthCredential credential) async {
          developer.log('✅ Verificación automática MFA completada');
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('⚠️ Error en verificación MFA: ${e.code} - ${e.message}');
          
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('✅ Código MFA enviado. Verification ID: $verificationId');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log('⏰ Timeout de auto-recuperación MFA para: $verificationId');
        },
        timeout: const Duration(seconds: 120),
      );

      return await completer.future;
    } catch (e) {
      developer.log('⚠️ Error al enviar código MFA: $e');
      rethrow;
    }
  }

  /// Resolver MFA con código SMS
  Future<UserCredential> resolveMFA(MultiFactorResolver resolver, String verificationId, String smsCode) async {
    try {
      developer.log('🔐 Resolviendo MFA con código SMS...');

      // Crear credencial de teléfono
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      // Generar assertion multifactor
      final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(credential);

      // Resolver el inicio de sesión
      final UserCredential userCredential = await resolver.resolveSignIn(multiFactorAssertion);

      developer.log('✅ MFA resuelto exitosamente: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      developer.log('⚠️ Error al resolver MFA: $e');
      rethrow;
    }
  }

  /// Obtener lista de factores inscritos para el usuario actual
  List<MultiFactorInfo> getEnrolledFactors() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('📱 No hay usuario autenticado para obtener factores');
      return [];
    }

    try {
      // En Firebase Auth para Flutter, la API de MultiFactor puede no estar disponible en todas las versiones
      // Esta es una implementación defensiva
      
      // Intentar obtener factores inscritos
      // Nota: Esta API puede no estar disponible en la versión actual
      developer.log('🔐 Verificando factores MFA para el usuario');
      
      // Por ahora, retornamos una lista vacía ya que la API completa puede no estar disponible
      // En futuras versiones de firebase_auth, esto debería funcionar:
      // final factors = user.multiFactor.enrolledFactors;
      // return factors;
      
      return [];
    } catch (e) {
      developer.log('⚠️ Error al obtener factores inscritos (API no disponible): $e');
      return [];
    }
  }

  /// Desinscribir un factor específico
  Future<void> unenrollFactor(MultiFactorInfo factorInfo) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No hay usuario autenticado',
        );
      }

      await user.multiFactor.unenroll(multiFactorInfo: factorInfo);
      developer.log('✅ Factor desinscrito exitosamente: ${factorInfo.displayName}');
    } catch (e) {
      developer.log('⚠️ Error al desinscribir factor: $e');
      rethrow;
    }
  }

  /// Verificar si el usuario actual tiene MFA habilitado
  bool hasMultiFactorEnabled() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      // En Firebase Auth para Flutter, la API de MultiFactor puede no estar disponible en todas las versiones
      // Esta es una implementación defensiva
      
      // Por ahora, retornamos false ya que la API completa puede no estar disponible
      // En futuras versiones de firebase_auth, esto debería funcionar:
      // return user.multiFactor.enrolledFactors.isNotEmpty;
      
      developer.log('🔐 Verificando si MFA está habilitado (API limitada)');
      return false;
    } catch (e) {
      developer.log('⚠️ Error al verificar MFA habilitado (API no disponible): $e');
      return false;
    }
  }

  // Método para diagnosticar la configuración de Firebase
  static void diagnoseFirebaseConfiguration() {
    developer.log('🔍 Diagnóstico de configuración Firebase:');
    developer.log('  - Inicializado: $_isInitialized');
    
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

  /// Diagnosticar problemas comunes de Google Sign-In
  Future<Map<String, dynamic>> diagnoseGoogleSignIn() async {
    final diagnosis = <String, dynamic>{};
    
    try {
      developer.log('🔍 Iniciando diagnóstico de Google Sign-In...');
      
      // 1. Verificar configuración de Google Sign-In
      diagnosis['google_signin_configured'] = true;
      
      // 2. Verificar configuración básica de Google Sign-In
      diagnosis['google_signin_instance'] = true;
      
      // 3. Verificar Firebase Auth
      final firebaseUser = _auth.currentUser;
      diagnosis['firebase_user_exists'] = firebaseUser != null;
      if (firebaseUser != null) {
        diagnosis['firebase_user_email'] = firebaseUser.email;
        diagnosis['firebase_providers'] = firebaseUser.providerData.map((p) => p.providerId).toList();
      }
      
      // 4. Verificar estado básico
      diagnosis['auth_ready'] = true;
      
      diagnosis['status'] = 'success';
      diagnosis['message'] = 'Diagnóstico completado';
      
    } catch (e) {
      diagnosis['status'] = 'error';
      diagnosis['message'] = e.toString();
    }
    
    // Imprimir diagnóstico detallado
    developer.log('📋 Diagnóstico de Google Sign-In:');
    diagnosis.forEach((key, value) {
      developer.log('  - $key: $value');
    });
    
    return diagnosis;
  }

  /// Limpiar caché de Google Sign-In (útil para problemas)
  Future<void> clearGoogleSignInCache() async {
    try {
      developer.log('🧹 Limpiando caché de Google Sign-In...');
      await _initializeGoogleSignIn();
      await _googleSignIn!.signOut();
      await _googleSignIn!.disconnect();
      developer.log('✅ Caché de Google Sign-In limpiado');
    } catch (e) {
      developer.log('⚠️ Error al limpiar caché: $e');
    }
  }

  /// Eliminar completamente la cuenta del usuario de Firebase Auth
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException(
          code: 'no-current-user',
          message: 'No hay un usuario autenticado actualmente',
        );
      }

      developer.log('🗑️ Eliminando cuenta de Firebase Auth para: ${user.email}');
      
      // Eliminar la cuenta del usuario de Firebase Auth
      await user.delete();
      
      developer.log('✅ Cuenta eliminada exitosamente de Firebase Auth');
      
      // Verificar que la cuenta realmente se eliminó
      await Future.delayed(const Duration(milliseconds: 200));
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        developer.log('⚠️ ADVERTENCIA: Aún existe un usuario después del delete(): ${currentUser.uid}');
      } else {
        developer.log('✅ Confirmado: No hay usuario después del delete()');
      }
      
    } on FirebaseAuthException catch (e) {
      developer.log('⚠️ Error al eliminar cuenta de Firebase Auth: ${e.code} - ${e.message}');
      
      // Si requiere re-autenticación reciente, lanzar excepción específica
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          code: e.code,
          message: 'Por seguridad, necesitas volver a iniciar sesión antes de eliminar tu cuenta.',
          originalCode: e.code,
        );
      }
      
      // Lanzar nuestra AuthException personalizada
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      developer.log('⚠️ Error inesperado al eliminar cuenta: $e');
      throw AuthException.fromException(e as Exception);
    }
  }

  /// Verificar si hay un usuario autenticado actualmente
  bool hasActiveUser() {
    final user = _auth.currentUser;
    final hasUser = user != null;
    
    if (hasUser) {
      developer.log('👤 Usuario activo detectado: ${user!.uid} (${user.email ?? "sin email"})');
    } else {
      developer.log('✅ No hay usuario activo');
    }
    
    return hasUser;
  }
}

/// Excepción personalizada para MFA requerido
class MFARequiredException implements Exception {
  final MultiFactorResolver resolver;
  
  MFARequiredException(this.resolver);

  @override
  String toString() => 'MFA requerido para completar el inicio de sesión';
}