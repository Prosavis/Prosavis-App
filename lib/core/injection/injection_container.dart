import 'package:get_it/get_it.dart';
import 'package:myapp/data/repositories/auth_repository_impl.dart';
import 'package:myapp/data/services/firebase_service.dart';
import 'package:myapp/domain/repositories/auth_repository.dart';
import 'package:myapp/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:myapp/presentation/blocs/auth/auth_bloc.dart';

final sl = GetIt.instance;

// Alias para setup, mantiene compatibilidad
Future<void> setupDependencyInjection() async => await init();

Future<void> init() async {
  // 1) Initialize Firebase before registering services that use it
  await FirebaseService.initializeFirebase();

  // 2) Register your service and repositories
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
  
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton<SignInWithGoogleUseCase>(
    () => SignInWithGoogleUseCase(sl()),
  );

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      authRepository: sl(),
      signInWithGoogleUseCase: sl(),
    ),
  );
}
