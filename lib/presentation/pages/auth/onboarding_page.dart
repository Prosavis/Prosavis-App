import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/brand_constants.dart';
import '../../widgets/brand/prosavis_logo.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  PageController pageController = PageController();
  int currentIndex = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      icon: Symbols.handyman,
      title: '¿Necesitas un servicio?',
      description: 'Encuentra profesionales calificados cerca de ti para cualquier trabajo que necesites.',
      gradient: AppTheme.primaryGradient,
    ),
    OnboardingData(
      icon: Symbols.work,
      title: '¿Ofreces servicios?',
      description: 'Conecta con clientes que buscan exactamente lo que ofreces y haz crecer tu negocio.',
      gradient: AppTheme.secondaryGradient,
    ),
    OnboardingData(
      icon: Symbols.verified_user,
      title: 'Seguridad garantizada',
      description: 'Todos nuestros prestadores están verificados. Trabaja con confianza y tranquilidad.',
      gradient: const LinearGradient(
        colors: [AppTheme.accentColor, Color(0xFFFF8C1A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _fadeController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    pageController.dispose();
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
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Page View
              Expanded(
                flex: 4,
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                    if (mounted) {
                      _slideController.reset();
                      _slideController.forward();
                    }
                  },
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingItem(onboardingData[index]);
                  },
                ),
              ),
              
              // Page Indicator
              _buildPageIndicator(),
              
              // Navigation Buttons
              _buildNavigationButtons(),
              
              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            // Logo de Prosavis
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: ProsavisLogo(
                  type: ProsavisLogoType.color,
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            Text(
              AppConstants.appName,
              style: BrandConstants.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingSmall / 2),
            
            Text(
              'Conectando servicios de calidad',
              style: BrandConstants.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingItem(OnboardingData data) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: data.gradient,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradient.colors.first.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  data.icon,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge * 2),
              
              // Title
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Description
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingData.length,
        (index) => AnimatedContainer(
          duration: AppConstants.shortAnimation,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? AppTheme.accentColor
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Row(
        children: [
          // Skip button
          if (currentIndex < onboardingData.length - 1)
            TextButton(
              onPressed: () => _completeOnboarding(),
              child: Text(
                'Saltar',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          
          const Spacer(),
          
          // Next/Get Started button
          ElevatedButton.icon(
            onPressed: currentIndex == onboardingData.length - 1
                ? _completeOnboarding
                : _nextPage,
            icon: Icon(
              currentIndex == onboardingData.length - 1
                  ? Symbols.login
                  : Symbols.arrow_forward,
            ),
            label: Text(
              currentIndex == onboardingData.length - 1
                  ? 'Comenzar'
                  : 'Siguiente',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    pageController.nextPage(
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.firstTimeKey, false);
    
    if (mounted) {
      context.go('/login');
    }
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

extension ColorValues on Color {
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    return Color.fromARGB(
      (alpha != null ? (alpha * 255).round() : this.alpha),
      (red != null ? (red * 255).round() : this.red),
      (green != null ? (green * 255).round() : this.green),
      (blue != null ? (blue * 255).round() : this.blue),
    );
  }
}
