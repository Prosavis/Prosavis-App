import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/injection/injection_container.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/service_refresh_notifier.dart';
import '../../../domain/usecases/services/create_service_usecase.dart';
import '../../../domain/usecases/services/update_service_usecase.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/image_storage_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/image_picker_bottom_sheet.dart';

class ServiceCreationPage extends StatefulWidget {
  final CreateServiceUseCase createServiceUseCase;
  
  const ServiceCreationPage({super.key, required this.createServiceUseCase});

  @override
  State<ServiceCreationPage> createState() => _ServiceCreationPageState();
}

class _ServiceCreationPageState extends State<ServiceCreationPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedCategory;
  String _priceType = 'fixed';
  String? _mainImageUrl; // Imagen principal
  File? _mainImageFile; // Archivo de imagen principal
  final List<String> _selectedImages = [];
  final List<File> _newImages = []; // Nuevas imágenes seleccionadas
  final List<String> _selectedTags = [];
  final List<String> _selectedSkills = [];
  final List<String> _availableDays = [];

  bool _isCreatingService = false;

  final List<String> _priceTypes = [
    'fixed',
    'daily',
    'negotiable',
  ];

  final List<String> _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  /// Convierte días en español a inglés para guardar en la base de datos
  List<String> _convertDaysToEnglish(List<String> spanishDays) {
    const Map<String, String> dayTranslation = {
      'Lunes': 'monday',
      'Martes': 'tuesday',
      'Miércoles': 'wednesday',
      'Jueves': 'thursday',
      'Viernes': 'friday',
      'Sábado': 'saturday',
      'Domingo': 'sunday',
    };

    return spanishDays
        .map((day) => dayTranslation[day] ?? day.toLowerCase())
        .toList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Ofrecer Servicio',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildCreationForm(),
      ),
    );
  }

  Widget _buildCreationForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildCategorySection(),
          const SizedBox(height: 16),
          _buildBasicInfoSection(),
          const SizedBox(height: 16),
          _buildPricingSection(),
          const SizedBox(height: 16),
          _buildExperienceSection(),
          const SizedBox(height: 16),
          _buildAvailabilitySection(),
          const SizedBox(height: 16),
          _buildSkillsSection(),
          const SizedBox(height: 16),
          _buildMainImageSection(),
          const SizedBox(height: 16),
          _buildImagesSection(),
          const SizedBox(height: 16),
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.add_business,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear nuevo servicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'Completa la información de tu servicio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      title: 'Información básica',
      icon: Symbols.info,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título del servicio',
              hintText: 'Ej: Plomería residencial',
              prefixIcon: const Icon(Symbols.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio';
              }
              if (value.trim().length < 5) {
                return 'El título debe tener al menos 5 caracteres';
              }
              return null;
            },
            maxLength: 60,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Describe tu servicio en detalle...',
              prefixIcon: const Icon(Symbols.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es obligatoria';
              }
              if (value.trim().length < 20) {
                return 'La descripción debe tener al menos 20 caracteres';
              }
              return null;
            },
            maxLines: 4,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return _buildSectionCard(
      title: 'Precio',
      icon: Symbols.payments,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _priceType,
            decoration: InputDecoration(
              labelText: 'Tipo de precio',
              prefixIcon: const Icon(Symbols.schedule),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _priceTypes.map((type) {
              final displayName = {
                'fixed': 'Por servicio',
                'daily': 'Por día',
                'negotiable': 'Negociable',
              }[type] ?? type;
              
              return DropdownMenuItem(
                value: type,
                child: Text(displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _priceType = value!);
            },
          ),
          const SizedBox(height: 16),
          if (_priceType != 'negotiable')
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Precio (\$)',
                hintText: '0.00',
                prefixIcon: const Icon(Symbols.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (_priceType == 'negotiable') return null;
                
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es obligatorio';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Ingresa un precio válido';
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return _buildSectionCard(
      title: 'Categoría',
      icon: Symbols.category,
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Categoría del servicio',
          prefixIcon: const Icon(Symbols.work),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: AppConstants.serviceCategories.map((category) {
          return DropdownMenuItem<String>(
            value: category['name'] as String,
            child: Row(
              children: [
                Icon(category['icon'], size: 20),
                const SizedBox(width: 8),
                Text(category['name']),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedCategory = value);
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Selecciona una categoría';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildExperienceSection() {
    return _buildSectionCard(
      title: 'Experiencia',
      icon: Symbols.work_history,
      child: TextFormField(
        controller: _experienceController,
        decoration: InputDecoration(
          labelText: 'Años de experiencia (opcional)',
          hintText: 'Ej: 5 años en plomería residencial',
          prefixIcon: const Icon(Symbols.timeline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        maxLines: 2,
        maxLength: 200,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return _buildSectionCard(
      title: 'Disponibilidad',
      icon: Symbols.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días disponibles',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final isSelected = _availableDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _availableDays.remove(day);
                    } else {
                      _availableDays.add(day);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return _buildSectionCard(
      title: 'Habilidades y características',
      icon: Symbols.star,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona las habilidades que aplican a tu servicio',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonSkills.map((skill) {
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
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    skill,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showAddSkillDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Symbols.add,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agregar habilidad personalizada',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageSection() {
    return _buildSectionCard(
      title: 'Imagen principal',
      icon: Symbols.image,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona la imagen que se mostrará como banner principal de tu servicio',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.info,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta imagen se mostrará como portada principal del servicio',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_mainImageFile == null && _mainImageUrl == null)
            GestureDetector(
              onTap: () => _selectMainImage(),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Symbols.add_photo_alternate,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seleccionar imagen principal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_mainImageFile != null || _mainImageUrl != null)
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _mainImageFile != null
                        ? Image.file(
                            _mainImageFile!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Symbols.image,
                                    size: 32,
                                    color: AppTheme.textTertiary,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Imagen principal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeMainImage(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Symbols.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PRINCIPAL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return _buildSectionCard(
      title: 'Galería de trabajos',
      icon: Symbols.photo_library,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agrega fotos de trabajos anteriores para mostrar tu calidad',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.info,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Máximo 4 imágenes • 10MB cada una • Solo JPEG, PNG, WebP',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isEmpty && _newImages.isEmpty)
            GestureDetector(
              onTap: () => _addImage(),
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Symbols.add_a_photo,
                      size: 32,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agregar fotos de trabajos',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedImages.isNotEmpty || _newImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length + _newImages.length + 
                         ((_selectedImages.length + _newImages.length) < 4 ? 1 : 0),
              itemBuilder: (context, index) {
                final totalImages = _selectedImages.length + _newImages.length;
                
                // Botón agregar al final
                if (index == totalImages) {
                  return GestureDetector(
                    onTap: () => _addImage(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.add_a_photo,
                            color: AppTheme.textTertiary,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Agregar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Mostrar imágenes existentes primero
                if (index < _selectedImages.length) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Symbols.image,
                                color: AppTheme.textTertiary,
                                size: 30,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Existente',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(_selectedImages[index]),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Symbols.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Mostrar nuevas imágenes
                final newImageIndex = index - _selectedImages.length;
                final imageFile = _newImages[newImageIndex];
                
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imageFile,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeNewImage(imageFile),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Symbols.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Nueva',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard(
      title: 'Ubicación',
      icon: Symbols.location_on,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección (opcional)',
                    hintText: 'Ej: Calle 123 #45-67, Bogotá',
                    prefixIcon: const Icon(Symbols.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLength: 200,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(
                        Symbols.my_location,
                        size: 18,
                      ),
                      label: Text(
                        'GPS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isCreatingService ? null : _submitService,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreatingService
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Creando servicio...'),
                    ],
                  )
                : Text(
                    'Crear servicio',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isCreatingService ? null : () => context.go('/home'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }



  void _showAddSkillDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Agregar habilidad',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nueva habilidad',
            hintText: 'Ej: Reparación de electrodomésticos',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              final skill = controller.text.trim();
              if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
                setState(() {
                  _selectedSkills.add(skill);
                });
              }
              Navigator.of(context).pop();
            },
            child: Text(
              'Agregar',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addImage() {
    if (_selectedImages.length + _newImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Máximo 4 imágenes permitidas',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ImagePickerBottomSheet.show(
      context,
      onImageSelected: (File imageFile) {
        setState(() {
          _newImages.add(imageFile);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imagen agregada exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _removeImage(String imageUrl) {
    setState(() {
      _selectedImages.remove(imageUrl);
    });
  }

  void _removeNewImage(File imageFile) {
    setState(() {
      _newImages.remove(imageFile);
    });
  }

  void _selectMainImage() {
    ImagePickerBottomSheet.show(
      context,
      onImageSelected: (File imageFile) {
        setState(() {
          _mainImageFile = imageFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imagen principal seleccionada',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _removeMainImage() {
    setState(() {
      _mainImageFile = null;
      _mainImageUrl = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '🔍 Obteniendo ubicación GPS...',
              style: GoogleFonts.inter(),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 30), // Dar tiempo suficiente
      ),
    );

    try {
      final address = await LocationUtils.getCurrentAddress();
      
      // Ocultar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      if (address != null && mounted) {
        setState(() {
          _addressController.text = address;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📍 Ubicación obtenida: $address',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ No se pudo obtener la ubicación. Verifica que el GPS esté habilitado.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Configuración',
              textColor: Colors.white,
              onPressed: () async {
                await LocationUtils.openLocationSettings();
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      // Ocultar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      if (mounted) {
        String errorMessage = '❌ Error al obtener ubicación.';
        SnackBarAction? action;
        
        if (e.toString().contains('Permisos de ubicación denegados')) {
          errorMessage = '❌ Permisos de ubicación denegados.';
          action = SnackBarAction(
            label: 'Configurar',
            textColor: Colors.white,
            onPressed: () async {
              await LocationUtils.openAppSettings();
            },
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            action: action,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }



  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreatingService = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      // No se requiere horario de trabajo

      // Combinar habilidades con experiencia si está presente
      final List<String> finalFeatures = List.from(_selectedSkills);
      if (_experienceController.text.trim().isNotEmpty) {
        final experienceText = _experienceController.text.trim();
        // Agregar prefijo si no lo tiene
        final formattedExperience = experienceText.startsWith('exp:') 
            ? experienceText 
            : 'exp: $experienceText';
        finalFeatures.add(formattedExperience);
      }

      // PASO 1: Crear el servicio primero (sin imágenes)
      final serviceModel = ServiceModel.createNew(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        price: _priceType == 'negotiable' ? 0.0 : double.parse(_priceController.text),
        priceType: _priceType,
        providerId: authState.user.id,
        providerName: authState.user.name,
        providerPhotoUrl: authState.user.photoUrl,
        mainImage: null, // Se añadirá después
        images: const [], // Se añadirán después
        tags: _selectedTags,
        features: finalFeatures,
        availableDays: _convertDaysToEnglish(_availableDays),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        timeRange: null, // Ya no se usa horario de trabajo
      );

      // Crear el servicio y obtener su ID real
      final serviceId = await widget.createServiceUseCase(
        CreateServiceParams(service: serviceModel),
      );

      // PASO 2: Subir imágenes con el ID real del servicio
      String? mainImageUrl;
      final List<String> allImages = List.from(_selectedImages);

      if (_mainImageFile != null || _newImages.isNotEmpty) {
        final imageStorageService = sl<ImageStorageService>();
        
        // Subir imagen principal si existe
        if (_mainImageFile != null) {
          try {
            mainImageUrl = await imageStorageService.uploadServiceImage(
              serviceId,
              _mainImageFile!,
            );
            if (mainImageUrl == null) {
              throw Exception('Error al subir la imagen principal del servicio');
            }
          } catch (e) {
            throw Exception('Error al subir la imagen principal: $e');
          }
        }

        // Subir nuevas imágenes si las hay
        if (_newImages.isNotEmpty) {
          try {
            final uploadedUrls = await imageStorageService.uploadMultipleServiceImages(
              serviceId,
              _newImages,
            );
            allImages.addAll(uploadedUrls);
          } catch (e) {
            throw Exception('Error al subir las imágenes adicionales: $e');
          }
        }

        // PASO 3: Actualizar el servicio con las URLs de las imágenes
        if (mainImageUrl != null || allImages.isNotEmpty) {
          final updatedServiceModel = serviceModel.copyWithModel(
            id: serviceId,
            mainImage: mainImageUrl,
            images: allImages,
          );

          await sl<UpdateServiceUseCase>().call(updatedServiceModel);
        }
      }

      if (mounted) {
        // Notificar que se creó un servicio para que otras páginas se refresquen
        ServiceRefreshNotifier().notifyServicesChanged();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Servicio creado exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Navegar directamente a la página principal
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al crear: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingService = false);
      }
    }
  }

} 