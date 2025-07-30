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
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/onboarding_page.dart';
import 'presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    developer.log('🚀 Iniciando aplicación Prosavis...');
    
    // Inicializar Firebase usando nuestro servicio mejorado
    await FirebaseService.initializeFirebase();
    
    // Configurar Firestore según el modo
    FirestoreService.setDevelopmentMode(FirebaseService.isDevelopmentMode);
    
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
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
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
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: context.read<AuthRepository>(),
            signInWithGoogleUseCase: context.read<SignInWithGoogleUseCase>(),
          )..add(AuthStarted()),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
