import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ServiceCreationPage extends StatefulWidget {
  const ServiceCreationPage({super.key});

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

  String? _selectedCategory;
  String? _priceType = 'fixed';
  final List<String> _selectedImages = [];
  final List<String> _selectedSkills = [];
  bool _isAvailableNow = true;
  final List<String> _availableDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _priceTypes = [
    'fixed',
    'hourly',
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

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
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
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildCreationForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(
              title: 'Información del servicio',
              child: Column(
                children: [
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Precios',
              child: Column(
                children: [
                  _buildPriceTypeSelector(),
                  const SizedBox(height: 16),
                  _buildPriceField(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Experiencia',
              child: _buildExperienceField(),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Disponibilidad',
              child: Column(
                children: [
                  _buildAvailabilityToggle(),
                  const SizedBox(height: 16),
                  _buildScheduleSelector(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Habilidades adicionales',
              child: _buildSkillsSelector(),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Galería de trabajos',
              child: _buildImageUpload(),
            ),
            
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Categoría del servicio',
        prefixIcon: Icon(Symbols.category),
      ),
      items: AppConstants.serviceCategories.map((category) {
        final categoryName = AppConstants.getCategoryName(category);
        return DropdownMenuItem<String>(
          value: categoryName,
          child: Row(
            children: [
              Icon(_getCategoryIcon(categoryName), size: 20),
              const SizedBox(width: 8),
              Text(categoryName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona una categoría';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Título del servicio',
        hintText: 'Ej: Instalación y reparación de tuberías',
        prefixIcon: Icon(Symbols.title),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un título';
        }
        if (value.length < 10) {
          return 'El título debe tener al menos 10 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Descripción del servicio',
        hintText: 'Describe tu servicio, experiencia, qué incluye, etc...',
        prefixIcon: Icon(Symbols.description),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor describe tu servicio';
        }
        if (value.length < 30) {
          return 'La descripción debe tener al menos 30 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildPriceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de precio',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _priceTypes.map((type) {
            final isSelected = _priceType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _priceType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _getPriceTypeName(type),
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
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      enabled: _priceType != 'negotiable',
      decoration: InputDecoration(
        labelText: _getPriceFieldLabel(),
        hintText: _priceType == 'negotiable' ? 'A convenir' : 'Ingresa tu precio',
        prefixIcon: const Icon(Symbols.attach_money),
        prefixText: _priceType != 'negotiable' ? '\$ ' : null,
      ),
      validator: (value) {
        if (_priceType == 'negotiable') return null;
        
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un precio';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Ingresa un precio válido';
        }
        return null;
      },
    );
  }

  Widget _buildExperienceField() {
    return TextFormField(
      controller: _experienceController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Experiencia y certificaciones',
        hintText: 'Años de experiencia, certificaciones, trabajos anteriores...',
        prefixIcon: Icon(Symbols.school),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor describe tu experiencia';
        }
        return null;
      },
    );
  }

  Widget _buildAvailabilityToggle() {
    return Row(
      children: [
        Checkbox(
          value: _isAvailableNow,
          onChanged: (value) {
            setState(() {
              _isAvailableNow = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        Expanded(
          child: Text(
            'Disponible para trabajar inmediatamente',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSelector() {
    return Column(
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
        
        const SizedBox(height: 16),
        
        Text(
          'Horario de trabajo',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartTime(),
                icon: const Icon(Symbols.schedule),
                label: Text(
                  _startTime != null
                      ? 'Desde: ${_startTime!.format(context)}'
                      : 'Hora de inicio',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndTime(),
                icon: const Icon(Symbols.schedule),
                label: Text(
                  _endTime != null
                      ? 'Hasta: ${_endTime!.format(context)}'
                      : 'Hora de fin',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsSelector() {
    return Column(
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
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agrega fotos de trabajos anteriores para mostrar tu calidad',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
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
        
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Symbols.image,
                        color: AppTheme.textTertiary,
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
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ElevatedButton(
        onPressed: _submitService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Publicar Servicio',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plomería':
        return Symbols.plumbing;
      case 'electricidad':
        return Symbols.electrical_services;
      case 'limpieza':
        return Symbols.cleaning_services;
      case 'jardinería':
        return Symbols.yard;
      case 'carpintería':
        return Symbols.construction;
      case 'pintura':
        return Symbols.format_paint;
      case 'mecánica':
        return Symbols.build;
      case 'tecnología':
        return Symbols.computer;
      case 'tutoría':
        return Symbols.school;
      default:
        return Symbols.home_repair_service;
    }
  }

  String _getPriceTypeName(String type) {
    switch (type) {
      case 'fixed':
        return 'Precio fijo';
      case 'hourly':
        return 'Por hora';
      case 'daily':
        return 'Por día';
      case 'negotiable':
        return 'Negociable';
      default:
        return type;
    }
  }

  String _getPriceFieldLabel() {
    switch (_priceType) {
      case 'fixed':
        return 'Precio fijo del servicio';
      case 'hourly':
        return 'Precio por hora';
      case 'daily':
        return 'Precio por día';
      case 'negotiable':
        return 'Precio negociable';
      default:
        return 'Precio';
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _addImage() {
    // Implementar selector de imágenes en próximas actualizaciones
    setState(() {
      _selectedImages.add('work_image_${_selectedImages.length + 1}');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selector de imágenes próximamente')),
    );
  }

  void _removeImage(String image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  void _submitService() {
    if (_formKey.currentState!.validate()) {
      if (_availableDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona al menos un día disponible')),
        );
        return;
      }

      // Implementar lógica de envío en próximas actualizaciones
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Symbols.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: Text(
          '¡Servicio publicado!',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tu servicio ha sido publicado exitosamente. Los clientes podrán encontrarte y contactarte pronto.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close page
            },
            child: Text(
              'Entendido',
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
} 