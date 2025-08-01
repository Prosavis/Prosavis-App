import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/auth/sign_in_with_google_usecase.dart';
import '../../../domain/usecases/auth/sign_in_with_email_usecase.dart';
import '../../../domain/usecases/auth/sign_up_with_email_usecase.dart';
import '../../../domain/usecases/auth/sign_in_with_phone_usecase.dart';
import '../../../domain/usecases/auth/verify_phone_code_usecase.dart';
import '../../../domain/usecases/auth/password_reset_usecase.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithPhoneUseCase _signInWithPhoneUseCase;
  final VerifyPhoneCodeUseCase _verifyPhoneCodeUseCase;
  final PasswordResetUseCase _passwordResetUseCase;
  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithEmailUseCase signInWithEmailUseCase,
    required SignUpWithEmailUseCase signUpWithEmailUseCase,
    required SignInWithPhoneUseCase signInWithPhoneUseCase,
    required VerifyPhoneCodeUseCase verifyPhoneCodeUseCase,
    required PasswordResetUseCase passwordResetUseCase,
  })  : _authRepository = authRepository,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _signInWithEmailUseCase = signInWithEmailUseCase,
        _signUpWithEmailUseCase = signUpWithEmailUseCase,
        _signInWithPhoneUseCase = signInWithPhoneUseCase,
        _verifyPhoneCodeUseCase = verifyPhoneCodeUseCase,
        _passwordResetUseCase = passwordResetUseCase,
        super(AuthInitial()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithGoogleRequested>(_onAuthSignInWithGoogleRequested);
    on<AuthSignInWithEmailRequested>(_onAuthSignInWithEmailRequested);
    on<AuthSignUpWithEmailRequested>(_onAuthSignUpWithEmailRequested);
    on<AuthSignInWithPhoneRequested>(_onAuthSignInWithPhoneRequested);
    on<AuthVerifyPhoneCodeRequested>(_onAuthVerifyPhoneCodeRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    // Escuchar cambios en el estado de autenticación
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
    
    // Verificar si hay un usuario actual
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error al verificar autenticación: $e'));
    }
  }

  Future<void> _onAuthSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final user = await _signInWithGoogleUseCase(NoParams());
      
      if (user != null) {
        emit(AuthAuthenticated(user));
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
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Credenciales incorrectas. Verifica tu email y contraseña.'));
      }
    } catch (e) {
      emit(AuthError('Error al iniciar sesión: $e'));
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
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Error al crear la cuenta. Intenta nuevamente.'));
      }
    } catch (e) {
      emit(AuthError('Error al registrarse: $e'));
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
    } catch (e) {
      emit(AuthError('Error al enviar código SMS: $e'));
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
        ),
      );
      
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Código SMS incorrecto. Verifica e intenta nuevamente.'));
      }
    } catch (e) {
      emit(AuthError('Error al verificar código: $e'));
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
    } catch (e) {
      emit(AuthError('Error al enviar email de recuperación: $e'));
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

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
} 