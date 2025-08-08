import 'package:get_it/get_it.dart';
import 'package:prosavis/data/repositories/auth_repository_impl.dart';
import 'package:prosavis/data/services/firebase_service.dart';
import 'package:prosavis/data/services/firestore_service.dart';

import 'package:prosavis/data/services/image_storage_service.dart';
import 'package:prosavis/domain/repositories/auth_repository.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_email_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_up_with_email_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_phone_usecase.dart';
import 'package:prosavis/domain/usecases/auth/verify_phone_code_usecase.dart';
import 'package:prosavis/domain/usecases/auth/password_reset_usecase.dart';
import 'package:prosavis/domain/usecases/auth/enroll_mfa_usecase.dart';
import 'package:prosavis/domain/usecases/auth/sign_in_with_mfa_usecase.dart';
import 'package:prosavis/domain/repositories/service_repository.dart';
import 'package:prosavis/data/repositories/service_repository_impl.dart';
import 'package:prosavis/domain/repositories/review_repository.dart';
import 'package:prosavis/data/repositories/review_repository_impl.dart';
import 'package:prosavis/domain/usecases/services/create_service_usecase.dart';
import 'package:prosavis/domain/usecases/services/search_services_usecase.dart';
import 'package:prosavis/domain/usecases/services/get_featured_services_usecase.dart';
import 'package:prosavis/domain/usecases/services/get_nearby_services_usecase.dart';
import 'package:prosavis/domain/usecases/services/get_user_services_usecase.dart';
import 'package:prosavis/domain/usecases/services/get_service_by_id_usecase.dart';
import 'package:prosavis/domain/usecases/services/update_service_usecase.dart';
import 'package:prosavis/domain/usecases/services/delete_service_usecase.dart';
import 'package:prosavis/domain/usecases/reviews/create_review_usecase.dart';
import 'package:prosavis/domain/usecases/reviews/get_service_reviews_usecase.dart';
import 'package:prosavis/domain/usecases/reviews/check_user_review_usecase.dart';
import 'package:prosavis/domain/repositories/favorite_repository.dart';
import 'package:prosavis/data/repositories/favorite_repository_impl.dart';
import 'package:prosavis/domain/usecases/favorites/add_to_favorites_usecase.dart';
import 'package:prosavis/domain/usecases/favorites/remove_from_favorites_usecase.dart';
import 'package:prosavis/domain/usecases/favorites/get_user_favorites_usecase.dart';
import 'package:prosavis/domain/usecases/favorites/check_favorite_status_usecase.dart';
import 'package:prosavis/presentation/blocs/auth/auth_bloc.dart';
import 'package:prosavis/presentation/blocs/search/search_bloc.dart';
import 'package:prosavis/presentation/blocs/home/home_bloc.dart';
import 'package:prosavis/presentation/blocs/favorites/favorites_bloc.dart';

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
    


    // 2) Register your service and repositories
    sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
    developer.log('✅ FirebaseService registrado');
    
    sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
    developer.log('✅ FirestoreService registrado');
    

    
    sl.registerLazySingleton<ImageStorageService>(() => ImageStorageService());
    developer.log('✅ ImageStorageService registrado');
    
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );
    developer.log('✅ AuthRepository registrado');
    
    sl.registerLazySingleton<ServiceRepository>(
      () => ServiceRepositoryImpl(sl<FirestoreService>()),
    );
    developer.log('✅ ServiceRepository registrado');

    sl.registerLazySingleton<ReviewRepository>(
      () => ReviewRepositoryImpl(sl<FirestoreService>()),
    );
    developer.log('✅ ReviewRepository registrado');

    sl.registerLazySingleton<FavoriteRepository>(
      () => FavoriteRepositoryImpl(),
    );
    developer.log('✅ FavoriteRepository registrado');

    // Use cases
    sl.registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ SignInWithGoogleUseCase registrado');

    sl.registerLazySingleton<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ SignInWithEmailUseCase registrado');

    sl.registerLazySingleton<SignUpWithEmailUseCase>(
      () => SignUpWithEmailUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ SignUpWithEmailUseCase registrado');

    sl.registerLazySingleton<SignInWithPhoneUseCase>(
      () => SignInWithPhoneUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ SignInWithPhoneUseCase registrado');

    sl.registerLazySingleton<VerifyPhoneCodeUseCase>(
      () => VerifyPhoneCodeUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ VerifyPhoneCodeUseCase registrado');

    sl.registerLazySingleton<PasswordResetUseCase>(
      () => PasswordResetUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ PasswordResetUseCase registrado');

    sl.registerLazySingleton<EnrollMFAUseCase>(
      () => EnrollMFAUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ EnrollMFAUseCase registrado');

    sl.registerLazySingleton<SignInWithMFAUseCase>(
      () => SignInWithMFAUseCase(sl<AuthRepository>()),
    );
    developer.log('✅ SignInWithMFAUseCase registrado');

    sl.registerLazySingleton<CreateServiceUseCase>(
      () {
        developer.log('🔧 Creando instancia de CreateServiceUseCase...');
        final serviceRepo = sl<ServiceRepository>();
        developer.log('✅ ServiceRepository obtenido: ${serviceRepo.runtimeType}');
        return CreateServiceUseCase(serviceRepo);
      },
    );
    developer.log('✅ CreateServiceUseCase registrado');

    sl.registerLazySingleton<SearchServicesUseCase>(
      () => SearchServicesUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ SearchServicesUseCase registrado');

    sl.registerLazySingleton<GetFeaturedServicesUseCase>(
      () => GetFeaturedServicesUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ GetFeaturedServicesUseCase registrado');

    sl.registerLazySingleton<GetNearbyServicesUseCase>(
      () => GetNearbyServicesUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ GetNearbyServicesUseCase registrado');

    sl.registerLazySingleton<GetUserServicesUseCase>(
      () => GetUserServicesUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ GetUserServicesUseCase registrado');

    sl.registerLazySingleton<GetServiceByIdUseCase>(
      () => GetServiceByIdUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ GetServiceByIdUseCase registrado');

    sl.registerLazySingleton<UpdateServiceUseCase>(
      () => UpdateServiceUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ UpdateServiceUseCase registrado');

    sl.registerLazySingleton<DeleteServiceUseCase>(
      () => DeleteServiceUseCase(sl<ServiceRepository>()),
    );
    developer.log('✅ DeleteServiceUseCase registrado');

    sl.registerLazySingleton<CreateReviewUseCase>(
      () => CreateReviewUseCase(sl<ReviewRepository>(), sl<ServiceRepository>()),
    );
    developer.log('✅ CreateReviewUseCase registrado');

    sl.registerLazySingleton<GetServiceReviewsUseCase>(
      () => GetServiceReviewsUseCase(sl<ReviewRepository>()),
    );
    developer.log('✅ GetServiceReviewsUseCase registrado');

    sl.registerLazySingleton<CheckUserReviewUseCase>(
      () => CheckUserReviewUseCase(sl<ReviewRepository>()),
    );
    developer.log('✅ CheckUserReviewUseCase registrado');

    sl.registerLazySingleton<AddToFavoritesUseCase>(
      () => AddToFavoritesUseCase(sl<FavoriteRepository>()),
    );
    developer.log('✅ AddToFavoritesUseCase registrado');

    sl.registerLazySingleton<RemoveFromFavoritesUseCase>(
      () => RemoveFromFavoritesUseCase(sl<FavoriteRepository>()),
    );
    developer.log('✅ RemoveFromFavoritesUseCase registrado');

    sl.registerLazySingleton<GetUserFavoritesUseCase>(
      () => GetUserFavoritesUseCase(sl<FavoriteRepository>()),
    );
    developer.log('✅ GetUserFavoritesUseCase registrado');

    sl.registerLazySingleton<CheckFavoriteStatusUseCase>(
      () => CheckFavoriteStatusUseCase(sl<FavoriteRepository>()),
    );
    developer.log('✅ CheckFavoriteStatusUseCase registrado');

    // BLoCs
    sl.registerFactory(
      () => AuthBloc(
        authRepository: sl<AuthRepository>(),
        signInWithGoogleUseCase: sl<SignInWithGoogleUseCase>(),
        signInWithEmailUseCase: sl<SignInWithEmailUseCase>(),
        signUpWithEmailUseCase: sl<SignUpWithEmailUseCase>(),
        signInWithPhoneUseCase: sl<SignInWithPhoneUseCase>(),
        verifyPhoneCodeUseCase: sl<VerifyPhoneCodeUseCase>(),
        passwordResetUseCase: sl<PasswordResetUseCase>(),
      ),
    );
    developer.log('✅ AuthBloc registrado');

    sl.registerFactory(
      () => SearchBloc(sl<SearchServicesUseCase>()),
    );
    developer.log('✅ SearchBloc registrado');

    sl.registerFactory(
      () => HomeBloc(
        getFeaturedServicesUseCase: sl<GetFeaturedServicesUseCase>(),
        getNearbyServicesUseCase: sl<GetNearbyServicesUseCase>(),
      ),
    );
    developer.log('✅ HomeBloc registrado');

    sl.registerFactory(
      () => FavoritesBloc(
        getUserFavoritesUseCase: sl<GetUserFavoritesUseCase>(),
        addToFavoritesUseCase: sl<AddToFavoritesUseCase>(),
        removeFromFavoritesUseCase: sl<RemoveFromFavoritesUseCase>(),
        checkFavoriteStatusUseCase: sl<CheckFavoriteStatusUseCase>(),
      ),
    );
    developer.log('✅ FavoritesBloc registrado');

    // ProfileBloc se registra directamente en main.dart para acceso al AuthBloc
    developer.log('✅ ProfileBloc configurado en main.dart');
    
    developer.log('🎉 Todas las dependencias configuradas correctamente');
  } catch (e, stackTrace) {
    developer.log('❌ Error crítico al configurar dependencias: $e');
    developer.log('Stack trace: $stackTrace');
    rethrow; // Re-lanzar el error para que main.dart lo pueda manejar
  }
}
