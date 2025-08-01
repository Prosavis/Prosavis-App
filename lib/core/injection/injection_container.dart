import 'package:get_it/get_it.dart';
import 'package:prosavis/data/repositories/auth_repository_impl.dart';
import 'package:prosavis/data/services/firebase_service.dart';
import 'package:prosavis/domain/repositories/auth_repository.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_email_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_up_with_email_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_phone_usecase.dart';
import 'package:prosavis/domain/usecases/auth/verify_phone_code_usecase.dart';
import 'package:prosavis/domain/usecases/auth/password_reset_usecase.dart';
import 'package:prosavis/presentation/blocs/auth/auth_bloc.dart';
import 'dart:developer' as developer;

final sl = GetIt.instance;

// Alias para setup, mantiene compatibilidad
Future<void> setupDependencyInjection() async => await init();

Future<void> init() async {
  try {
    developer.log('🔧 Iniciando configuración de dependencias...');
    
    // 1) Initialize Firebase before registering services that use it
    await FirebaseService.initializeFirebase();
    developer.log('✅ Firebase inicializado: ${FirebaseService.isInitialized}');
    
    if (FirebaseService.isDevelopmentMode) {
      developer.log('⚠️ Ejecutando en modo desarrollo (sin Firebase real)');
    }

    // 2) Register your service and repositories
    sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
    developer.log('✅ FirebaseService registrado');
    
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );
    developer.log('✅ AuthRepository registrado');

    // Use cases
    sl.registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(sl()),
    );
    developer.log('✅ SignInWithGoogleUseCase registrado');

    sl.registerLazySingleton<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(sl()),
    );
    developer.log('✅ SignInWithEmailUseCase registrado');

    sl.registerLazySingleton<SignUpWithEmailUseCase>(
      () => SignUpWithEmailUseCase(sl()),
    );
    developer.log('✅ SignUpWithEmailUseCase registrado');

    sl.registerLazySingleton<SignInWithPhoneUseCase>(
      () => SignInWithPhoneUseCase(sl()),
    );
    developer.log('✅ SignInWithPhoneUseCase registrado');

    sl.registerLazySingleton<VerifyPhoneCodeUseCase>(
      () => VerifyPhoneCodeUseCase(sl()),
    );
    developer.log('✅ VerifyPhoneCodeUseCase registrado');

    sl.registerLazySingleton<PasswordResetUseCase>(
      () => PasswordResetUseCase(sl()),
    );
    developer.log('✅ PasswordResetUseCase registrado');

    // BLoC
    sl.registerFactory(
      () => AuthBloc(
        authRepository: sl(),
        signInWithGoogleUseCase: sl(),
        signInWithEmailUseCase: sl(),
        signUpWithEmailUseCase: sl(),
        signInWithPhoneUseCase: sl(),
        verifyPhoneCodeUseCase: sl(),
        passwordResetUseCase: sl(),
      ),
    );
    developer.log('✅ AuthBloc registrado');
    
    developer.log('🎉 Todas las dependencias configuradas correctamente');
  } catch (e, stackTrace) {
    developer.log('❌ Error crítico al configurar dependencias: $e');
    developer.log('Stack trace: $stackTrace');
    rethrow; // Re-lanzar el error para que main.dart lo pueda manejar
  }
}
