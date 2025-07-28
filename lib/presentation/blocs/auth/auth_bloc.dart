import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/auth/sign_in_with_google_usecase.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
  })  : _authRepository = authRepository,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        super(AuthInitial()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithGoogleRequested>(_onAuthSignInWithGoogleRequested);
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