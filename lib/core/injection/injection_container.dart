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
      developer.log('✅ Firebase inicializado correctamente');
    }
    


    // 2) Register your service and repositories
    sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
    sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
    sl.registerLazySingleton<ImageStorageService>(() => ImageStorageService());
    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
    sl.registerLazySingleton<ServiceRepository>(() => ServiceRepositoryImpl(sl<FirestoreService>()));
    sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl<FirestoreService>()));
    sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl());
    sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl<FirestoreService>()));
    
    if (AppConfig.enableDetailedLogs) {
      developer.log('✅ Servicios registrados: Firebase, Firestore, ImageStorage, Auth, Service, Review, Favorite, User');
    }



    // Use cases - Auth
    sl.registerLazySingleton<SignInWithGoogleUseCase>(() => SignInWithGoogleUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<SignInWithEmailUseCase>(() => SignInWithEmailUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<SignUpWithEmailUseCase>(() => SignUpWithEmailUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<SignInWithPhoneUseCase>(() => SignInWithPhoneUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<VerifyPhoneCodeUseCase>(() => VerifyPhoneCodeUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<PasswordResetUseCase>(() => PasswordResetUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<EnrollMFAUseCase>(() => EnrollMFAUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<SignInWithMFAUseCase>(() => SignInWithMFAUseCase(sl<AuthRepository>()));
    
    if (AppConfig.enableDetailedLogs) {
      developer.log('✅ Use Cases Auth registrados: Google, Email, Phone, MFA, Password Reset');
    }

    // Use cases - Services  
    sl.registerLazySingleton<CreateServiceUseCase>(() => CreateServiceUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<SearchServicesUseCase>(() => SearchServicesUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<GetFeaturedServicesUseCase>(() => GetFeaturedServicesUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<GetNearbyServicesUseCase>(() => GetNearbyServicesUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<GetUserServicesUseCase>(() => GetUserServicesUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<GetServiceByIdUseCase>(() => GetServiceByIdUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<UpdateServiceUseCase>(() => UpdateServiceUseCase(sl<ServiceRepository>()));
    sl.registerLazySingleton<DeleteServiceUseCase>(() => DeleteServiceUseCase(sl<ServiceRepository>()));
    
    if (AppConfig.enableDetailedLogs) {
      developer.log('✅ Use Cases Services registrados: Create, Search, Featured, Nearby, User, ById, Update, Delete');
    }

    // Use cases - Reviews
    sl.registerLazySingleton<CreateReviewUseCase>(() => CreateReviewUseCase(sl<ReviewRepository>(), sl<ServiceRepository>()));
    sl.registerLazySingleton<GetServiceReviewsUseCase>(() => GetServiceReviewsUseCase(sl<ReviewRepository>()));
    sl.registerLazySingleton<GetServiceReviewStatsUseCase>(() => GetServiceReviewStatsUseCase(sl<ReviewRepository>()));
    sl.registerLazySingleton<CheckUserReviewUseCase>(() => CheckUserReviewUseCase(sl<ReviewRepository>()));
    
    // Use cases - Favorites  
    sl.registerLazySingleton<AddToFavoritesUseCase>(() => AddToFavoritesUseCase(sl<FavoriteRepository>()));
    sl.registerLazySingleton<RemoveFromFavoritesUseCase>(() => RemoveFromFavoritesUseCase(sl<FavoriteRepository>()));
    sl.registerLazySingleton<GetUserFavoritesUseCase>(() => GetUserFavoritesUseCase(sl<FavoriteRepository>()));
    sl.registerLazySingleton<CheckFavoriteStatusUseCase>(() => CheckFavoriteStatusUseCase(sl<FavoriteRepository>()));
    sl.registerLazySingleton<WatchUserFavoritesUseCase>(() => WatchUserFavoritesUseCase(sl<FavoriteRepository>()));
    
    // Use cases - Users
    sl.registerLazySingleton<DeleteUserCascadeUseCase>(() => DeleteUserCascadeUseCase(sl<UserRepository>()));
    
    if (AppConfig.enableDetailedLogs) {
      developer.log('✅ Use Cases adicionales registrados: Reviews, Favorites, Users');
    }

    // BLoCs
    sl.registerFactory(() => AuthBloc(
      authRepository: sl<AuthRepository>(),
      signInWithGoogleUseCase: sl<SignInWithGoogleUseCase>(),
      signInWithEmailUseCase: sl<SignInWithEmailUseCase>(),
      signUpWithEmailUseCase: sl<SignUpWithEmailUseCase>(),
      signInWithPhoneUseCase: sl<SignInWithPhoneUseCase>(),
      verifyPhoneCodeUseCase: sl<VerifyPhoneCodeUseCase>(),
      passwordResetUseCase: sl<PasswordResetUseCase>(),
    ));
    
    sl.registerFactory(() => SearchBloc(sl<SearchServicesUseCase>()));
    
    sl.registerFactory(() => HomeBloc(
      getFeaturedServicesUseCase: sl<GetFeaturedServicesUseCase>(),
      getNearbyServicesUseCase: sl<GetNearbyServicesUseCase>(),
      getServiceReviewStatsUseCase: sl<GetServiceReviewStatsUseCase>(),
    ));
    
    sl.registerFactory(() => FavoritesBloc(
      getUserFavoritesUseCase: sl<GetUserFavoritesUseCase>(),
      watchUserFavoritesUseCase: sl<WatchUserFavoritesUseCase>(),
      addToFavoritesUseCase: sl<AddToFavoritesUseCase>(),
      removeFromFavoritesUseCase: sl<RemoveFromFavoritesUseCase>(),
      checkFavoriteStatusUseCase: sl<CheckFavoriteStatusUseCase>(),
      getServiceReviewStatsUseCase: sl<GetServiceReviewStatsUseCase>(),
    ));
    
    if (AppConfig.enableDetailedLogs) {
      developer.log('✅ BLoCs registrados: Auth, Search, Home, Favorites');
    }



    // ProfileBloc se registra directamente en main.dart para acceso al AuthBloc
    if (AppConfig.enableDetailedLogs) developer.log('✅ ProfileBloc configurado en main.dart');
    
    if (AppConfig.enableDetailedLogs) developer.log('🎉 Todas las dependencias configuradas correctamente');
  } catch (e, stackTrace) {
    developer.log('❌ Error crítico al configurar dependencias: $e');
    developer.log('Stack trace: $stackTrace');
    rethrow; // Re-lanzar el error para que main.dart lo pueda manejar
  }
}
