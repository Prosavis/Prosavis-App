import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permission_handler/permission_handler.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/image_storage_service.dart';
import '../../../core/injection/injection_container.dart' as di;
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

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

    _fadeController.forward();
    _loadUserData();
  }

  void _loadUserData() async {
    // Cargar datos del perfil usando el ProfileBloc
    context.read<ProfileBloc>().add(LoadProfile());
  }

  ImageProvider? _getProfileImage(AuthState authState) {
    // Si hay una imagen seleccionada localmente, mostrarla
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('http')) {
        // Es una URL de Firebase
        return NetworkImage(_profileImageUrl!);
      } else {
        // Es una ruta local
        return FileImage(File(_profileImageUrl!));
      }
    }
    
    // Si no hay imagen local, usar la del usuario autenticado
    if (authState is AuthAuthenticated && authState.user.photoUrl != null) {
      return NetworkImage(authState.user.photoUrl!);
    }
    
    return null;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            // Llenar los controladores con los datos cargados
            setState(() {
              _nameController.text = state.user.name;
              _emailController.text = state.user.email;
              _phoneController.text = state.user.phoneNumber ?? '';
              // Agregar otros campos cuando estén disponibles en UserEntity
              _profileImageUrl = state.user.photoUrl;
            });
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        child: SafeArea(
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
              icon: const Icon(
                Symbols.arrow_back,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Editar Perfil',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Guardar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isLoading ? AppTheme.textTertiary : AppTheme.primaryColor,
                ),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar del usuario
              Center(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _getProfileImage(authState),
                          backgroundColor: AppTheme.primaryColor,
                          child: _getProfileImage(authState) == null
                              ? (authState is AuthAuthenticated
                                  ? Text(
                                      authState.user.name.isNotEmpty 
                                          ? authState.user.name[0].toUpperCase()
                                          : 'U',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                      ),
                                    )
                                  : const Icon(
                                      Symbols.person,
                                      size: 60,
                                      color: Colors.white,
                                    ))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              onPressed: _changeProfileImage,
                              icon: const Icon(
                                Symbols.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Formulario
              _buildSectionTitle('Información Personal'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Symbols.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Symbols.email,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email no editable
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo es requerido';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Symbols.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                      return 'Ingresa un teléfono válido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _locationController,
                label: 'Ubicación',
                icon: Symbols.location_on,
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Acerca de ti'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _bioController,
                label: 'Biografía',
                icon: Symbols.description,
                maxLines: 4,
                maxLength: 200,
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
                      child: Text(
                        'Tu información personal está protegida y solo será visible para los proveedores cuando solicites un servicio.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.inter(
        color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
      ),
    );
  }

  void _changeProfileImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambiar Foto de Perfil',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Symbols.camera_alt,
                  label: 'Cámara',
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage();
                  },
                ),
                _buildImageOption(
                  icon: Symbols.photo_library,
                  label: 'Galería',
                  onTap: () {
                    Navigator.pop(context);
                    _selectFromGallery();
                  },
                ),
                _buildImageOption(
                  icon: Symbols.delete,
                  label: 'Eliminar',
                  onTap: () {
                    Navigator.pop(context);
                    _deletePhoto();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      // Solicitar permiso de cámara
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _showPermissionDeniedDialog('cámara');
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        // Mostrar indicador de carga
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('Subiendo imagen...', style: GoogleFonts.inter()),
                ],
              ),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        try {
          // Obtener el usuario actual para el ID
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final imageStorageService = di.sl<ImageStorageService>();
            final uploadedUrl = await imageStorageService.uploadProfileImage(
              authState.user.id,
              File(image.path),
            );

            if (uploadedUrl != null) {
              setState(() {
                _profileImageUrl = uploadedUrl;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Imagen subida exitosamente. Guarda el perfil para aplicar los cambios.',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              throw Exception('Error al subir la imagen');
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al subir imagen: ${e.toString()}',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al capturar imagen: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      // Solicitar permiso de galería
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        final result = await Permission.photos.request();
        if (result.isDenied) {
          _showPermissionDeniedDialog('galería');
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        // Mostrar indicador de carga
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('Subiendo imagen...', style: GoogleFonts.inter()),
                ],
              ),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        try {
          // Obtener el usuario actual para el ID
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final imageStorageService = di.sl<ImageStorageService>();
            final uploadedUrl = await imageStorageService.uploadProfileImage(
              authState.user.id,
              File(image.path),
            );

            if (uploadedUrl != null) {
              setState(() {
                _profileImageUrl = uploadedUrl;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Imagen subida exitosamente. Guarda el perfil para aplicar los cambios.',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              throw Exception('Error al subir la imagen');
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al subir imagen: ${e.toString()}',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al seleccionar imagen: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deletePhoto() {
    setState(() {
      _profileImageUrl = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto eliminada. Guarda el perfil para aplicar los cambios.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permiso Requerido',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'La aplicación necesita acceso a $permission para esta funcionalidad. Por favor, concede el permiso en la configuración.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Ir a Configuración',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener usuario actual del AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      final currentUser = authState.user;

      // Crear usuario actualizado con los nuevos datos
      final updatedUser = UserEntity(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(), // Email no se puede cambiar por seguridad
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        photoUrl: _profileImageUrl,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      // Capturar referencias al context antes de operaciones asíncronas
      final authBloc = context.read<AuthBloc>();
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final firestoreService = FirestoreService();
      
      await firestoreService.createOrUpdateUser(updatedUser);

      // Verificar que el widget esté montado antes de continuar
      if (!mounted) return;

      // Actualizar el AuthBloc con el usuario actualizado
      authBloc.add(AuthUserUpdated(updatedUser));

      // Mostrar mensaje de éxito y navegar
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Perfil actualizado exitosamente',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar el perfil: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}