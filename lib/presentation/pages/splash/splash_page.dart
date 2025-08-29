import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/themes/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> 
    with TickerProviderStateMixin {
  
  // Optimización: Un solo controlador para todas las animaciones
  late AnimationController _mainController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    
    // Optimización: Un solo controlador maestro para reducir overhead
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1800), // Duración total optimizada
      vsync: this,
    );
    if (AppConfig.enableSplashSound) {
      _audioPlayer = AudioPlayer();
    }

    // Optimización: Todas las animaciones usan el mismo controlador con intervalos
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutExpo),
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Optimización: Reducir delay inicial
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (mounted) {
      // Reproducir sonido de bienvenida de forma no bloqueante
      _playWelcomeSound();
      
      // Iniciar todas las animaciones con un solo controlador
      _mainController.forward();
      
      // Optimización: Navegación más rápida tras completar animaciones
      _mainController.addStatusListener(_onAnimationComplete);
    }
  }
  
  void _onAnimationComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      // Remover listener para evitar memory leaks
      _mainController.removeStatusListener(_onAnimationComplete);
      context.go('/home');
    }
  }

  void _playWelcomeSound() {
    if (!AppConfig.enableSplashSound) return;
    try {
      _audioPlayer
          ?.play(AssetSource('sounds/transition-fleeting.mp3'))
          .onError((error, stackTrace) {
        // Silencioso: no generar más logs ni alertas del sistema
      });
      if (!kIsWeb) {
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      // Silenciar errores de sonido en splash
    }
  }



  @override
  void dispose() {
    _mainController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.welcomeGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fondo animado sutil con Lottie (si el asset existe)
                const SizedBox(height: 40),
                // Logo con animación
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Texto del nombre con animación
                SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: _buildBrandText(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tagline con animación
                SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: _buildTagline(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Image.asset(
        'assets/branding/logos/logo-no-background.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildBrandText() {
    return Text(
      'Prosavis',
      style: GoogleFonts.inter(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: -1.0,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Conectando servicios de calidad',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}