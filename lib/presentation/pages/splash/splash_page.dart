import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../../core/themes/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para la animación de escala del logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Controlador para el fade general
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Controlador para la animación del texto
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Configurar animaciones
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Delay inicial para suavizar el inicio
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      // Reproducir sonido de bienvenida
      _playWelcomeSound();
      
      // Iniciar fade y escala del logo simultáneamente
      _fadeController.forward();
      _scaleController.forward();
      
      // Delay antes de mostrar el texto
      await Future.delayed(const Duration(milliseconds: 400));
      
      if (mounted) {
        _textController.forward();
        
        // Sonido adicional cuando aparece el texto
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _playTextSound();
        }
        
        // Esperar 2 segundos en total antes de navegar al home
        await Future.delayed(const Duration(milliseconds: 1400));
        
        if (mounted) {
          context.go('/home');
        }
      }
    }
  }

  void _playWelcomeSound() {
    try {
      // Sonido de éxito/bienvenida
      SystemSound.play(SystemSoundType.alert);
      
      // Vibración sutil para dispositivos móviles
      HapticFeedback.lightImpact();
    } catch (e) {
      // Si hay error, continuar sin sonido
      developer.log('Error reproduciendo sonido: $e');
    }
  }

  void _playTextSound() {
    try {
      // Sonido más sutil para la aparición del texto
      HapticFeedback.selectionClick();
    } catch (e) {
      // Si hay error, continuar sin sonido
      developer.log('Error reproduciendo vibración: $e');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _textController.dispose();
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
        'assets/images/logo-no-background.png',
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