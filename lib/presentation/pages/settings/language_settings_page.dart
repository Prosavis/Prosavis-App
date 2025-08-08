import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedLanguage = 'es';

  final List<Map<String, String>> _languages = [
    {
      'code': 'es',
      'name': 'Español',
      'nativeName': 'Español',
      'flag': '🇪🇸',
      'available': 'true',
    },
    {
      'code': 'en',
      'name': 'Inglés',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'available': 'false',
    },
    {
      'code': 'pt',
      'name': 'Portugués',
      'nativeName': 'Português',
      'flag': '🇧🇷',
      'available': 'false',
    },
    {
      'code': 'fr',
      'name': 'Francés',
      'nativeName': 'Français',
      'flag': '🇫🇷',
      'available': 'false',
    },
    {
      'code': 'it',
      'name': 'Italiano',
      'nativeName': 'Italiano',
      'flag': '🇮🇹',
      'available': 'false',
    },
    {
      'code': 'de',
      'name': 'Alemán',
      'nativeName': 'Deutsch',
      'flag': '🇩🇪',
      'available': 'false',
    },
    {
      'code': 'zh',
      'name': 'Chino',
      'nativeName': '中文',
      'flag': '🇨🇳',
      'available': 'false',
    },
    {
      'code': 'ja',
      'name': 'Japonés',
      'nativeName': '日本語',
      'flag': '🇯🇵',
      'available': 'false',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadCurrentLanguage();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Symbols.arrow_back,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Idioma',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona tu idioma preferido',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 32),

            // Lista de idiomas
            Column(
              children: _languages.map((language) {
                return Column(
                  children: [
                    _buildLanguageTile(language),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.info,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El cambio de idioma se aplicará después de reiniciar la aplicación.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Botón Aplicar (Deshabilitado)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Deshabilitado
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Aplicar Cambios',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? savedLanguage;

      if (user != null) {
        // Cargar desde Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('preferences')
            .get();

        if (doc.exists) {
          savedLanguage = doc.data()?['language'];
        }
      }

      // Si no hay idioma guardado en Firestore, cargar desde SharedPreferences
      if (savedLanguage == null) {
        final prefs = await SharedPreferences.getInstance();
        savedLanguage = prefs.getString('app_language');
      }

      // Si no hay idioma guardado, usar el idioma del sistema o español por defecto
      if (savedLanguage == null) {
        final systemLocale = PlatformDispatcher.instance.locale.languageCode;
        savedLanguage = _languages.any((l) => l['code'] == systemLocale) 
            ? systemLocale 
            : 'es';
      }

      if (mounted) {
        setState(() {
          _selectedLanguage = savedLanguage!;
        });
      }
    } catch (e) {
      debugPrint('Error cargando idioma: $e');
    }
  }

  Widget _buildLanguageTile(Map<String, String> language) {
    final bool isSelected = _selectedLanguage == language['code'];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (language['available'] == 'false') {
            _showComingSoonDialog(language['name']!);
          } else {
            setState(() {
              _selectedLanguage = language['code']!;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : AppTheme.getBorderColor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                language['flag']!,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language['name']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? AppTheme.primaryColor
                            : AppTheme.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          language['nativeName']!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        if (language['available'] == 'false') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Symbols.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String languageName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🌍',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El soporte para $languageName estará disponible pronto',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}