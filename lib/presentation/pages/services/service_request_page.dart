import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({super.key});

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  String? _selectedUrgency;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  bool _isFlexibleSchedule = false;
  final List<String> _selectedImages = [];

  final List<String> _urgencyOptions = [
    'Inmediato (hoy)',
    'Urgente (esta semana)',
    'Normal (próximas 2 semanas)',
    'Flexible (cuando sea posible)',
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
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
        ),
        title: Text(
          'Solicitar Servicio',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildRequestForm(),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(
              title: 'Información básica',
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
              title: 'Ubicación',
              child: _buildLocationField(),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Presupuesto',
              child: _buildBudgetField(),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Urgencia y horario',
              child: Column(
                children: [
                  _buildUrgencySelector(),
                  const SizedBox(height: 16),
                  _buildScheduleSelector(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildFormSection(
              title: 'Imágenes (opcional)',
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
        return DropdownMenuItem<String>(
          value: category['name'],
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
        hintText: 'Ej: Reparación de grifo de cocina',
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
        labelText: 'Descripción detallada',
        hintText: 'Describe exactamente qué necesitas, incluye detalles específicos...',
        prefixIcon: Icon(Symbols.description),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor describe el servicio que necesitas';
        }
        if (value.length < 20) {
          return 'La descripción debe tener al menos 20 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Dirección o ubicación',
        hintText: 'Ingresa la dirección donde se realizará el servicio',
        prefixIcon: const Icon(Symbols.location_on),
        suffixIcon: IconButton(
          onPressed: () {
            // TODO: Implement location picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selector de ubicación próximamente')),
            );
          },
          icon: const Icon(Symbols.my_location),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa la ubicación';
        }
        return null;
      },
    );
  }

  Widget _buildBudgetField() {
    return TextFormField(
      controller: _budgetController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Presupuesto estimado',
        hintText: 'Ingresa tu presupuesto en USD',
        prefixIcon: Icon(Symbols.attach_money),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un presupuesto';
        }
        final budget = double.tryParse(value);
        if (budget == null || budget <= 0) {
          return 'Ingresa un presupuesto válido';
        }
        return null;
      },
    );
  }

  Widget _buildUrgencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nivel de urgencia',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ..._urgencyOptions.map((option) {
          return RadioListTile<String>(
            title: Text(
              option,
              style: GoogleFonts.inter(fontSize: 14),
            ),
            value: option,
            groupValue: _selectedUrgency,
            onChanged: (value) {
              setState(() {
                _selectedUrgency = value;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryColor,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScheduleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isFlexibleSchedule,
              onChanged: (value) {
                setState(() {
                  _isFlexibleSchedule = value ?? false;
                  if (_isFlexibleSchedule) {
                    _preferredDate = null;
                    _preferredTime = null;
                  }
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            Expanded(
              child: Text(
                'Horario flexible',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        
        if (!_isFlexibleSchedule) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(),
                  icon: const Icon(Symbols.calendar_today),
                  label: Text(
                    _preferredDate != null
                        ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                        : 'Seleccionar fecha',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectTime(),
                  icon: const Icon(Symbols.schedule),
                  label: Text(
                    _preferredTime != null
                        ? _preferredTime!.format(context)
                        : 'Seleccionar hora',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adjunta imágenes para ayudar a los profesionales a entender mejor tu solicitud',
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
              color: AppTheme.backgroundLight,
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
                  'Tocar para agregar imágenes',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.map((image) {
              return Container(
                width: 80,
                height: 80,
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
                        onTap: () => _removeImage(image),
                        child: Container(
                          padding: const EdgeInsets.all(2),
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
                  ],
                ),
              );
            }).toList(),
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
        onPressed: _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Publicar Solicitud',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _preferredDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _preferredTime = time;
      });
    }
  }

  void _addImage() {
    // TODO: Implement image picker
    setState(() {
      _selectedImages.add('image_${_selectedImages.length + 1}');
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

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      if (_selectedUrgency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona el nivel de urgencia')),
        );
        return;
      }

      if (!_isFlexibleSchedule && (_preferredDate == null || _preferredTime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona fecha y hora preferidas')),
        );
        return;
      }

      // TODO: Implement actual submission logic
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
          '¡Solicitud publicada!',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tu solicitud ha sido publicada exitosamente. Los profesionales interesados se pondrán en contacto contigo pronto.',
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