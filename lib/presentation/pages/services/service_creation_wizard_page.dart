import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/service_refresh_notifier.dart';
import '../../../domain/usecases/services/create_service_usecase.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/image_storage_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/image_picker_bottom_sheet.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../widgets/tutorial/tutorial_content.dart';

// Definición de un paso del wizard
class ServiceCreationStep {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isRequired;
  final Widget Function(ServiceCreationWizardPageState state) builder;
  final bool Function(ServiceCreationWizardPageState state) validator;

  const ServiceCreationStep({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isRequired,
    required this.builder,
    required this.validator,
  });
}

class ServiceCreationWizardPage extends StatefulWidget {
  final CreateServiceUseCase createServiceUseCase;
  
  const ServiceCreationWizardPage({super.key, required this.createServiceUseCase});

  @override
  State<ServiceCreationWizardPage> createState() => ServiceCreationWizardPageState();
}

class ServiceCreationWizardPageState extends State<ServiceCreationWizardPage>
    with TickerProviderStateMixin {
  
  // Controladores de animación
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Variables de estado
  int _currentStepIndex = 0;
  bool _isCreatingService = false;
  bool _shouldShowTutorial = false;
  bool _isTutorialShowing = false;
  
  // Controladores de formulario
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _customSkillController = TextEditingController();
  
  // Variables de estado del formulario
  String? _selectedCategory;
  String _priceType = 'fixed';
  String? _mainImageUrl;
  File? _mainImageFile;
  // Variables para pasos adicionales
  final List<File> _newImages = [];
  final List<String> _selectedSkills = [];
  final List<String> _customSkills = [];
  final List<String> _availableDays = [];
  String? _selectedExperienceLevel;
  
  // Variables de ubicación
  double? _latitude;
  double? _longitude;

  // Datos constantes
  final List<String> _priceTypes = ['fixed', 'daily', 'negotiable'];
  final List<String> _weekDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];
  final List<String> _experienceLevels = [
    'Principiante (menos de 1 año)',
    'Intermedio (1-3 años)',
    'Avanzado (3-5 años)',
    'Experto (más de 5 años)',
  ];
  final List<String> _commonSkills = [
    'Experiencia certificada',
    'Trabajo en fin de semana',
    'Servicio de emergencia',
    'Garantía incluida',
    'Materiales incluidos',
    'Presupuesto gratuito',
    'Referencias disponibles',
    'Seguro de responsabilidad',
  ];

  // Definición de los pasos del wizard
  late List<ServiceCreationStep> _steps;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSteps();
    _loadUserWhatsAppNumber();
    _checkTutorialStatus();
  }

  void _loadUserWhatsAppNumber() {
    // Cargar el número de WhatsApp del usuario automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && 
          authState.user.phoneNumber != null && 
          authState.user.phoneNumber!.isNotEmpty) {
        
        final String phoneNumber = authState.user.phoneNumber!;
        // Si el número empieza con +57 y tiene al menos 13 caracteres ('+57' + 10 dígitos)
        if (phoneNumber.startsWith('+57') && phoneNumber.length >= 13) {
          // Remover el +57 para mostrar solo el número
          _whatsappController.text = phoneNumber.substring(3);
        }
      }
    });
  }

  void _checkTutorialStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final shouldShow = await TutorialService.shouldShowServiceCreationTutorial(authState.user.id);
      if (mounted) {
        setState(() {
          _shouldShowTutorial = shouldShow;
        });
        
        // Mostrar tutorial del primer paso si debe mostrarse
        if (_shouldShowTutorial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showTutorialForCurrentStep();
          });
        }
      }
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeSteps() {
    _steps = [
      // Paso 1: Categoría (Obligatorio)
      ServiceCreationStep(
        id: 'category',
        title: 'Categoría',
        subtitle: 'Selecciona la categoría de tu servicio',
        icon: Symbols.category,
        isRequired: true,
        builder: _buildCategoryStep,
        validator: (state) => state._selectedCategory != null && state._selectedCategory!.isNotEmpty,
      ),
      
      // Paso 2: Información básica (Obligatorio)
      ServiceCreationStep(
        id: 'basic_info',
        title: 'Información básica',
        subtitle: 'Describe tu servicio con un título y descripción',
        icon: Symbols.edit_note,
        isRequired: true,
        builder: _buildBasicInfoStep,
        validator: (state) => 
          state._titleController.text.trim().length >= 5 && 
          state._descriptionController.text.trim().length >= 20,
      ),
      
      // Paso 3: Precio (Obligatorio)
      ServiceCreationStep(
        id: 'pricing',
        title: 'Precio',
        subtitle: 'Define el precio de tu servicio',
        icon: Symbols.payments,
        isRequired: true,
        builder: _buildPricingStep,
        validator: (state) => 
          state._priceType == 'negotiable' || 
          (state._priceController.text.isNotEmpty && double.tryParse(state._priceController.text) != null),
      ),
      
      // Paso 4: Imagen principal (Opcional)
      ServiceCreationStep(
        id: 'main_image',
        title: 'Imagen principal',
        subtitle: 'Añade una imagen que represente tu servicio (opcional)',
        icon: Symbols.image,
        isRequired: false,
        builder: _buildMainImageStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 5: Experiencia (Opcional)
      ServiceCreationStep(
        id: 'experience',
        title: 'Experiencia',
        subtitle: 'Cuéntanos sobre tu experiencia',
        icon: Symbols.star,
        isRequired: false,
        builder: _buildExperienceStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 6: Contacto (Opcional)
      ServiceCreationStep(
        id: 'contact',
        title: 'Contacto',
        subtitle: 'Formas de contacto adicionales',
        icon: Symbols.contact_phone,
        isRequired: false,
        builder: _buildContactStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 7: Disponibilidad (Opcional)
      ServiceCreationStep(
        id: 'availability',
        title: 'Disponibilidad',
        subtitle: 'Días en los que ofreces tu servicio',
        icon: Symbols.schedule,
        isRequired: false,
        builder: _buildAvailabilityStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 8: Habilidades (Opcional)
      ServiceCreationStep(
        id: 'skills',
        title: 'Habilidades especiales',
        subtitle: 'Características que te destacan',
        icon: Symbols.verified,
        isRequired: false,
        builder: _buildSkillsStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 9: Imágenes adicionales (Opcional)
      ServiceCreationStep(
        id: 'additional_images',
        title: 'Imágenes adicionales',
        subtitle: 'Galería para mostrar tu trabajo',
        icon: Symbols.photo_library,
        isRequired: false,
        builder: _buildAdditionalImagesStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 10: Ubicación (Opcional)
      ServiceCreationStep(
        id: 'location',
        title: 'Ubicación',
        subtitle: 'Dónde ofreces tu servicio',
        icon: Symbols.location_on,
        isRequired: false,
        builder: _buildLocationStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 11: Resumen (Obligatorio)
      ServiceCreationStep(
        id: 'summary',
        title: 'Resumen',
        subtitle: 'Revisa y confirma tu servicio',
        icon: Symbols.check_circle,
        isRequired: true,
        builder: _buildSummaryStep,
        validator: (state) => true, // Siempre válido, es el paso final
      ),
    ];
  }

  @override
  void dispose() {
    // Detener animaciones antes de dispose
    if (_slideController.isAnimating) {
      _slideController.stop();
    }
    if (_fadeController.isAnimating) {
      _fadeController.stop();
    }
    
    _slideController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _tiktokController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: _buildStepContent(),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentStep = _steps[_currentStepIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Symbols.arrow_back,
              color: AppTheme.getTextPrimary(context),
            ),
            onPressed: _currentStepIndex > 0 ? _goToPreviousStep : () => context.go('/home'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStep.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                if (currentStep.subtitle != null)
                  Text(
                    currentStep.subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
              ],
            ),
          ),
          if (!currentStep.isRequired)
            TextButton(
              onPressed: _skipCurrentStep,
              child: Text(
                'Saltar',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentStepIndex + 1) / _steps.length,
                  backgroundColor: AppTheme.getTextSecondary(context).withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentStepIndex + 1} de ${_steps.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _steps[_currentStepIndex].isRequired 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _steps[_currentStepIndex].isRequired ? 'Obligatorio' : 'Opcional',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _steps[_currentStepIndex].isRequired 
                        ? AppTheme.primaryColor
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: _steps[_currentStepIndex].builder(this),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final currentStep = _steps[_currentStepIndex];
    final isStepValid = currentStep.validator(this);
    final isLastStep = _currentStepIndex == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStepIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                child: Text(
                  'Anterior',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStepIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isStepValid || !currentStep.isRequired ? 
                (isLastStep ? _createService : _goToNextStep) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppTheme.getTextSecondary(context).withValues(alpha: 0.3),
              ),
              child: _isCreatingService
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isLastStep ? 'Crear servicio' : 'Continuar',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de navegación
  void _goToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _animateToStep(_currentStepIndex + 1);
    }
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0) {
      _animateToStep(_currentStepIndex - 1);
    }
  }

  void _skipCurrentStep() {
    if (!_steps[_currentStepIndex].isRequired) {
      _goToNextStep();
    }
  }

  void _animateToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _steps.length) return;
    
    setState(() {
      _currentStepIndex = stepIndex;
    });

    // Reiniciar animaciones de forma segura
    if (_slideController.isAnimating) {
      _slideController.stop();
    }
    if (_fadeController.isAnimating) {
      _fadeController.stop();
    }
    
    _slideController.reset();
    _fadeController.reset();
    
    _slideController.forward();
    _fadeController.forward();

    // Feedback háptico
    HapticsService.onNavigation();
    
    // Mostrar tutorial del nuevo paso si corresponde
    if (_shouldShowTutorial && !_isTutorialShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorialForCurrentStep();
      });
    }
  }

  // Constructores de pasos
  Widget _buildCategoryStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              children: [
                const Icon(
                  Symbols.category,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Qué tipo de servicio ofreces?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona la categoría que mejor describe tu servicio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría del servicio',
                    prefixIcon: const Icon(
                      Symbols.work,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  items: AppConstants.serviceCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['name'] as String,
                      child: Row(
                        children: [
                          Icon(category['icon'] as IconData, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(category['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    HapticsService.onNavigation();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              children: [
                const Icon(
                  Symbols.edit_note,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cuéntanos sobre tu servicio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Un buen título y descripción atraerán más clientes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título del servicio',
                    hintText: 'Ej: Plomería residencial',
                    prefixIcon: const Icon(
                      Symbols.title,
                      color: AppTheme.primaryColor,
                    ),
                    helperText: 'Mínimo 5 caracteres',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  maxLength: 60,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Describe tu servicio en detalle...',
                    prefixIcon: const Icon(
                      Symbols.description,
                      color: AppTheme.primaryColor,
                    ),
                    helperText: 'Mínimo 20 caracteres',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              children: [
                const Icon(
                  Symbols.payments,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Cuánto cobras por tu servicio?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Define cómo cobras por tu trabajo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _priceType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de precio',
                    prefixIcon: const Icon(
                      Symbols.schedule,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  items: _priceTypes.map((type) {
                    final displayName = {
                      'fixed': 'Por servicio',
                      'daily': 'Por día',
                      'negotiable': 'Negociable',
                    }[type] ?? type;
                    
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _priceType = value!);
                    HapticsService.onNavigation();
                  },
                ),
                const SizedBox(height: 16),
                if (_priceType != 'negotiable')
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Precio (\$)',
                      hintText: '0.00',
                      prefixIcon: const Icon(
                        Symbols.attach_money,
                        color: AppTheme.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                  ),
                if (_priceType == 'negotiable')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Symbols.info,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Los clientes podrán contactarte para negociar el precio',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              children: [
                const Icon(
                  Symbols.image,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Imagen principal del servicio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Una buena imagen aumenta la confianza de los clientes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_mainImageFile != null || _mainImageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: _mainImageFile != null
                            ? FileImage(_mainImageFile!)
                            : NetworkImage(_mainImageUrl!) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: IconButton(
                              icon: const Icon(Symbols.delete, color: Colors.white),
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _mainImageFile = null;
                                    _mainImageUrl = null;
                                  });
                                  HapticsService.onNavigation();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _selectMainImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Symbols.add_a_photo,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Toca para añadir imagen',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Recomendado: 1080x1080px',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_mainImageFile != null || _mainImageUrl != null)
                  const SizedBox(height: 16),
                if (_mainImageFile != null || _mainImageUrl != null)
                  ElevatedButton.icon(
                    onPressed: _selectMainImage,
                    icon: const Icon(Symbols.edit),
                    label: const Text('Cambiar imagen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Symbols.star,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cuéntanos sobre tu experiencia',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto ayudará a los clientes a conocer tu trayectoria profesional.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Nivel de experiencia
                Text(
                  'Nivel de experiencia',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedExperienceLevel,
                      hint: Text(
                        'Selecciona tu nivel de experiencia',
                        style: GoogleFonts.inter(
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                      isExpanded: true,
                      items: _experienceLevels.map((level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(
                            level,
                            style: GoogleFonts.inter(
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedExperienceLevel = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Descripción de experiencia
                Text(
                  'Describe tu experiencia',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _experienceController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Cuéntanos sobre tu experiencia, trabajos anteriores, logros destacados...',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.getTextSecondary(context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Symbols.contact_phone,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Información de contacto',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega formas adicionales para que los clientes puedan contactarte.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                // WhatsApp
                _buildWhatsAppField(),
                const SizedBox(height: 16),
                
                // Teléfono 1
                _buildPhoneField(
                  'Teléfono principal',
                  _phone1Controller,
                  'Ej: 1 234 5678 o móvil',
                ),
                const SizedBox(height: 16),
                
                // Teléfono 2
                _buildPhoneField(
                  'Teléfono secundario',
                  _phone2Controller,
                  'Ej: 300 987 6543',
                ),
                const SizedBox(height: 16),
                
                // Información explicativa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.info,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¿Por qué separar WhatsApp de las llamadas?',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Puedes usar el mismo número de WhatsApp aquí si prefieres\n• O separar: WhatsApp para mensajes y estos para llamadas\n• Útil si tienes línea fija y móvil, o números comerciales específicos',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Instagram
                _buildContactFieldWithCustomIcon(
                  'Instagram',
                  _instagramController,
                  'Ej: @tu_usuario',
                  'assets/icons/social/instagram.webp',
                ),
                const SizedBox(height: 16),
                
                // X (Twitter)
                _buildContactFieldWithCustomIcon(
                  'X (Twitter)',
                  _xController,
                  'Ej: @tu_usuario',
                  'assets/icons/social/x.png',
                ),
                const SizedBox(height: 16),
                
                // TikTok
                _buildContactFieldWithCustomIcon(
                  'TikTok',
                  _tiktokController,
                  'Ej: @tu_usuario',
                  'assets/icons/social/tiktok.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildWhatsAppField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WhatsApp',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Indicativo fijo +57
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.getBorderColor(context)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                color: AppTheme.getBackgroundColor(context),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/social/whatsapp.webp',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Symbols.phone_android,
                        size: 24,
                        color: AppTheme.getTextSecondary(context),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+57',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            // Campo del número
            Expanded(
              child: TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                maxLength: 10, // Solo 10 dígitos para Colombia
                decoration: InputDecoration(
                  hintText: '300 123 4567',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.getTextSecondary(context),
                  ),
                  counterText: '', // Ocultar contador de caracteres
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.inter(
                  color: AppTheme.getTextPrimary(context),
                ),
                inputFormatters: [
                  // Solo permitir números
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Se cargó automáticamente tu número de perfil. Solo funciona en Colombia (+57)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Indicativo fijo +57
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.getBorderColor(context)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                color: AppTheme.getBackgroundColor(context),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.call,
                    size: 24,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+57',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            // Campo del número
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10, // Solo 10 dígitos para Colombia (móvil) o hasta 7 para fijo
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.getTextSecondary(context),
                  ),
                  counterText: '', // Ocultar contador de caracteres
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.inter(
                  color: AppTheme.getTextPrimary(context),
                ),
                inputFormatters: [
                  // Solo permitir números
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactFieldWithCustomIcon(String label, TextEditingController controller, String hint, String iconAssetPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppTheme.getTextSecondary(context),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                iconAssetPath,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback a un ícono genérico si la imagen falla al cargar
                  return Icon(
                    Symbols.alternate_email,
                    size: 24,
                    color: AppTheme.getTextSecondary(context),
                  );
                },
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.inter(
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Symbols.schedule,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Disponibilidad',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona los días en los que ofreces tu servicio.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Días disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Lista de días de la semana
                ...(_weekDays.map((day) => _buildDayCheckbox(day)).toList()),
                
                const SizedBox(height: 24),
                
                // Nota adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Symbols.info,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los clientes podrán contactarte en los días seleccionados. Puedes coordinar horarios específicos directamente con ellos.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCheckbox(String day) {
    final isSelected = _availableDays.contains(day);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.getBorderColor(context),
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _availableDays.add(day);
            } else {
              _availableDays.remove(day);
            }
          });
        },
        title: Text(
          day,
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? AppTheme.primaryColor : AppTheme.getTextPrimary(context),
          ),
        ),
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSkillsStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Symbols.verified,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Habilidades especiales',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona las características que te destacan como profesional.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Selecciona tus habilidades',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Grid de habilidades
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _commonSkills.length,
                  itemBuilder: (context, index) {
                    final skill = _commonSkills[index];
                    final isSelected = _selectedSkills.contains(skill);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : null,
                          border: Border.all(
                            color: isSelected 
                              ? AppTheme.primaryColor 
                              : AppTheme.getBorderColor(context),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Symbols.check_circle : Symbols.circle,
                              size: 16,
                              color: isSelected 
                                ? AppTheme.primaryColor 
                                : AppTheme.getTextSecondary(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                skill,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                  color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.getTextPrimary(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Campo para agregar habilidades personalizadas
                Text(
                  'Agregar habilidad personalizada',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSkillController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Soldadura especializada, Diseño 3D...',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.getTextSecondary(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addCustomSkill,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Symbols.add,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_selectedSkills.isNotEmpty || _customSkills.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Symbols.check_circle,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Habilidades seleccionadas (${_selectedSkills.length + _customSkills.length})',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Habilidades predefinidas
                            ..._selectedSkills.map((skill) => 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  skill,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Habilidades personalizadas
                            ..._customSkills.map((skill) => 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      skill,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeCustomSkill(skill),
                                      child: const Icon(
                                        Symbols.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomSkill() {
    final customSkill = _customSkillController.text.trim();
    if (customSkill.isNotEmpty && 
        !_customSkills.contains(customSkill) && 
        !_selectedSkills.contains(customSkill)) {
      setState(() {
        _customSkills.add(customSkill);
        _customSkillController.clear();
      });
    }
  }

  void _removeCustomSkill(String skill) {
    setState(() {
      _customSkills.remove(skill);
    });
  }

  // Método para seleccionar ubicación en mapa
  Future<void> _selectLocationOnMap() async {
    try {
      final result = await context.push('/addresses/map');
      if (!mounted || result == null) return;
      
      final map = result as Map<String, dynamic>;
      setState(() {
        _latitude = (map['latitude'] as num?)?.toDouble();
        _longitude = (map['longitude'] as num?)?.toDouble();
        final addr = map['address'] as String?;
        if (addr != null && addr.isNotEmpty) {
          _addressController.text = addr;
        }
      });
      
      await HapticsService.onNavigation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAdditionalImagesStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Symbols.photo_library,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Galería de imágenes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Añade imágenes adicionales para mostrar tu trabajo y atraer más clientes.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón para añadir imágenes
                Center(
                  child: GestureDetector(
                    onTap: _newImages.length >= 6 ? null : _selectAdditionalImages,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _newImages.length >= 6 
                              ? AppTheme.getTextSecondary(context) 
                              : AppTheme.primaryColor,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _newImages.length >= 6 
                            ? AppTheme.getTextSecondary(context).withValues(alpha: 0.05)
                            : AppTheme.primaryColor.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.add_photo_alternate,
                            size: 40,
                            color: _newImages.length >= 6 
                                ? AppTheme.getTextSecondary(context) 
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _newImages.length >= 6 ? 'Límite alcanzado' : 'Añadir imágenes',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _newImages.length >= 6 
                                  ? AppTheme.getTextSecondary(context) 
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _newImages.length >= 6 
                                ? 'Máximo 6 imágenes permitidas'
                                : 'Toca para seleccionar imágenes (máx. 6)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.getTextSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_newImages.length}/6 imágenes',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _newImages.length >= 6 
                                  ? Colors.orange 
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Grid de imágenes seleccionadas
                if (_newImages.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Imágenes seleccionadas (${_newImages.length})',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _newImages.length,
                    itemBuilder: (context, index) {
                      final image = _newImages[index];
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.getBorderColor(context),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _newImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Symbols.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                
                // Información adicional
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.tips_and_updates,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Consejos para mejores resultados',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Utiliza imágenes de alta calidad que muestren tu trabajo\n• Máximo 6 imágenes por servicio\n• Cada imagen puede pesar hasta 10MB\n• Formatos permitidos: JPG, PNG, WebP',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _selectAdditionalImages() async {
    try {
      // Verificar límite antes de abrir el selector
      if (_newImages.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has alcanzado el límite de 6 imágenes'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await HapticsService.onNavigation();
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ImagePickerBottomSheet(
          onImageSelected: (File image) {
            setState(() {
              // Solo agregar si no se ha alcanzado el límite
              if (_newImages.length < 6) {
                _newImages.add(image);
              }
            });
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imágenes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLocationStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Symbols.location_on,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubicación del servicio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Especifica dónde ofreces tu servicio para ayudar a los clientes a encontrarte.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Campo de dirección
                Text(
                  'Dirección o zona de servicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Campo de dirección con botón de mapa
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Bogotá, Colombia o tu barrio específico',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.getTextSecondary(context),
                          ),
                          prefixIcon: Icon(
                            Symbols.place,
                            color: AppTheme.getTextSecondary(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          color: AppTheme.getTextPrimary(context),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Botón de Google Maps
                    GestureDetector(
                      onTap: _selectLocationOnMap,
                      child: Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/social/Google_Maps_icon__2020_.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Symbols.map,
                                color: Colors.white,
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Información sobre selección en mapa
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Symbols.info,
                      size: 16,
                      color: AppTheme.getTextSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Toca el ícono de Google Maps para seleccionar tu ubicación exacta',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Mostrar coordenadas si están disponibles
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Symbols.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ubicación seleccionada: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Opciones de alcance del servicio
                Text(
                  'Tipo de servicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Opciones con radiobuttons
                _buildServiceTypeOption(
                  'A domicilio',
                  'Voy al lugar del cliente',
                  Symbols.directions_car,
                  'home_service',
                ),
                const SizedBox(height: 12),
                _buildServiceTypeOption(
                  'En mi local',
                  'Los clientes vienen a mi ubicación',
                  Symbols.store,
                  'in_location',
                ),
                const SizedBox(height: 12),
                _buildServiceTypeOption(
                  'Ambos',
                  'Ofrezco el servicio en ambas modalidades',
                  Symbols.swap_horiz,
                  'both',
                ),
                
                const SizedBox(height: 24),
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Symbols.info,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Esta información ayuda a los clientes a saber si tu servicio está disponible en su zona.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _selectedServiceType = 'home_service';

  Widget _buildServiceTypeOption(String title, String subtitle, IconData icon, String value) {
    final isSelected = _selectedServiceType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedServiceType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.getTextSecondary(context),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.getBorderColor(context),
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep(ServiceCreationWizardPageState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            child: Column(
              children: [
                const Icon(
                  Symbols.check_circle,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Listo para publicar!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu servicio antes de publicarlo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Información básica
                _buildSummaryItem(
                  icon: Symbols.category,
                  title: 'Categoría',
                  value: _selectedCategory ?? 'No seleccionada',
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  icon: Symbols.title,
                  title: 'Título',
                  value: _titleController.text.trim().isEmpty 
                      ? 'Sin título' 
                      : _titleController.text.trim(),
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  icon: Symbols.description,
                  title: 'Descripción',
                  value: _descriptionController.text.trim().isEmpty 
                      ? 'Sin descripción' 
                      : _descriptionController.text.trim(),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  icon: Symbols.payments,
                  title: 'Precio',
                  value: _priceType == 'negotiable' 
                      ? 'Negociable' 
                      : _priceController.text.isEmpty 
                          ? 'No definido'
                          : '\$${_priceController.text}',
                ),
                
                // Imagen principal
                const SizedBox(height: 12),
                _buildSummaryImageItem(),
                
                // Experiencia
                if (_selectedExperienceLevel != null || _experienceController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    icon: Symbols.star,
                    title: 'Experiencia',
                    value: _buildExperienceValue(),
                    maxLines: 3,
                  ),
                ],
                
                // Contacto
                if (_hasContactInfo()) ...[
                  const SizedBox(height: 12),
                  _buildSummaryContactItem(),
                ],
                
                // Disponibilidad
                if (_availableDays.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    icon: Symbols.schedule,
                    title: 'Disponibilidad',
                    value: _availableDays.join(', '),
                    maxLines: 2,
                  ),
                ],
                
                // Habilidades
                if (_selectedSkills.isNotEmpty || _customSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    icon: Symbols.verified,
                    title: 'Habilidades especiales',
                    value: [..._selectedSkills, ..._customSkills].join(', '),
                    maxLines: 3,
                  ),
                ],
                
                // Imágenes adicionales
                if (_newImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryAdditionalImages(),
                ],
                
                // Ubicación
                if (_addressController.text.trim().isNotEmpty || _selectedServiceType.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryLocationItem(),
                ],
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Symbols.info,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Al crear tu servicio, será visible para todos los usuarios de la plataforma',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryImageItem() {
    if (_mainImageFile != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.getTextSecondary(context).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Symbols.image,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imagen principal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _mainImageFile!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return _buildSummaryItem(
      icon: Symbols.image,
      title: 'Imagen principal',
      value: _mainImageUrl != null ? 'Imagen agregada' : 'Sin imagen',
    );
  }

  Widget _buildSummaryAdditionalImages() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.getTextSecondary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.photo_library,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Imágenes adicionales',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_newImages.length} imágenes agregadas',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _newImages[index],
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildExperienceValue() {
    String experience = '';
    if (_selectedExperienceLevel != null) {
      experience += _selectedExperienceLevel!;
    }
    if (_experienceController.text.trim().isNotEmpty) {
      if (experience.isNotEmpty) experience += ' - ';
      experience += _experienceController.text.trim();
    }
    return experience.isEmpty ? 'No especificada' : experience;
  }

    bool _hasContactInfo() {
    return _whatsappController.text.trim().isNotEmpty ||
        _phone1Controller.text.trim().isNotEmpty ||
        _phone2Controller.text.trim().isNotEmpty ||
        _instagramController.text.trim().isNotEmpty ||
        _xController.text.trim().isNotEmpty ||
        _tiktokController.text.trim().isNotEmpty;
  }

  String _getServiceTypeText() {
    switch (_selectedServiceType) {
      case 'home':
        return 'Servicio a domicilio';
      case 'location':
        return 'Servicio en mi local';
      case 'both':
        return 'Ambas modalidades';
      default:
        return 'No especificado';
    }
  }

  Widget _buildSummaryLocationItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.location_on,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ubicación y modalidad',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Dirección
          if (_addressController.text.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.place,
                  color: AppTheme.getTextSecondary(context),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _addressController.text.trim(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Coordenadas si están disponibles
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Symbols.my_location,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coordenadas: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Tipo de servicio
          if (_selectedServiceType.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedServiceType == 'home' 
                        ? Symbols.home 
                        : _selectedServiceType == 'location' 
                            ? Symbols.store 
                            : Symbols.swap_horiz,
                    color: AppTheme.primaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getServiceTypeText(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryContactItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.getTextSecondary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.contact_phone,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Contacto adicional',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // WhatsApp
          if (_whatsappController.text.trim().isNotEmpty)
            _buildContactSummaryRow(
              'assets/icons/social/whatsapp.webp',
              'WhatsApp',
              '+57 ${_whatsappController.text.trim()}',
            ),
          
          // Teléfono 1
          if (_phone1Controller.text.trim().isNotEmpty)
            _buildContactSummaryRowWithIcon(
              Symbols.call,
              'Teléfono',
              '+57 ${_phone1Controller.text.trim()}',
            ),
          
          // Teléfono 2
          if (_phone2Controller.text.trim().isNotEmpty)
            _buildContactSummaryRowWithIcon(
              Symbols.call,
              'Teléfono 2',
              '+57 ${_phone2Controller.text.trim()}',
            ),
          
          // Instagram
          if (_instagramController.text.trim().isNotEmpty)
            _buildContactSummaryRow(
              'assets/icons/social/instagram.webp',
              'Instagram',
              _instagramController.text.trim(),
            ),
          
          // X (Twitter)
          if (_xController.text.trim().isNotEmpty)
            _buildContactSummaryRow(
              'assets/icons/social/x.png',
              'X',
              _xController.text.trim(),
            ),
          
          // TikTok
          if (_tiktokController.text.trim().isNotEmpty)
            _buildContactSummaryRow(
              'assets/icons/social/tiktok.png',
              'TikTok',
              _tiktokController.text.trim(),
            ),
        ],
      ),
    );
  }

  Widget _buildContactSummaryRow(String iconAssetPath, String platform, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Image.asset(
            iconAssetPath,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Symbols.alternate_email,
                size: 16,
                color: AppTheme.getTextSecondary(context),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            '$platform: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.getTextPrimary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSummaryRowWithIcon(IconData icon, String platform, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.getTextSecondary(context),
          ),
          const SizedBox(width: 8),
          Text(
            '$platform: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.getTextPrimary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.getTextSecondary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  Widget _buildStepCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  void _selectMainImage() async {
    if (!mounted) return;
    
    HapticsService.onNavigation();
    
    try {
      ImagePickerBottomSheet.show(
        context,
        onImageSelected: (file) {
          if (mounted) {
            setState(() {
              _mainImageFile = file;
              _mainImageUrl = null;
            });
          }
        },
        hasCurrentImage: _mainImageFile != null || _mainImageUrl != null,
        onRemoveImage: () {
          if (mounted) {
            setState(() {
              _mainImageFile = null;
              _mainImageUrl = null;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir selector de imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // MÉTODOS DE TUTORIAL
  void _showTutorialForCurrentStep() {
    if (!_shouldShowTutorial || _isTutorialShowing) return;
    
    final tutorialStep = TutorialContent.getStepTutorial(_currentStepIndex);
    if (tutorialStep != null) {
      setState(() {
        _isTutorialShowing = true;
      });
      
      TutorialHelper.showTutorial(
        context: context,
        tutorialStep: tutorialStep,
        isLastStep: _currentStepIndex == _steps.length - 1,
        onContinue: () {
          setState(() {
            _isTutorialShowing = false;
          });
          
          // Si es el último paso, marcar tutorial como visto
          if (_currentStepIndex == _steps.length - 1) {
            TutorialService.markServiceCreationTutorialAsSeen();
            setState(() {
              _shouldShowTutorial = false;
            });
          }
        },
        onSkip: () {
          setState(() {
            _isTutorialShowing = false;
            _shouldShowTutorial = false;
          });
          TutorialService.markServiceCreationTutorialAsSeen();
        },
      );
    }
  }



  // Método para crear el servicio
  Future<void> _createService() async {
    if (!mounted) return;
    
    setState(() {
      _isCreatingService = true;
    });
    
    try {
      // Obtener el usuario autenticado
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      String? mainImageUrl;
      final List<String> additionalImageUrls = [];
      
      // Subir imagen principal si existe
      if (_mainImageFile != null) {
        final imageStorageService = ImageStorageService();
        // Usar un ID temporal para la subida, se actualizará después
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        mainImageUrl = await imageStorageService.uploadServiceImage(tempId, _mainImageFile!);
        
        if (mainImageUrl == null) {
          throw Exception('Error al subir la imagen principal');
        }
      }

      // Subir imágenes adicionales si existen
      if (_newImages.isNotEmpty) {
        final imageStorageService = ImageStorageService();
        
        for (int i = 0; i < _newImages.length; i++) {
          try {
            // Usar un ID temporal único para cada imagen
            final tempId = '${DateTime.now().millisecondsSinceEpoch}_$i';
            final imageUrl = await imageStorageService.uploadServiceImage(tempId, _newImages[i]);
            
            if (imageUrl != null) {
              additionalImageUrls.add(imageUrl);
            }
          } catch (e) {
            // Log el error pero continúa con las otras imágenes
            developer.log('⚠️ Error al subir imagen adicional $i: $e');
          }
        }
      }

      // Crear el modelo del servicio
      final serviceModel = ServiceModel.createNew(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        price: _priceType == 'negotiable' ? 0.0 : double.parse(_priceController.text.trim()),
        priceType: _priceType,
        providerId: authState.user.id,
        providerName: authState.user.name,
        providerPhotoUrl: authState.user.photoUrl,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty
            ? '+57${_whatsappController.text.trim()}'
            : authState.user.phoneNumber,
        instagram: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
        xProfile: _xController.text.trim().isNotEmpty ? _xController.text.trim() : null,
        tiktok: _tiktokController.text.trim().isNotEmpty ? _tiktokController.text.trim() : null,
        callPhones: [
          if (_phone1Controller.text.trim().isNotEmpty) '+57${_phone1Controller.text.trim()}',
          if (_phone2Controller.text.trim().isNotEmpty) '+57${_phone2Controller.text.trim()}',
        ],
        mainImage: mainImageUrl,
        images: additionalImageUrls, // URLs de las imágenes adicionales subidas
        tags: const [], // Se implementará en pasos futuros
        features: [
          if (_experienceController.text.trim().isNotEmpty) 
            'Experiencia: ${_experienceController.text.trim()}',
          if (_selectedServiceType.isNotEmpty)
            'Modalidad: ${_getServiceTypeText()}',
          ..._selectedSkills,
          ..._customSkills,
        ],
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        location: (_latitude != null && _longitude != null) 
            ? {'latitude': _latitude!, 'longitude': _longitude!} 
            : null,
        availableDays: _availableDays,
        timeRange: null,
      );

      // Crear el servicio usando el use case
      final serviceId = await widget.createServiceUseCase.call(
        CreateServiceParams(service: serviceModel),
      );

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Servicio creado exitosamente!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              // Navegar al servicio creado
              context.go('/services/$serviceId');
            },
          ),
        ),
      );

      // Actualizar la lista de servicios
      ServiceRefreshNotifier().notifyServicesChanged();
      
      // Feedback háptico de éxito
      HapticsService.onSuccess();
      
      // Navegar a mis servicios
      context.go('/services/my-services');
      
    } catch (e) {
      if (!mounted) return;
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear servicio: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Feedback háptico de error
      HapticsService.onWarning();
      
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingService = false;
        });
      }
    }
  }
}
