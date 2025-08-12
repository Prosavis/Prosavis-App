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
import '../../../domain/entities/service_entity.dart';
import '../../../domain/usecases/services/get_service_by_id_usecase.dart';
import '../../../domain/usecases/services/update_service_usecase.dart';
import '../../../data/services/image_storage_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/image_picker_bottom_sheet.dart';

class ServiceEditPage extends StatefulWidget {
  final String serviceId;
  
  const ServiceEditPage({super.key, required this.serviceId});

  @override
  State<ServiceEditPage> createState() => _ServiceEditPageState();
}

class _ServiceEditPageState extends State<ServiceEditPage> {
  late final GetServiceByIdUseCase _getServiceByIdUseCase;
  late final UpdateServiceUseCase _updateServiceUseCase;
  
  ServiceEntity? _service;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

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
  List<String> _selectedImages = [];
  final List<File> _newImages = []; // Nuevas imágenes seleccionadas
  List<String> _selectedTags = [];
  List<String> _selectedSkills = [];
  List<String> _availableDays = [];


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
    _getServiceByIdUseCase = sl<GetServiceByIdUseCase>();
    _updateServiceUseCase = sl<UpdateServiceUseCase>();
    _loadService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    super.dispose();
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
      _titleController.text = service.title;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _selectedCategory = service.category;
      _priceType = service.priceType;
      _mainImageUrl = service.mainImage; // Cargar imagen principal
      _selectedImages = List.from(service.images);
      _selectedTags = List.from(service.tags);
      _selectedSkills = List.from(service.features);
      _availableDays = List.from(service.availableDays);
      _addressController.text = service.address ?? '';
      // Cargar experiencia si está disponible en los tags o features
      if (service.features.isNotEmpty) {
        final experienceFeature = service.features.firstWhere(
          (feature) => feature.toLowerCase().contains('experiencia') || 
                      feature.toLowerCase().contains('años') ||
                      feature.toLowerCase().contains('exp:'),
          orElse: () => '',
        );
        if (experienceFeature.isNotEmpty) {
          _experienceController.text = experienceFeature;
          // Remover de features para no duplicar
          _selectedSkills.remove(experienceFeature);
        }
      }

      setState(() {
        _service = service;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el servicio: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      final imageStorageService = sl<ImageStorageService>();

      // Subir imagen principal si hay una nueva
      String? mainImageUrl = _mainImageUrl;
      if (_mainImageFile != null) {
        try {
          mainImageUrl = await imageStorageService.uploadServiceImage(
            widget.serviceId,
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

      final updatedService = _service!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory!,
        priceType: _priceType,
        mainImage: mainImageUrl,
        images: allImages,
        tags: _selectedTags,
        features: finalFeatures,
        availableDays: _availableDays,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        timeRange: null, // Ya no se usa horario de trabajo
        updatedAt: DateTime.now(),
      );

      await _updateServiceUseCase(updatedService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Servicio actualizado exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Regresar a la página anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al actualizar: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Symbols.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppTheme.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Editar servicio',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        actions: [
          if (!_isLoading && _service != null)
            TextButton(
              onPressed: _isUpdating ? null : _updateService,
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Guardar',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando servicio...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_outline,
              size: 64,
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadService,
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        ),
      );
    }

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
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkSurfaceVariant.withValues(alpha: 0.6)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.edit_note,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar servicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'Actualiza la información de tu servicio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.primaryColor.withValues(alpha: 0.8),
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
              color: AppTheme.getTextSecondary(context),
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
                      color: isSelected
                          ? Colors.white
                          : AppTheme.getTextSecondary(context),
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
              color: AppTheme.getTextTertiary(context),
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
                      color: isSelected
                          ? Colors.white
                          : AppTheme.getTextSecondary(context),
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
              color: AppTheme.getTextTertiary(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurfaceVariant.withValues(alpha: 0.4)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.info,
                  size: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta imagen se mostrará como portada principal del servicio',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextSecondary
                          : Colors.blue.shade800,
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
                        : (_mainImageUrl != null && _mainImageUrl!.startsWith('https://'))
                            ? Image.network(
                                _mainImageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryColor,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Symbols.broken_image,
                                        size: 32,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  );
                                },
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
              color: AppTheme.getTextTertiary(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurfaceVariant.withValues(alpha: 0.4)
                  : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : Colors.amber.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.info,
                  size: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Máximo 4 imágenes',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextSecondary
                          : Colors.amber.shade800,
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
                    Icon(
                      Symbols.add_a_photo,
                      size: 32,
                      color: AppTheme.getTextTertiary(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agregar fotos de trabajos',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.getTextTertiary(context),
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
                  final imageUrl = _selectedImages[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.startsWith('https://')
                              ? Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Symbols.broken_image,
                                              color: AppTheme.textTertiary,
                                              size: 30,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Error',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
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
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Existente',
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface
                  : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : _updateService,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isUpdating
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
                      Text('Actualizando...'),
                    ],
                  )
                : Text(
                    'Guardar cambios',
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
            onPressed: _isUpdating ? null : () => context.pop(),
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
}