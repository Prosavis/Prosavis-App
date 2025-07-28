import 'package:get_it/get_it.dart';
import '../../data/services/firebase_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/sign_in_with_google_usecase.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // External dependencies
  final firebaseService = FirebaseService();
  getIt.registerLazySingleton<FirebaseService>(() => firebaseService);

  // Initialize Firebase
  await firebaseService.initializeFirebase();

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<FirebaseService>()),
  );

  // Use cases
  getIt.registerLazySingleton<SignInWithGoogleUseCase>(
    () => SignInWithGoogleUseCase(getIt<AuthRepository>()),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
      signInWithGoogleUseCase: getIt<SignInWithGoogleUseCase>(),
    ),
  );
} 