import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/services/firebase_service.dart';
import 'data/services/firestore_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'domain/usecases/auth/sign_in_with_email_usecase.dart';
import 'domain/usecases/auth/sign_up_with_email_usecase.dart';
import 'domain/usecases/auth/sign_in_with_phone_usecase.dart';
import 'domain/usecases/auth/verify_phone_code_usecase.dart';
import 'domain/usecases/auth/password_reset_usecase.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/theme/theme_bloc.dart';
import 'presentation/blocs/theme/theme_state.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/main/main_navigation_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/verify_phone_page.dart';
import 'presentation/pages/auth/forgot_password_page.dart';
import 'presentation/pages/settings/notifications_settings_page.dart';
import 'presentation/pages/settings/language_settings_page.dart';
import 'presentation/pages/settings/edit_profile_page.dart';
import 'presentation/pages/settings/privacy_settings_page.dart';
import 'presentation/pages/settings/terms_conditions_page.dart';
import 'presentation/pages/search/search_page.dart';
import 'presentation/pages/categories/categories_page.dart';
import 'presentation/pages/notifications/notifications_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    developer.log('🚀 Iniciando aplicación Prosavis...');
    
    // Inicializar Firebase usando nuestro servicio mejorado
    await FirebaseService.initializeFirebase();
    
    // Configurar Firestore según el modo
    FirestoreService.setDevelopmentMode(FirebaseService.isDevelopmentMode);
    
    // Diagnosticar configuración de Firebase para debugging
    FirebaseService.diagnoseFirebaseConfiguration();
    
    if (FirebaseService.isDevelopmentMode) {
      developer.log('🔧 Aplicación iniciada en MODO DESARROLLO');
    } else {
      developer.log('✅ Aplicación iniciada con Firebase configurado');
    }
    
  } catch (e) {
    developer.log('⚠️ Error en inicialización: $e');
  }
  
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/auth/verify-phone',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return VerifyPhonePage(
          verificationId: extra['verificationId'],
          phoneNumber: extra['phoneNumber'],
        );
      },
    ),
    GoRoute(
      path: '/auth/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationPage(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationsSettingsPage(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageSettingsPage(),
    ),
    GoRoute(
      path: '/settings/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacySettingsPage(),
    ),
    GoRoute(
      path: '/settings/terms',
      builder: (context, state) => const TermsConditionsPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        Provider<SignInWithGoogleUseCase>(
          create: (context) => SignInWithGoogleUseCase(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<SignInWithEmailUseCase>(
          create: (context) => SignInWithEmailUseCase(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<SignUpWithEmailUseCase>(
          create: (context) => SignUpWithEmailUseCase(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<SignInWithPhoneUseCase>(
          create: (context) => SignInWithPhoneUseCase(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<VerifyPhoneCodeUseCase>(
          create: (context) => VerifyPhoneCodeUseCase(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<PasswordResetUseCase>(
          create: (context) => PasswordResetUseCase(
            context.read<AuthRepository>(),
          ),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: context.read<AuthRepository>(),
            signInWithGoogleUseCase: context.read<SignInWithGoogleUseCase>(),
            signInWithEmailUseCase: context.read<SignInWithEmailUseCase>(),
            signUpWithEmailUseCase: context.read<SignUpWithEmailUseCase>(),
            signInWithPhoneUseCase: context.read<SignInWithPhoneUseCase>(),
            verifyPhoneCodeUseCase: context.read<VerifyPhoneCodeUseCase>(),
            passwordResetUseCase: context.read<PasswordResetUseCase>(),
          )..add(AuthStarted()),
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
