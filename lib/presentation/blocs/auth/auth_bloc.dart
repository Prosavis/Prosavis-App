import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/auth/sign_in_with_google_usecase.dart';
import '../../../domain/usecases/auth/sign_in_with_email_usecase.dart';
import '../../../domain/usecases/auth/sign_up_with_email_usecase.dart';
import '../../../domain/usecases/auth/sign_in_with_phone_usecase.dart';
import '../../../domain/usecases/auth/verify_phone_code_usecase.dart';
import '../../../domain/usecases/auth/password_reset_usecase.dart';
import '../../../domain/usecases/auth/delete_account_usecase.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/exceptions/auth_exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../core/config/app_config.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithPhoneUseCase _signInWithPhoneUseCase;
  final VerifyPhoneCodeUseCase _verifyPhoneCodeUseCase;
  final PasswordResetUseCase _passwordResetUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithEmailUseCase signInWithEmailUseCase,
    required SignUpWithEmailUseCase signUpWithEmailUseCase,
    required SignInWithPhoneUseCase signInWithPhoneUseCase,
    required VerifyPhoneCodeUseCase verifyPhoneCodeUseCase,
    required PasswordResetUseCase passwordResetUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
  })  : _authRepository = authRepository,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _signInWithEmailUseCase = signInWithEmailUseCase,
        _signUpWithEmailUseCase = signUpWithEmailUseCase,
        _signInWithPhoneUseCase = signInWithPhoneUseCase,
        _verifyPhoneCodeUseCase = verifyPhoneCodeUseCase,
        _passwordResetUseCase = passwordResetUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        super(AuthInitial()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithGoogleRequested>(_onAuthSignInWithGoogleRequested);
    on<AuthSignInWithEmailRequested>(_onAuthSignInWithEmailRequested);
    on<AuthSignUpWithEmailRequested>(_onAuthSignUpWithEmailRequested);
    on<AuthSignInWithPhoneRequested>(_onAuthSignInWithPhoneRequested);
    on<AuthVerifyPhoneCodeRequested>(_onAuthVerifyPhoneCodeRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthUserUpdated>(_onAuthUserUpdated);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    // 🔍 DIAGNÓSTICO: Verificar estado de autenticación al inicio
    // Reducir verbosidad: diagnóstico solo si está habilitado
    try {
      // ignore: deprecated_member_use_from_same_package
      if (AppConfig.enableDetailedLogs) {
        developer.log('🚀 === INICIANDO AUTHBLOC ===');
        _authRepository.diagnoseAuthState();
      }
    } catch (_) {}
    
    // Escuchar cambios en el estado de autenticación
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
    
    // Verificar si hay un usuario actual - RESPETANDO PERSISTENCIA NATURAL
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        if (AppConfig.enableDetailedLogs) {
          developer.log('👤 Usuario persistente encontrado:');
          developer.log('   - ID: ${currentUser.id}');
          developer.log('   - Email: ${currentUser.email}');
          developer.log('   - Nombre: ${currentUser.name}');
        }
        
        // 🔍 VERIFICACIÓN ESPECIAL: Limpiar solo usuarios anónimos de pruebas anteriores
        await _checkAndCleanAnonymousUser(currentUser, emit);
      } else {
        if (AppConfig.enableDetailedLogs) developer.log('📱 No hay usuario autenticado - Iniciando navegación pública');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      developer.log('❌ Error al verificar autenticación inicial: $e');
      emit(AuthError('Error al verificar autenticación: $e'));
    }
    
    if (AppConfig.enableDetailedLogs) developer.log('🎯 === AUTHBLOC INICIADO ===');
  }

  Future<void> _onAuthSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final user = await _signInWithGoogleUseCase(NoParams());
      
      if (user != null) {
        emit(AuthAuthenticated(user, isRecentLogin: true));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error al iniciar sesión con Google: $e'));
    }
  }

  Future<void> _onAuthSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final user = await _signInWithEmailUseCase(
        SignInWithEmailParams(email: event.email, password: event.password),
      );
      
      if (user != null) {
        emit(AuthAuthenticated(user, isRecentLogin: true));
      } else {
        emit(const AuthError('Credenciales incorrectas. Verifica tu email y contraseña.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message, errorCode: e.code, isSignUp: false));
    } catch (e) {
      emit(AuthError('Error inesperado al iniciar sesión: $e'));
    }
  }

  Future<void> _onAuthSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final user = await _signUpWithEmailUseCase(
        SignUpWithEmailParams(
          email: event.email,
          password: event.password,
          name: event.name,
        ),
      );
      
      if (user != null) {
        emit(AuthAuthenticated(user, isRecentLogin: true));
      } else {
        emit(const AuthError('Error al crear la cuenta. Intenta nuevamente.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message, errorCode: e.code, isSignUp: true));
    } catch (e) {
      emit(AuthError('Error inesperado al registrarse: $e'));
    }
  }

  Future<void> _onAuthSignInWithPhoneRequested(
    AuthSignInWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final verificationId = await _signInWithPhoneUseCase(
        SignInWithPhoneParams(phoneNumber: event.phoneNumber),
      );
      
      emit(AuthPhoneCodeSent(
        verificationId: verificationId,
        phoneNumber: event.phoneNumber,
      ));
    } on AuthException catch (e) {
      emit(AuthError(e.message, errorCode: e.code, isSignUp: false));
    } catch (e) {
      emit(AuthError('Error inesperado al enviar código SMS: $e'));
    }
  }

  Future<void> _onAuthVerifyPhoneCodeRequested(
    AuthVerifyPhoneCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final user = await _verifyPhoneCodeUseCase(
        VerifyPhoneCodeParams(
          verificationId: event.verificationId,
          smsCode: event.smsCode,
          name: event.name,
        ),
      );
      
      if (user != null) {
        emit(AuthAuthenticated(user, isRecentLogin: true));
      } else {
        emit(const AuthError('Código SMS incorrecto. Verifica e intenta nuevamente.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message, errorCode: e.code, isSignUp: false));
    } catch (e) {
      emit(AuthError('Error inesperado al verificar código: $e'));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      await _passwordResetUseCase(
        PasswordResetParams(email: event.email),
      );
      
      emit(AuthPasswordResetSent(email: event.email));
    } on AuthException catch (e) {
      emit(AuthError(e.message, errorCode: e.code, isSignUp: false));
    } catch (e) {
      emit(AuthError('Error inesperado al enviar email de recuperación: $e'));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      await _authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Error al cerrar sesión: $e'));
    }
  }

  void _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  void _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(event.user));
  }

  /// Verificación inteligente: limpiar solo usuarios anónimos, mantener usuarios reales
  Future<void> _checkAndCleanAnonymousUser(dynamic currentUser, Emitter<AuthState> emit) async {
    try {
      // Verificar si el usuario actual es anónimo usando el repositorio
      final isAnonymous = _authRepository.isCurrentUserAnonymous();
      
      if (isAnonymous) {
        developer.log('🧹 USUARIO ANÓNIMO DETECTADO - Limpiando para evitar confusión...');
        developer.log('   Este usuario anónimo probablemente es de pruebas anteriores.');
        developer.log('   Los usuarios anónimos no son parte del flujo normal de la app.');
        await _authRepository.forceCompleteSignOut();
        emit(AuthUnauthenticated());
        developer.log('✅ Usuario anónimo limpiado - Navegación pública habilitada');
      } else {
        developer.log('✅ Usuario real encontrado - Manteniendo sesión persistente');
        developer.log('   Este es un usuario legítimo que debemos mantener logueado.');
        emit(AuthAuthenticated(currentUser));
        developer.log('🎉 Sesión de usuario real restaurada correctamente');
      }
    } catch (e) {
      developer.log('⚠️ Error en verificación de usuario: $e');
      // En caso de error, mantener la sesión por seguridad (favorecer al usuario)
      developer.log('   Manteniendo sesión por precaución...');
      emit(AuthAuthenticated(currentUser));
    }
  }

  Future<void> _onAuthDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      await _deleteAccountUseCase(
        DeleteAccountParams(userId: event.userId),
      );
      
      // Después de eliminar la cuenta, el usuario debe estar desautenticado
      emit(AuthUnauthenticated());
      
      developer.log('✅ Cuenta eliminada exitosamente - Estado: No autenticado');
      
      // Verificar que realmente no hay usuario autenticado
      await Future.delayed(const Duration(milliseconds: 500));
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        developer.log('⚠️ ADVERTENCIA: Aún hay usuario autenticado tras borrado: ${currentUser.id}');
        // Forzar logout adicional si es necesario
        try {
          await _authRepository.signOut();
          emit(AuthUnauthenticated());
          developer.log('🧹 Logout adicional ejecutado exitosamente');
        } catch (e) {
          developer.log('⚠️ Error en logout adicional: $e');
        }
      } else {
        developer.log('✅ Confirmado: No hay usuario autenticado');
      }
      
    } on AuthException catch (e) {
      developer.log('❌ Error de autenticación al eliminar cuenta: ${e.message}');
      emit(AuthError(e.message, errorCode: e.code, isSignUp: false));
    } catch (e) {
      developer.log('❌ Error inesperado al eliminar cuenta: $e');
      emit(AuthError('Error inesperado al eliminar cuenta: $e'));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
} 