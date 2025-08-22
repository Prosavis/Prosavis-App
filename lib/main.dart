import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';

import 'dart:developer' as developer;
import 'core/config/app_config.dart';

import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/performance_config.dart';
import 'data/services/firebase_service.dart';
import 'data/services/firestore_service.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/theme/theme_bloc.dart';
import 'presentation/blocs/theme/theme_state.dart';
import 'presentation/blocs/search/search_bloc.dart';
import 'presentation/blocs/search/search_event.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/home/home_bloc.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'data/services/image_storage_service.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/main/main_navigation_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/verify_phone_page.dart';
import 'presentation/pages/auth/forgot_password_page.dart';
import 'presentation/pages/settings/notifications_settings_page.dart';
import 'presentation/pages/settings/language_settings_page.dart';

import 'presentation/pages/settings/edit_profile_page.dart';
import 'presentation/pages/address/map_picker_page.dart';
import 'presentation/pages/settings/terms_conditions_page.dart';
import 'presentation/pages/search/search_page.dart';
import 'presentation/pages/categories/categories_page.dart';
import 'presentation/pages/notifications/notifications_page.dart';
import 'presentation/pages/profile/profile_page.dart';
import 'presentation/pages/services/service_creation_page.dart';
import 'presentation/pages/services/my_services_page.dart';
import 'presentation/pages/services/service_details_page.dart';
import 'presentation/pages/services/service_edit_page.dart';
import 'domain/entities/service_entity.dart';
import 'domain/usecases/services/create_service_usecase.dart';
import 'core/injection/injection_container.dart' as di;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'core/services/haptics_service.dart';

void main() async {
  // Optimización: Defer first frame para inicialización más suave
  WidgetsFlutterBinding.ensureInitialized();
  // Cargar variables de entorno (API Keys, flags, etc.)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // continuar sin .env
  }
  
  bool dependenciesInitialized = false;
  
  try {
    if (AppConfig.enableDetailedLogs) developer.log('🚀 Iniciando aplicación Prosavis...');
    
    // Configurar optimizaciones de rendimiento
    PerformanceConfig.configurePerformance();
    
    // Optimización: Inicialización en paralelo cuando sea posible
    await Future.wait([
      // Inicializar sistema de inyección de dependencias
      di.init(),
      // Precargar activos críticos si los hay
      _preloadCriticalAssets(),
    ]);
    
    dependenciesInitialized = true;
    
    // Diagnosticar configuración de Firebase para debugging
    if (AppConfig.enableDetailedLogs) {
      FirebaseService.diagnoseFirebaseConfiguration();
      developer.log('✅ Aplicación iniciada con Firebase configurado');
    }
    
  } catch (e, stackTrace) {
    developer.log('❌ Error crítico en inicialización: $e');
    developer.log('Stack trace: $stackTrace');
    dependenciesInitialized = false;
  }
  
  runApp(MyApp(dependenciesReady: dependenciesInitialized));
}

/// Optimización: Precargar activos críticos para mejorar rendimiento inicial
Future<void> _preloadCriticalAssets() async {
  // Forzar la resolución de la tipografía más usada para evitar jank inicial.
  // No realizamos precache de imágenes aquí porque no disponemos de un
  // BuildContext válido en esta fase de inicio.
  GoogleFonts.inter();
  return;
}

// Transiciones premium reutilizables para rutas
CustomTransitionPage<void> _fadeThroughPage({required Widget child}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppConstants.mediumAnimation,
    reverseTransitionDuration: AppConstants.mediumAnimation,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _sharedAxisPage({
  required Widget child,
  SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppConstants.mediumAnimation,
    reverseTransitionDuration: AppConstants.mediumAnimation,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/',
  observers: [HapticsRouteObserver()],
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadeThroughPage(child: const SplashPage()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: const LoginPage(),
        type: SharedAxisTransitionType.scaled,
      ),
    ),
    GoRoute(
      path: '/auth/verify-phone',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _sharedAxisPage(
          child: VerifyPhonePage(
            verificationId: extra['verificationId'],
            phoneNumber: extra['phoneNumber'],
            name: extra['name'] as String?,
          ),
          type: SharedAxisTransitionType.vertical,
        );
      },
    ),
    GoRoute(
      path: '/auth/forgot-password',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: const ForgotPasswordPage(),
        type: SharedAxisTransitionType.vertical,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _fadeThroughPage(child: const MainNavigationPage()),
    ),
    GoRoute(
      path: '/settings/notifications',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: const NotificationsSettingsPage(),
        type: SharedAxisTransitionType.horizontal,
      ),
    ),
    GoRoute(
      path: '/settings/language',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: const LanguageSettingsPage(),
        type: SharedAxisTransitionType.horizontal,
      ),
    ),
    GoRoute(
      path: '/settings/edit-profile',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: const EditProfilePage(),
        type: SharedAxisTransitionType.horizontal,
      ),
    ),

    GoRoute(
      path: '/settings/terms',
      pageBuilder: (context, state) => _fadeThroughPage(child: const TermsConditionsPage()),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _fadeThroughPage(child: const SearchPage()),
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (context, state) => _fadeThroughPage(child: const CategoriesPage()),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _fadeThroughPage(child: const NotificationsPage()),
    ),
    GoRoute(
      path: '/create-service',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: ServiceCreationPage(
          createServiceUseCase: di.sl<CreateServiceUseCase>(),
        ),
        type: SharedAxisTransitionType.scaled,
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _fadeThroughPage(child: const ProfilePage()),
    ),
    GoRoute(
      path: '/addresses/map',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: const MapPickerPage(),
        type: SharedAxisTransitionType.scaled,
      ),
    ),
    GoRoute(
      path: '/services/my-services',
      pageBuilder: (context, state) => _fadeThroughPage(child: const MyServicesPage()),
    ),
    GoRoute(
      path: '/services/create',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: ServiceCreationPage(
          createServiceUseCase: di.sl<CreateServiceUseCase>(),
        ),
        type: SharedAxisTransitionType.scaled,
      ),
    ),
    GoRoute(
      path: '/services/:serviceId',
      pageBuilder: (context, state) {
        final serviceId = state.pathParameters['serviceId']!;
        final serviceEntity = state.extra as ServiceEntity?;
        final page = serviceEntity != null
            ? ServiceDetailsPage(service: serviceEntity)
            : ServiceDetailsPage(serviceId: serviceId);
        return _sharedAxisPage(
          child: page,
          type: SharedAxisTransitionType.scaled,
        );
      },
    ),
    GoRoute(
      path: '/services/edit/:serviceId',
      pageBuilder: (context, state) {
        final serviceId = state.pathParameters['serviceId']!;
        return _sharedAxisPage(
          child: ServiceEditPage(serviceId: serviceId),
          type: SharedAxisTransitionType.horizontal,
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  final bool dependenciesReady;
  
  const MyApp({super.key, this.dependenciesReady = true});

  @override
  Widget build(BuildContext context) {
    // Si las dependencias no están listas, mostrar una pantalla de error
    if (!dependenciesReady) {
      return const MaterialApp(
        title: AppConstants.appName,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error al inicializar la aplicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Por favor reinicia la aplicación'),
              ],
            ),
          ),
        ),
      );
    }
    
    // Dependencias listas, continuar con la aplicación normal
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(AuthStarted()),
        ),
        BlocProvider<SearchBloc>(
          create: (_) => di.sl<SearchBloc>()..add(LoadRecentSearches()),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => di.sl<HomeBloc>(),
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            imageStorageService: di.sl<ImageStorageService>(),
            firestoreService: di.sl<FirestoreService>(),
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<FavoritesBloc>(
          create: (_) => di.sl<FavoritesBloc>(),
        ),

      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return AnimatedTheme(
            data: themeState.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            duration: AppConstants.mediumAnimation,
            curve: Curves.easeInOut,
            child: MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
