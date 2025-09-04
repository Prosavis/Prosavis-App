import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'dart:async';
import 'dart:ui';
import 'dart:developer' as developer;
import 'core/config/app_config.dart';
import 'firebase_options.dart';

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
import 'presentation/blocs/home/home_event.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'presentation/blocs/favorites/favorites_event.dart';
import 'presentation/blocs/favorites/favorites_state.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/review/review_bloc.dart';
import 'presentation/blocs/location/location_bloc.dart';
import 'data/services/image_storage_service.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/main/main_navigation_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/verify_phone_page.dart';
import 'presentation/pages/auth/forgot_password_page.dart';

import 'presentation/pages/settings/language_settings_page.dart';

import 'presentation/pages/settings/edit_profile_page.dart';
import 'presentation/pages/address/map_picker_page.dart';
import 'presentation/pages/settings/terms_conditions_page.dart';
import 'presentation/pages/settings/privacy_policy_page.dart';
import 'presentation/pages/search/search_page.dart';
import 'presentation/pages/categories/categories_page.dart';
import 'presentation/pages/support/support_page.dart';
import 'presentation/pages/profile/profile_page.dart';
import 'presentation/pages/services/service_creation_wizard_page.dart';
import 'presentation/pages/services/service_edit_wizard_page.dart';
import 'presentation/pages/services/my_services_page.dart';
import 'presentation/pages/services/service_details_page.dart';
import 'domain/entities/service_entity.dart';
import 'domain/usecases/services/create_service_usecase.dart';
import 'core/injection/injection_container.dart' as di;
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'core/services/haptics_service.dart';

void main() async {
  // Inicialización segura con manejo de errores
  runZonedGuarded<Future<void>>(() async {
    // Optimización: Defer first frame para inicialización más suave
    WidgetsFlutterBinding.ensureInitialized();
    
    // 🚀 OPTIMIZACIÓN: Usar fuentes locales Inter desde assets
    
    // 🚀 OPTIMIZACIÓN: Límite de caché de imágenes para listas largas (~192MB)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 192 << 20;
    
    // Inicializar Firebase PRIMERO
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configurar Crashlytics
    await _initializeCrashlytics();
    
    // Cargar variables de entorno si existe (para desarrollo local)
    try {
      await dotenv.load(fileName: '.env');
      if (AppConfig.enableDetailedLogs) developer.log('📁 Variables de entorno cargadas desde .env');
    } catch (_) {
      if (AppConfig.enableDetailedLogs) developer.log('⚠️ No se encontró archivo .env (normal en producción)');
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
        developer.log('✅ Aplicación iniciada con Firebase y Crashlytics configurados');
      }
      
    } catch (e, stackTrace) {
      developer.log('❌ Error crítico en inicialización: $e');
      developer.log('Stack trace: $stackTrace');
      
      // Reportar error a Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        fatal: true,
        information: ['Error crítico durante la inicialización de la aplicación'],
      );
      
      dependenciesInitialized = false;
    }
    
    runApp(MyApp(dependenciesReady: dependenciesInitialized));
  }, (error, stack) {
    // Capturar errores no manejados y enviarlos a Crashlytics
    developer.log('❌ Error no manejado capturado: $error');
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
      information: ['Error no manejado en la zona raíz de la aplicación'],
    );
  });
}

/// Inicializa Firebase Crashlytics con configuración optimizada para desarrollo y producción
Future<void> _initializeCrashlytics() async {
  try {
    // Configurar Crashlytics según el entorno
    if (AppConfig.isDevelopment) {
      // En desarrollo, deshabilitar la recolección automática para testing
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      developer.log('🔧 Crashlytics configurado para desarrollo (recolección deshabilitada)');
    } else {
      // En producción, habilitar recolección automática
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      developer.log('📊 Crashlytics configurado para producción (recolección habilitada)');
    }
    
    // Configurar manejo de errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log('🐛 Error de Flutter capturado: ${details.exception}');
      
      if (AppConfig.isDevelopment) {
        // En desarrollo, mostrar el error en consola
        FlutterError.presentError(details);
      } else {
        // En producción, enviar a Crashlytics
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    
    // Configurar manejo de errores de plataforma (iOS/Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log('⚡ Error de plataforma capturado: $error');
      
      if (!AppConfig.isDevelopment) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
          information: ['Error capturado desde PlatformDispatcher'],
        );
      }
      
      return true;
    };
    
    developer.log('✅ Crashlytics inicializado correctamente');
    
  } catch (e, stackTrace) {
    developer.log('❌ Error al inicializar Crashlytics: $e');
    developer.log('Stack trace: $stackTrace');
    // No podemos usar Crashlytics aquí porque falló la inicialización
  }
}

/// Optimización: Precargar activos críticos para mejorar rendimiento inicial
Future<void> _preloadCriticalAssets() async {
  // Optimización: Ejecutar en un aislamiento para no bloquear el hilo principal
  await Future.microtask(() async {
    // No precargar fuentes - Inter se carga automáticamente desde assets
    // Solo tareas mínimas que no bloqueen el primer frame
    developer.log('✅ Assets críticos optimizados para primer frame');
  });
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
      pageBuilder: (context, state) {
        final tabString = state.uri.queryParameters['tab'];
        final initialTab = int.tryParse(tabString ?? '0') ?? 0;
        return _fadeThroughPage(child: MainNavigationPage(initialTab: initialTab));
      },
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
      path: '/settings/privacy',
      pageBuilder: (context, state) => _fadeThroughPage(child: const PrivacyPolicyPage()),
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
      path: '/support',
      pageBuilder: (context, state) => _fadeThroughPage(child: const SupportPage()),
    ),
    GoRoute(
      path: '/create-service',
      pageBuilder: (context, state) => _sharedAxisPage(
        child: ServiceCreationWizardPage(
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
        child: ServiceCreationWizardPage(
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
          child: ServiceEditWizardPage(serviceId: serviceId),
          type: SharedAxisTransitionType.scaled,
        );
      },
    ),
  ],
);

class MyApp extends StatefulWidget {
  final bool dependenciesReady;
  
  const MyApp({super.key, this.dependenciesReady = true});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // 🚀 OPTIMIZACIÓN: Prewarm after first frame (evita jank en arranque)
    if (widget.dependenciesReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prewarmAboveTheFold();
      });
    }
  }
  
  /// Pre-carga datos "above the fold" después del primer frame
  void _prewarmAboveTheFold() {
    try {
      final context = this.context;
      if (!mounted) return;
      
      developer.log('🔥 Prewarm: Iniciando carga de datos above-the-fold');
      
      // Pre-warm imágenes críticas del branding (async, no bloquea)
      _precacheHeroImages(context);
      
      // Disparar carga de servicios home sin bloquear UI
      context.read<HomeBloc>().add(LoadHomeServices());
      
    } catch (e) {
      developer.log('⚠️ Error en prewarm above-the-fold: $e');
    }
  }
  
  /// Pre-cachea imágenes críticas del branding y hero
  void _precacheHeroImages(BuildContext context) {
    developer.log('🖼️ Precaching hero images...');
    
    // Lista de imágenes críticas para precarga
    const criticalImages = [
      'assets/branding/logos/logo-color.png',
      'assets/branding/logos/logo-icon-clean.png',
      'assets/branding/logos/logo-no-background.png',
    ];
    
    // Precache en paralelo (no await para no bloquear)
    for (final imagePath in criticalImages) {
      precacheImage(AssetImage(imagePath), context).catchError((e) {
        developer.log('⚠️ Error precaching $imagePath: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si las dependencias no están listas, mostrar una pantalla de error
    if (!widget.dependenciesReady) {
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), // Corporativo
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
        BlocProvider<ReviewBloc>(
          create: (_) => di.sl<ReviewBloc>(),
        ),
        BlocProvider<LocationBloc>(
          create: (_) => di.sl<LocationBloc>(),
        ),

      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          // Cargar favoritos automáticamente cuando el usuario se autentica
          if (authState is AuthAuthenticated) {
            final favoritesBloc = context.read<FavoritesBloc>();
            // Solo cargar si no están ya cargados
            if (favoritesBloc.state is FavoritesInitial) {
              favoritesBloc.add(LoadUserFavorites(authState.user.id));
            }
          } else if (authState is AuthUnauthenticated) {
            // Limpiar favoritos cuando el usuario cierra sesión
            final favoritesBloc = context.read<FavoritesBloc>();
            favoritesBloc.add(const FavoritesStreamUpdated([]));
          }
        },
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
      ),
    );
  }
}
