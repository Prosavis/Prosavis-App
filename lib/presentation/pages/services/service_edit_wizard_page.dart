import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/injection/injection_container.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/service_refresh_notifier.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/usecases/services/get_service_by_id_usecase.dart';
import '../../../domain/usecases/services/update_service_usecase.dart';
import '../../../data/services/image_storage_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/image_picker_bottom_sheet.dart';
import '../../../core/services/haptics_service.dart';

// Definición de un paso del wizard para edición
class ServiceEditStep {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isRequired;
  final Widget Function(ServiceEditWizardPageState state) builder;
  final bool Function(ServiceEditWizardPageState state) validator;

  const ServiceEditStep({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isRequired,
    required this.builder,
    required this.validator,
  });
}

class ServiceEditWizardPage extends StatefulWidget {
  final String serviceId;
  
  const ServiceEditWizardPage({super.key, required this.serviceId});

  @override
  State<ServiceEditWizardPage> createState() => ServiceEditWizardPageState();
}

class ServiceEditWizardPageState extends State<ServiceEditWizardPage>
    with TickerProviderStateMixin {
  
  // Use cases
  late final GetServiceByIdUseCase _getServiceByIdUseCase;
  late final UpdateServiceUseCase _updateServiceUseCase;
  
  // Controladores de animación
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Variables de estado
  ServiceEntity? _service;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  int _currentStepIndex = 0;
  
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
  
  // Variables de estado del formulario
  String? _selectedCategory;
  String _priceType = 'fixed';
  String? _mainImageUrl;
  File? _mainImageFile;
  bool _imageDeleted = false; // Bandera para rastrear si se eliminó la imagen principal
  List<String> _selectedImages = [];
  final List<File> _newImages = [];
  final List<String> _imagesToDelete = []; // Imágenes a eliminar del storage

  List<String> _selectedSkills = [];
  final List<String> _customSkills = [];
  List<String> _availableDays = [];
  String? _selectedExperienceLevel;
  String _selectedServiceType = 'home_service';
  double? _lat;
  double? _lng;
  final _customSkillController = TextEditingController();

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
  late List<ServiceEditStep> _steps;

  @override
  void initState() {
    super.initState();
    _getServiceByIdUseCase = sl<GetServiceByIdUseCase>();
    _updateServiceUseCase = sl<UpdateServiceUseCase>();
    _initializeAnimations();
    _initializeSteps();
    _loadService();
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
      ServiceEditStep(
        id: 'category',
        title: 'Categoría',
        subtitle: 'Modifica la categoría de tu servicio',
        icon: Symbols.category,
        isRequired: true,
        builder: _buildCategoryStep,
        validator: (state) => state._selectedCategory != null && state._selectedCategory!.isNotEmpty,
      ),
      
      // Paso 2: Información básica (Obligatorio)
      ServiceEditStep(
        id: 'basic_info',
        title: 'Información básica',
        subtitle: 'Actualiza el título y descripción',
        icon: Symbols.edit_note,
        isRequired: true,
        builder: _buildBasicInfoStep,
        validator: (state) => 
          state._titleController.text.trim().length >= 5 && 
          state._descriptionController.text.trim().length >= 20,
      ),
      
      // Paso 3: Precio (Obligatorio)
      ServiceEditStep(
        id: 'pricing',
        title: 'Precio',
        subtitle: 'Ajusta el precio de tu servicio',
        icon: Symbols.payments,
        isRequired: true,
        builder: _buildPricingStep,
        validator: (state) => 
          state._priceType == 'negotiable' || 
          (state._priceController.text.isNotEmpty && double.tryParse(state._priceController.text) != null),
      ),
      
      // Paso 4: Imagen principal (Opcional)
      ServiceEditStep(
        id: 'main_image',
        title: 'Imagen principal',
        subtitle: 'Cambia la imagen de tu servicio (opcional)',
        icon: Symbols.image,
        isRequired: false,
        builder: _buildMainImageStep,
        validator: (state) => true, // Siempre válido por ser opcional
      ),
      
      // Paso 5: Experiencia (Opcional)
      ServiceEditStep(
        id: 'experience',
        title: 'Experiencia',
        subtitle: 'Actualiza tu experiencia',
        icon: Symbols.star,
        isRequired: false,
        builder: _buildExperienceStep,
        validator: (state) => true,
      ),
      
      // Paso 6: Contacto (Opcional)
      ServiceEditStep(
        id: 'contact',
        title: 'Contacto',
        subtitle: 'Modifica tus datos de contacto',
        icon: Symbols.contact_phone,
        isRequired: false,
        builder: _buildContactStep,
        validator: (state) => true,
      ),
      
      // Paso 7: Disponibilidad (Opcional)
      ServiceEditStep(
        id: 'availability',
        title: 'Disponibilidad',
        subtitle: 'Cambia tus días disponibles',
        icon: Symbols.schedule,
        isRequired: false,
        builder: _buildAvailabilityStep,
        validator: (state) => true,
      ),
      
      // Paso 8: Habilidades (Opcional)
      ServiceEditStep(
        id: 'skills',
        title: 'Habilidades especiales',
        subtitle: 'Actualiza tus características',
        icon: Symbols.verified,
        isRequired: false,
        builder: _buildSkillsStep,
        validator: (state) => true,
      ),
      
      // Paso 9: Imágenes adicionales (Opcional)
      ServiceEditStep(
        id: 'additional_images',
        title: 'Imágenes adicionales',
        subtitle: 'Actualiza tu galería de trabajos',
        icon: Symbols.photo_library,
        isRequired: false,
        builder: _buildAdditionalImagesStep,
        validator: (state) => true,
      ),
      
      // Paso 10: Ubicación (Opcional)
      ServiceEditStep(
        id: 'location',
        title: 'Ubicación',
        subtitle: 'Modifica dónde ofreces tu servicio',
        icon: Symbols.location_on,
        isRequired: false,
        builder: _buildLocationStep,
        validator: (state) => true,
      ),
      
      // Paso 11: Resumen (Obligatorio)
      ServiceEditStep(
        id: 'summary',
        title: 'Resumen',
        subtitle: 'Revisa y guarda los cambios',
        icon: Symbols.check_circle,
        isRequired: true,
        builder: _buildSummaryStep,
        validator: (state) => true,
      ),
    ];
  }

  Future<void> _loadService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = await _getServiceByIdUseCase(widget.serviceId);
      if (service == null) {
        setState(() {
          _errorMessage = 'Servicio no encontrado';
          _isLoading = false;
        });
        return;
      }

      // Verificar que el usuario actual es el propietario del servicio
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is! AuthAuthenticated || authState.user.id != service.providerId) {
          setState(() {
            _errorMessage = 'No tienes permisos para editar este servicio';
            _isLoading = false;
          });
          return;
        }
      }

      // Cargar datos del servicio en los controladores
      _service = service;
      _titleController.text = service.title;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _selectedCategory = service.category;
      _priceType = service.priceType;
      _mainImageUrl = service.mainImage;
      _imageDeleted = false; // Resetear bandera al cargar servicio
      _selectedImages = List.from(service.images);
      // Tags se mantienen del servicio original sin edición
      _selectedSkills = List.from(service.features);
      _availableDays = List.from(service.availableDays);
      _addressController.text = service.address ?? '';
      _whatsappController.text = service.whatsappNumber ?? '';
      _instagramController.text = service.instagram ?? '';
      _xController.text = service.xProfile ?? '';
      _tiktokController.text = service.tiktok ?? '';
      
      // Cargar teléfonos de contacto (limpiar formato +57)
      if (service.callPhones.isNotEmpty) {
        String phone1 = service.callPhones.first;
        if (phone1.startsWith('+57')) {
          phone1 = phone1.substring(3);
        }
        _phone1Controller.text = phone1;
        
        if (service.callPhones.length > 1) {
          String phone2 = service.callPhones[1];
          if (phone2.startsWith('+57')) {
            phone2 = phone2.substring(3);
          }
          _phone2Controller.text = phone2;
        }
      }

      // Cargar WhatsApp (limpiar formato +57)
      if (service.whatsappNumber != null && service.whatsappNumber!.isNotEmpty) {
        String whatsapp = service.whatsappNumber!;
        if (whatsapp.startsWith('+57')) {
          whatsapp = whatsapp.substring(3);
        }
        _whatsappController.text = whatsapp;
      }

      // Cargar experiencia y habilidades
      final experienceFeature = service.features.cast<String?>().firstWhere(
        (feature) => feature != null && (feature.startsWith('exp:') || feature.toLowerCase().contains('experiencia')),
        orElse: () => null,
      );
      if (experienceFeature != null) {
        _experienceController.text = experienceFeature.replaceFirst('exp:', '').replaceFirst('Experiencia:', '').trim();
      }

      // Cargar habilidades (filtrar experiencia)
      _selectedSkills = service.features
          .where((feature) => !feature.startsWith('exp:') && !feature.toLowerCase().contains('experiencia') && !feature.startsWith('Modalidad:'))
          .where((feature) => _commonSkills.contains(feature))
          .toList();

      // Cargar habilidades personalizadas
      _customSkills.addAll(service.features
          .where((feature) => !feature.startsWith('exp:') && !feature.toLowerCase().contains('experiencia') && !feature.startsWith('Modalidad:'))
          .where((feature) => !_commonSkills.contains(feature))
          .toList());

      // Cargar modalidad de servicio
      final modalityFeature = service.features.cast<String?>().firstWhere(
        (feature) => feature != null && feature.startsWith('Modalidad:'),
        orElse: () => null,
      );
      if (modalityFeature != null) {
        final modalityText = modalityFeature.replaceFirst('Modalidad:', '').trim();
        if (modalityText.contains('domicilio')) {
          _selectedServiceType = 'home_service';
        } else if (modalityText.contains('local')) {
          _selectedServiceType = 'in_location';
        } else if (modalityText.contains('Ambas')) {
          _selectedServiceType = 'both';
        }
      }

      // Cargar ubicación
      if (service.location != null) {
        _lat = service.location!['latitude']?.toDouble();
        _lng = service.location!['longitude']?.toDouble();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el servicio: $e';
        _isLoading = false;
      });
    }
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

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
            onPressed: _currentStepIndex > 0 ? _goToPreviousStep : () => context.pop(),
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
                (isLastStep ? _updateService : _goToNextStep) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppTheme.getTextSecondary(context).withValues(alpha: 0.3),
              ),
              child: _isUpdating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isLastStep ? 'Guardar cambios' : 'Continuar',
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
    
    final isMovingForward = stepIndex > _currentStepIndex;
    final direction = isMovingForward ? 1.0 : -1.0;
    
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
    
    // Recrear animación con dirección dinámica
    _slideAnimation = Tween<Offset>(
      begin: Offset(direction, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.reset();
    _fadeController.reset();
    
    _slideController.forward();
    _fadeController.forward();

    // Feedback háptico
    HapticsService.onNavigation();
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
              _imageDeleted = false; // Resetear la bandera si se selecciona una nueva imagen
              // No limpiar _mainImageUrl aquí para mantener la imagen actual como respaldo
            });
          }
        },
        hasCurrentImage: _mainImageFile != null || _mainImageUrl != null,
        onRemoveImage: () {
          if (mounted) {
            setState(() {
              _mainImageFile = null;
              _mainImageUrl = null;
              _imageDeleted = true; // Marcar que se eliminó la imagen
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

  // Constructores de pasos (implementar los mismos que en creation pero adaptados para edición)
  Widget _buildCategoryStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  '¿Quieres cambiar la categoría?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Categoría actual: $_selectedCategory',
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
                    labelText: 'Nueva categoría',
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

  Widget _buildBasicInfoStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualiza la información',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica el título y descripción de tu servicio',
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

  Widget _buildPricingStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  '¿Quieres cambiar el precio?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Precio actual: ${_priceType == 'negotiable' ? 'Negociable' : '\$${_priceController.text}'}',
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
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

  Widget _buildMainImageStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Imagen del servicio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes cambiar la imagen principal si lo deseas',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _selectMainImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: _mainImageFile != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _mainImageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _mainImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _mainImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Symbols.error,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Symbols.add_a_photo,
                                    size: 48,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Toca para cambiar imagen',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectMainImage,
                  icon: const Icon(Symbols.edit),
                  label: Text(_mainImageFile != null || _mainImageUrl != null ? 'Cambiar imagen' : 'Añadir imagen'),
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

  Widget _buildExperienceStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualiza tu experiencia',
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

  Widget _buildContactStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualizar información de contacto',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica las formas adicionales para que los clientes puedan contactarte.',
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

  Widget _buildAvailabilityStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualizar disponibilidad',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica los días en los que ofreces tu servicio.',
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

  Widget _buildSkillsStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualizar habilidades especiales',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica las características que te destacan como profesional.',
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
                            // Remover si existe en cualquier posición y agregar al inicio
                            _selectedSkills.remove(skill);
                            _selectedSkills.insert(0, skill);
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
                
                // Grid de habilidades personalizadas si existen
                if (_customSkills.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Habilidades personalizadas',
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
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _customSkills.length,
                    itemBuilder: (context, index) {
                      final skill = _customSkills[index];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Al deseleccionar una habilidad personalizada, se elimina automáticamente
                            _customSkills.remove(skill);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Symbols.check_circle,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  skill,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
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
                ],
                
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
                              'Habilidades seleccionadas (${_getAllSelectedSkills().length})',
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
                            // Todas las habilidades seleccionadas en orden (más recientes primero)
                            ..._getAllSelectedSkills().map((skill) {
                              final isCustomSkill = _customSkills.contains(skill);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: isCustomSkill
                                  ? Row(
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
                                    )
                                  : Text(
                                      skill,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                              );
                            }),
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

  Widget _buildLocationStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualizar ubicación del servicio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica dónde ofreces tu servicio para ayudar a los clientes a encontrarte.',
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
                if (_lat != null && _lng != null) ...[
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
                            'Ubicación seleccionada: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
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

  Widget _buildSummaryStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  '¡Listo para guardar!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa los cambios antes de guardar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // 1. Categoría
                _buildSummaryItem(
                  icon: Symbols.category,
                  title: 'Categoría',
                  value: _selectedCategory ?? 'No seleccionada',
                ),
                const SizedBox(height: 12),
                
                // 2. Información básica - Título
                _buildSummaryItem(
                  icon: Symbols.title,
                  title: 'Título',
                  value: _titleController.text.trim().isEmpty 
                      ? 'Sin título' 
                      : _titleController.text.trim(),
                ),
                const SizedBox(height: 12),
                
                // 2. Información básica - Descripción
                _buildSummaryItem(
                  icon: Symbols.description,
                  title: 'Descripción',
                  value: _descriptionController.text.trim().isEmpty 
                      ? 'Sin descripción' 
                      : _descriptionController.text.trim(),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                // 3. Precio
                _buildSummaryItem(
                  icon: Symbols.payments,
                  title: 'Precio',
                  value: _priceType == 'negotiable' 
                      ? 'Negociable' 
                      : _priceController.text.isEmpty 
                          ? 'No definido'
                          : '\$${_priceController.text}',
                ),
                const SizedBox(height: 12),
                
                // 4. Imagen principal
                _buildSummaryItem(
                  icon: Symbols.image,
                  title: 'Imagen principal',
                  value: _mainImageFile != null 
                      ? 'Nueva imagen seleccionada'
                      : _mainImageUrl != null 
                          ? 'Imagen actual mantenida' 
                          : 'Sin imagen',
                ),
                const SizedBox(height: 12),
                
                // 5. Experiencia
                _buildSummaryItem(
                  icon: Symbols.star,
                  title: 'Experiencia',
                  value: _selectedExperienceLevel != null 
                      ? _selectedExperienceLevel! 
                      : 'No especificada',
                ),
                const SizedBox(height: 12),
                
                // 6. Contacto
                _buildSummaryItem(
                  icon: Symbols.contact_phone,
                  title: 'Contacto',
                  value: _getContactSummary(),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                // 7. Disponibilidad
                _buildSummaryItem(
                  icon: Symbols.schedule,
                  title: 'Disponibilidad',
                  value: _availableDays.isNotEmpty 
                      ? _availableDays.join(', ')
                      : 'Días no especificados',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                // 8. Habilidades especiales
                _buildSummaryItem(
                  icon: Symbols.verified,
                  title: 'Habilidades especiales',
                  value: _getSkillsSummary(),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                // 9. Imágenes adicionales
                _buildSummaryItem(
                  icon: Symbols.photo_library,
                  title: 'Imágenes adicionales',
                  value: _getAdditionalImagesSummary(),
                ),
                const SizedBox(height: 12),
                
                // 10. Ubicación
                _buildSummaryItem(
                  icon: Symbols.location_on,
                  title: 'Ubicación',
                  value: _getLocationSummary(),
                  maxLines: 2,
                ),
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
                          'Los cambios se guardarán inmediatamente',
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

  // Métodos auxiliares para generar resúmenes
  String _getContactSummary() {
    final List<String> contactInfo = [];
    
    if (_whatsappController.text.trim().isNotEmpty) {
      contactInfo.add('WhatsApp: ${_whatsappController.text.trim()}');
    }
    if (_phone1Controller.text.trim().isNotEmpty) {
      contactInfo.add('Tel: ${_phone1Controller.text.trim()}');
    }
    if (_phone2Controller.text.trim().isNotEmpty) {
      contactInfo.add('Tel 2: ${_phone2Controller.text.trim()}');
    }
    if (_instagramController.text.trim().isNotEmpty) {
      contactInfo.add('Instagram: @${_instagramController.text.trim()}');
    }
    if (_xController.text.trim().isNotEmpty) {
      contactInfo.add('X: @${_xController.text.trim()}');
    }
    if (_tiktokController.text.trim().isNotEmpty) {
      contactInfo.add('TikTok: @${_tiktokController.text.trim()}');
    }
    
    return contactInfo.isNotEmpty 
        ? contactInfo.join(' • ')
        : 'No se agregó información de contacto';
  }

  String _getSkillsSummary() {
    final List<String> allSkills = [];
    allSkills.addAll(_selectedSkills);
    allSkills.addAll(_customSkills);
    
    return allSkills.isNotEmpty 
        ? allSkills.join(', ')
        : 'No se seleccionaron habilidades especiales';
  }

  String _getAdditionalImagesSummary() {
    final int totalImages = _selectedImages.length + _newImages.length;
    
    if (totalImages == 0) {
      return 'No se agregaron imágenes adicionales';
    } else if (_newImages.isNotEmpty && _selectedImages.isNotEmpty) {
      return '${_selectedImages.length} imágenes mantenidas, ${_newImages.length} nuevas';
    } else if (_newImages.isNotEmpty) {
      return '${_newImages.length} nuevas imágenes seleccionadas';
    } else {
      return '${_selectedImages.length} imágenes actuales mantenidas';
    }
  }

  String _getLocationSummary() {
    final parts = <String>[];
    parts.add(_getServiceTypeText()); // Usar método consistente
    
    if (_addressController.text.trim().isNotEmpty) {
      parts.add('Dirección: ${_addressController.text.trim()}');
    }
    
    if (_lat != null && _lng != null) {
      parts.add('Ubicación GPS definida');
    }
    
    return parts.join(' • ');
  }



  Widget _buildAdditionalImagesStep(ServiceEditWizardPageState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'Actualizar galería de imágenes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica las imágenes adicionales para mostrar tu trabajo y atraer más clientes.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón para añadir imágenes
                Center(
                  child: GestureDetector(
                    onTap: (_selectedImages.length + _newImages.length) >= 6 ? null : _selectAdditionalImages,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (_selectedImages.length + _newImages.length) >= 6 
                              ? AppTheme.getTextSecondary(context) 
                              : AppTheme.primaryColor,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: (_selectedImages.length + _newImages.length) >= 6 
                            ? AppTheme.getTextSecondary(context).withValues(alpha: 0.05)
                            : AppTheme.primaryColor.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.add_photo_alternate,
                            size: 40,
                            color: (_selectedImages.length + _newImages.length) >= 6 
                                ? AppTheme.getTextSecondary(context) 
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_selectedImages.length + _newImages.length) >= 6 ? 'Límite alcanzado' : 'Añadir imágenes',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: (_selectedImages.length + _newImages.length) >= 6 
                                  ? AppTheme.getTextSecondary(context) 
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_selectedImages.length + _newImages.length) >= 6 
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
                            '${_selectedImages.length + _newImages.length}/6 imágenes total',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: (_selectedImages.length + _newImages.length) >= 6 
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
                    'Nuevas imágenes (${_newImages.length})',
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

                // Imágenes existentes si las hay
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Imágenes actuales (${_selectedImages.length})',
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
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
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
                              child: Image.network(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Symbols.broken_image,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Agregar a la lista de imágenes a eliminar
                                  _imagesToDelete.add(_selectedImages[index]);
                                  _selectedImages.removeAt(index);
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
      // Verificar límite TOTAL antes de abrir el selector
      const maxImages = 6;
      final currentTotal = _selectedImages.length + _newImages.length;
      if (currentTotal >= maxImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Máximo $maxImages imágenes permitidas. Tienes $currentTotal.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      HapticsService.onNavigation();
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ImagePickerBottomSheet(
          onImageSelected: (File image) {
            setState(() {
              // Solo agregar si no se ha alcanzado el límite total
              const maxImages = 6;
              final currentTotal = _selectedImages.length + _newImages.length;
              if (currentTotal < maxImages) {
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

  // Métodos helper para contacto, días y habilidades
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Actualiza tu número de WhatsApp. Solo funciona en Colombia (+57)',
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

  void _addCustomSkill() {
    final customSkill = _customSkillController.text.trim();
    if (customSkill.isNotEmpty && 
        !_customSkills.contains(customSkill) && 
        !_selectedSkills.contains(customSkill)) {
      setState(() {
        // Agregar al inicio de la lista y marcar como seleccionada
        _customSkills.insert(0, customSkill);
        _customSkillController.clear();
      });
    }
  }

  void _removeCustomSkill(String skill) {
    setState(() {
      _customSkills.remove(skill);
    });
  }

  // Método para obtener todas las habilidades seleccionadas en orden
  List<String> _getAllSelectedSkills() {
    final List<String> allSkills = [];
    
    // Primero agregar habilidades personalizadas (más recientes primero)
    allSkills.addAll(_customSkills);
    
    // Luego agregar habilidades predeterminadas seleccionadas (más recientes primero)
    allSkills.addAll(_selectedSkills);
    
    return allSkills;
  }

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

  // Método para seleccionar ubicación en mapa
  Future<void> _selectLocationOnMap() async {
    try {
      final result = await context.push('/addresses/map');
      if (!mounted || result == null) return;
      
      final map = result as Map<String, dynamic>;
      setState(() {
        _lat = (map['latitude'] as num?)?.toDouble();
        _lng = (map['longitude'] as num?)?.toDouble();
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

  String _getServiceTypeText() {
    switch (_selectedServiceType) {
      case 'home_service':
        return 'Servicio a domicilio';
      case 'in_location':
        return 'Servicio en mi local';
      case 'both':
        return 'Ambas modalidades';
      default:
        return 'No especificado';
    }
  }

  // Métodos auxiliares para validación y normalización
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');
  
  String? _normalizeColombianPhone(String s) {
    final digits = _digitsOnly(s);
    return digits.length == 10 ? '+57$digits' : null;
  }
  
  double _safeParsePrice(String text) {
    if (_priceType == 'negotiable') return 0.0;
    
    final cleanText = text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(cleanText);
    return parsed ?? 0.0;
  }

  // Método para actualizar el servicio
  Future<void> _updateService() async {
    if (!mounted || _service == null) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    // Guards de validación
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      setState(() => _isUpdating = false);
      return;
    }
    
    if (_priceType != 'negotiable' &&
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido')),
      );
      setState(() => _isUpdating = false);
      return;
    }
    
    if (_titleController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título debe tener al menos 5 caracteres')),
      );
      setState(() => _isUpdating = false);
      return;
    }
    
    if (_descriptionController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descripción debe tener al menos 20 caracteres')),
      );
      setState(() => _isUpdating = false);
      return;
    }
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      final imageStorageService = sl<ImageStorageService>();
      String? mainImageUrl = _mainImageUrl;
      
      // Manejar imagen principal - SUBIR PRIMERO, BORRAR DESPUÉS
      if (_imageDeleted) {
        // Solo eliminar la anterior si realmente queremos dejarla en null
        if (_service!.mainImage?.isNotEmpty == true) {
          try {
            await imageStorageService.deleteServiceImage(_service!.mainImage!);
          } catch (e) {
            developer.log('⚠️ Error al eliminar imagen anterior: $e');
          }
        }
        mainImageUrl = null;
      } else if (_mainImageFile != null) {
        // 1) Subir nueva imagen primero
        final uploadedUrl = await imageStorageService.uploadServiceImage(
          widget.serviceId,
          _mainImageFile!,
        );
        if (uploadedUrl == null) {
          throw Exception('Error al subir la imagen principal');
        }
        
        // 2) Borrar anterior solo si la subida fue exitosa (best-effort)
        if (_service!.mainImage?.isNotEmpty == true) {
          try {
            await imageStorageService.deleteServiceImage(_service!.mainImage!);
          } catch (e) {
            developer.log('⚠️ Error al eliminar imagen anterior: $e');
          }
        }
        
        mainImageUrl = uploadedUrl;
      }
      // Si no se eliminó ni hay nueva imagen, mantener la URL actual

      // Validar límite total de imágenes antes de subir
      const maxImages = 6;
      final currentTotal = _selectedImages.length + _newImages.length;
      if (currentTotal > maxImages) {
        throw Exception('Máximo $maxImages imágenes permitidas. Tienes $currentTotal.');
      }
      
      // Subir nuevas imágenes adicionales si las hay
      final List<String> allImages = List.from(_selectedImages);
      if (_newImages.isNotEmpty) {
        try {
          final uploadedUrls = await imageStorageService.uploadMultipleServiceImages(
            widget.serviceId,
            _newImages,
          );
          allImages.addAll(uploadedUrls);
        } catch (e) {
          throw Exception('Error al subir las imágenes adicionales: $e');
        }
      }

      // Combinar habilidades con experiencia - evitar duplicados usando Set
      final finalFeatures = <String>{
        ..._selectedSkills,
        ..._customSkills,
        if (_selectedExperienceLevel != null) 'Nivel: $_selectedExperienceLevel',
        if (_experienceController.text.trim().isNotEmpty)
          (_experienceController.text.trim().startsWith('exp:')
              ? _experienceController.text.trim()
              : 'Experiencia: ${_experienceController.text.trim()}'),
        'Modalidad: ${_getServiceTypeText()}',
      }.toList();

      // Normalizar teléfonos usando los métodos auxiliares
      final whatsapp = _normalizeColombianPhone(_whatsappController.text);
      final phone1 = _normalizeColombianPhone(_phone1Controller.text);
      final phone2 = _normalizeColombianPhone(_phone2Controller.text);
      
      // Actualizar el servicio
      final updatedService = _service!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _safeParsePrice(_priceController.text.trim()),
        category: _selectedCategory!,
        priceType: _priceType,
        mainImage: mainImageUrl,
        images: allImages,
        tags: _service!.tags, // Mantener tags originales (no se editan)
        features: finalFeatures,
        availableDays: _availableDays,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        whatsappNumber: whatsapp,
        callPhones: [
          if (phone1 != null) phone1,
          if (phone2 != null) phone2,
        ],
        instagram: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
        xProfile: _xController.text.trim().isNotEmpty ? _xController.text.trim() : null,
        tiktok: _tiktokController.text.trim().isNotEmpty ? _tiktokController.text.trim() : null,
        location: (_lat != null && _lng != null)
            ? {
                'latitude': _lat!,
                'longitude': _lng!,
              }
            : _service!.location,
        updatedAt: DateTime.now(),
      );

      await _updateServiceUseCase(updatedService);

      if (!mounted) return;

      // Eliminar imágenes marcadas para borrado DESPUÉS de guardar (best-effort)
      for (final imageUrl in _imagesToDelete) {
        try {
          await imageStorageService.deleteServiceImage(imageUrl);
        } catch (e) {
          developer.log('⚠️ Error al eliminar imagen: $e');
        }
      }

      // Actualizar la lista de servicios
      ServiceRefreshNotifier().notifyServicesChanged();
      
      // Feedback háptico de éxito
      HapticsService.onSuccess();
      
      // Navegar directamente al detalle del servicio (evita problema de SnackBar + pop)
      if (mounted) {
        context.pushReplacement('/services/${widget.serviceId}');
      }
      
    } catch (e) {
      if (!mounted) return;
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar servicio: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Feedback háptico de error
      HapticsService.onWarning();
      
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}