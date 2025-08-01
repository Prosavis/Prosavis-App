import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/themes/app_theme.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final Function(File) onImageSelected;
  final VoidCallback? onRemoveImage;
  final bool hasCurrentImage;

  const ImagePickerBottomSheet({
    super.key,
    required this.onImageSelected,
    this.onRemoveImage,
    this.hasCurrentImage = false,
  });

  static void show(
    BuildContext context, {
    required Function(File) onImageSelected,
    VoidCallback? onRemoveImage,
    bool hasCurrentImage = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerBottomSheet(
        onImageSelected: onImageSelected,
        onRemoveImage: onRemoveImage,
        hasCurrentImage: hasCurrentImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Foto de Perfil',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Options
            _buildOption(
              context,
              icon: Symbols.photo_camera,
              title: 'Tomar Foto',
              subtitle: 'Usar la cámara',
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            
            _buildOption(
              context,
              icon: Symbols.photo_library,
              title: 'Galería',
              subtitle: 'Seleccionar de la galería',
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            
            if (hasCurrentImage && onRemoveImage != null) ...[
              const SizedBox(height: 12),
              _buildOption(
                context,
                icon: Symbols.delete,
                title: 'Eliminar Foto',
                subtitle: 'Quitar foto actual',
                onTap: () {
                  Navigator.pop(context);
                  onRemoveImage!();
                },
                isDestructive: true,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Cancel button
            _buildOption(
              context,
              icon: Symbols.close,
              title: 'Cancelar',
              subtitle: 'Cerrar sin cambios',
              onTap: () => Navigator.pop(context),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
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
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      // Pedir permisos según la fuente
      final Permission permission = source == ImageSource.camera
          ? Permission.camera
          : Permission.photos;

      final PermissionStatus status = await permission.request();
      
      if (status.isDenied) {
        if (context.mounted) {
          _showPermissionDialog(context, source);
        }
        return;
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(context, source);
        }
        return;
      }

      // Seleccionar imagen
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        Navigator.pop(context);
        onImageSelected(File(pickedFile.path));
      }
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showPermissionDialog(BuildContext context, ImageSource source) {
    final String sourceName = source == ImageSource.camera ? 'cámara' : 'galería';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permiso Requerido',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Para acceder a la $sourceName necesitamos tu permiso.',
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
              _pickImage(context, source);
            },
            child: Text(
              'Reintentar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, ImageSource source) {
    final String sourceName = source == ImageSource.camera ? 'cámara' : 'galería';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permiso Permanentemente Denegado',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Para acceder a la $sourceName, ve a Configuración y habilita los permisos.',
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
              'Configuración',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


}