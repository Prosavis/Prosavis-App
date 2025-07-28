import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/injection/injection_container.dart' as di;
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/pages/auth/onboarding_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Setup dependency injection (Firebase se inicializa aquí)
    await di.init();

    debugPrint('✅ Aplicación inicializada correctamente');
  } catch (e) {
    debugPrint('❌ Error al inicializar la aplicación: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (context) => di.sl<AuthBloc>()..add(AuthStarted()),
        child: const SplashWrapper(),
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startSplashAnimation();
  }

  void _startSplashAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show splash screen during initial loading
        if (state is AuthInitial || state is AuthLoading) {
          return _buildSplashScreen();
        }

        // Navigate based on auth state
        if (state is AuthAuthenticated) {
          return const HomePage();
        }

        // Check if it's first time opening the app
        return FutureBuilder<bool>(
          future: _isFirstTime(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSplashScreen();
            }

            final isFirstTime = snapshot.data ?? true;
            if (isFirstTime) {
              _setNotFirstTime(); // Mark as not first time
              return const OnboardingPage();
            }

            return const LoginPage();
          },
        );
      },
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withAlpha((0.8 * 255).round()),
              AppTheme.secondaryColor.withAlpha((0.6 * 255).round()),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animation
              ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handshake,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 8),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Conectando servicios de calidad',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                ),
              ),

              const SizedBox(height: 40),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(AppConstants.firstTimeKey);
  }

  Future<void> _setNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.firstTimeKey, false);
  }
}
