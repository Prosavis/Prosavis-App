import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

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
        colors: [AppTheme.accentColor, Colors.orange],
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
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withValues(alpha: 0.8),
            ],
          ),
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
                    _slideController.reset();
                    _slideController.forward();
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Symbols.handshake,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Conectando servicios',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
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
                      color: data.gradient.colors.first.withValues(alpha: 0.3),
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
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Description
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
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
                ? AppTheme.primaryColor
                : AppTheme.textTertiary.withValues(alpha: 0.3),
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
                  color: AppTheme.textSecondary,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
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
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.firstTimeKey, false);
    
    // Navigate using the BuildContext that has access to the BLoC
    // This will trigger AppNavigator to rebuild and show LoginPage
    if (mounted) {
      // Force a rebuild by calling setState on a parent widget
      // The AppNavigator will detect the change and navigate to LoginPage
      setState(() {
        // This will cause the widget to rebuild and the AppNavigator
        // will check isFirstTime again and navigate to LoginPage
      });
      
      // Alternative: Use Navigator but maintain the BLoC context
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
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