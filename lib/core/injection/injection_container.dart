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
import 'package:prosavis/domain/usecases/reviews/get_service_review_stats_usecase.dart';
import 'package:prosavis/domain/usecases/reviews/check_user_review_usecase.dart';
import 'package:prosavis/domain/repositories/favorite_repository.dart';
import 'package:prosavis/data/repositories/favorite_repository_impl.dart';
import 'package:prosavis/domain/repositories/user_repository.dart';
import 'package:prosavis/data/repositories/user_repository_impl.dart';

import 'package:prosavis/domain/usecases/favorites/add_to_favorites_usecase.dart';
import 'package:prosavis/domain/usecases/favorites/remove_from_favorites_usecase.dart';
import 'package:prosavis/domain/usecases/favorites/get_user_favorites_usecase.dart';
import 'package:prosavis/domain/usecases/favorites/check_favorite_status_usecase.dart';
import 'package:prosavis/domain/usecases/users/delete_user_cascade_usecase.dart';
import 'package:prosavis/presentation/blocs/auth/auth_bloc.dart';
import 'package:prosavis/presentation/blocs/search/search_bloc.dart';
import 'package:prosavis/presentation/blocs/home/home_bloc.dart';
import 'package:prosavis/presentation/blocs/favorites/favorites_bloc.dart';


import 'dart:developer' as developer;
import 'package:prosavis/core/config/app_config.dart';

final sl = GetIt.instance;

// Alias para setup, mantiene compatibilidad
Future<void> setupDependencyInjection() async => await init();

Future<void> init() async {
  try {
    if (AppConfig.enableDetailedLogs) {
      developer.log('🔧 Iniciando configuración de dependencias...');
    }
    
    // 1) Initialize Firebase before registering services that use it
    await FirebaseService.initializeFirebase();
    if (AppConfig.enableDetailedLogs) {
      developer.log('✅ Firebase inicializado: ${FirebaseService.isInitialized}');
    }
    


    // 2) Register your service and repositories
    sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
    if (AppConfig.enableDetailedLogs) developer.log('✅ FirebaseService registrado');
    
    sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
    if (AppConfig.enableDetailedLogs) developer.log('✅ FirestoreService registrado');
    

    
    sl.registerLazySingleton<ImageStorageService>(() => ImageStorageService());
    if (AppConfig.enableDetailedLogs) developer.log('✅ ImageStorageService registrado');
    
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ AuthRepository registrado');
    
    sl.registerLazySingleton<ServiceRepository>(
      () => ServiceRepositoryImpl(sl<FirestoreService>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ ServiceRepository registrado');

    sl.registerLazySingleton<ReviewRepository>(
      () => ReviewRepositoryImpl(sl<FirestoreService>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ ReviewRepository registrado');

    sl.registerLazySingleton<FavoriteRepository>(
      () => FavoriteRepositoryImpl(),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ FavoriteRepository registrado');

    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(sl<FirestoreService>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ UserRepository registrado');



    // Use cases
    sl.registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SignInWithGoogleUseCase registrado');

    sl.registerLazySingleton<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SignInWithEmailUseCase registrado');

    sl.registerLazySingleton<SignUpWithEmailUseCase>(
      () => SignUpWithEmailUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SignUpWithEmailUseCase registrado');

    sl.registerLazySingleton<SignInWithPhoneUseCase>(
      () => SignInWithPhoneUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SignInWithPhoneUseCase registrado');

    sl.registerLazySingleton<VerifyPhoneCodeUseCase>(
      () => VerifyPhoneCodeUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ VerifyPhoneCodeUseCase registrado');

    sl.registerLazySingleton<PasswordResetUseCase>(
      () => PasswordResetUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ PasswordResetUseCase registrado');

    sl.registerLazySingleton<EnrollMFAUseCase>(
      () => EnrollMFAUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ EnrollMFAUseCase registrado');

    sl.registerLazySingleton<SignInWithMFAUseCase>(
      () => SignInWithMFAUseCase(sl<AuthRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SignInWithMFAUseCase registrado');

    sl.registerLazySingleton<CreateServiceUseCase>(
      () {
        if (AppConfig.enableDetailedLogs) developer.log('🔧 Creando instancia de CreateServiceUseCase...');
        final serviceRepo = sl<ServiceRepository>();
        if (AppConfig.enableDetailedLogs) developer.log('✅ ServiceRepository obtenido: ${serviceRepo.runtimeType}');
        return CreateServiceUseCase(serviceRepo);
      },
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ CreateServiceUseCase registrado');

    sl.registerLazySingleton<SearchServicesUseCase>(
      () => SearchServicesUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SearchServicesUseCase registrado');

    sl.registerLazySingleton<GetFeaturedServicesUseCase>(
      () => GetFeaturedServicesUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetFeaturedServicesUseCase registrado');

    sl.registerLazySingleton<GetNearbyServicesUseCase>(
      () => GetNearbyServicesUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetNearbyServicesUseCase registrado');

    sl.registerLazySingleton<GetUserServicesUseCase>(
      () => GetUserServicesUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetUserServicesUseCase registrado');

    sl.registerLazySingleton<GetServiceByIdUseCase>(
      () => GetServiceByIdUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetServiceByIdUseCase registrado');

    sl.registerLazySingleton<UpdateServiceUseCase>(
      () => UpdateServiceUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ UpdateServiceUseCase registrado');

    sl.registerLazySingleton<DeleteServiceUseCase>(
      () => DeleteServiceUseCase(sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ DeleteServiceUseCase registrado');

    sl.registerLazySingleton<CreateReviewUseCase>(
      () => CreateReviewUseCase(sl<ReviewRepository>(), sl<ServiceRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ CreateReviewUseCase registrado');

    sl.registerLazySingleton<GetServiceReviewsUseCase>(
      () => GetServiceReviewsUseCase(sl<ReviewRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetServiceReviewsUseCase registrado');

    sl.registerLazySingleton<GetServiceReviewStatsUseCase>(
      () => GetServiceReviewStatsUseCase(sl<ReviewRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetServiceReviewStatsUseCase registrado');

    sl.registerLazySingleton<CheckUserReviewUseCase>(
      () => CheckUserReviewUseCase(sl<ReviewRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ CheckUserReviewUseCase registrado');

    sl.registerLazySingleton<AddToFavoritesUseCase>(
      () => AddToFavoritesUseCase(sl<FavoriteRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ AddToFavoritesUseCase registrado');

    sl.registerLazySingleton<RemoveFromFavoritesUseCase>(
      () => RemoveFromFavoritesUseCase(sl<FavoriteRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ RemoveFromFavoritesUseCase registrado');

    sl.registerLazySingleton<GetUserFavoritesUseCase>(
      () => GetUserFavoritesUseCase(sl<FavoriteRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ GetUserFavoritesUseCase registrado');

    sl.registerLazySingleton<CheckFavoriteStatusUseCase>(
      () => CheckFavoriteStatusUseCase(sl<FavoriteRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ CheckFavoriteStatusUseCase registrado');

    // User use cases
    sl.registerLazySingleton<DeleteUserCascadeUseCase>(
      () => DeleteUserCascadeUseCase(sl<UserRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ DeleteUserCascadeUseCase registrado');

    // Stream de favoritos en tiempo real
    sl.registerLazySingleton<WatchUserFavoritesUseCase>(
      () => WatchUserFavoritesUseCase(sl<FavoriteRepository>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ WatchUserFavoritesUseCase registrado');

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
    if (AppConfig.enableDetailedLogs) developer.log('✅ AuthBloc registrado');

    sl.registerFactory(
      () => SearchBloc(sl<SearchServicesUseCase>()),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ SearchBloc registrado');

    sl.registerFactory(
      () => HomeBloc(
        getFeaturedServicesUseCase: sl<GetFeaturedServicesUseCase>(),
        getNearbyServicesUseCase: sl<GetNearbyServicesUseCase>(),
        getServiceReviewStatsUseCase: sl<GetServiceReviewStatsUseCase>(),
      ),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ HomeBloc registrado');

    sl.registerFactory(
      () => FavoritesBloc(
        getUserFavoritesUseCase: sl<GetUserFavoritesUseCase>(),
        watchUserFavoritesUseCase: sl<WatchUserFavoritesUseCase>(),
        addToFavoritesUseCase: sl<AddToFavoritesUseCase>(),
        removeFromFavoritesUseCase: sl<RemoveFromFavoritesUseCase>(),
        checkFavoriteStatusUseCase: sl<CheckFavoriteStatusUseCase>(),
        getServiceReviewStatsUseCase: sl<GetServiceReviewStatsUseCase>(),
      ),
    );
    if (AppConfig.enableDetailedLogs) developer.log('✅ FavoritesBloc registrado');



    // ProfileBloc se registra directamente en main.dart para acceso al AuthBloc
    if (AppConfig.enableDetailedLogs) developer.log('✅ ProfileBloc configurado en main.dart');
    
    if (AppConfig.enableDetailedLogs) developer.log('🎉 Todas las dependencias configuradas correctamente');
  } catch (e, stackTrace) {
    developer.log('❌ Error crítico al configurar dependencias: $e');
    developer.log('Stack trace: $stackTrace');
    rethrow; // Re-lanzar el error para que main.dart lo pueda manejar
  }
}
