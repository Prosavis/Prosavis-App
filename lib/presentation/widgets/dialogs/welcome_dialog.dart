import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';

class WelcomeDialog extends StatelessWidget {
  final VoidCallback onOfferServiceTapped;
  final VoidCallback? onClose;

  const WelcomeDialog({
    super.key,
    required this.onOfferServiceTapped,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onOfferServiceTapped,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => WelcomeDialog(
        onOfferServiceTapped: onOfferServiceTapped,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con botón de cerrar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onClose?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.getTextSecondary(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Symbols.close,
                        size: 20,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Icono de éxito
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Symbols.check_circle,
                      size: 40,
                      color: Colors.white,
                      fill: 1,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Título principal
                  Text(
                    '¡Bienvenido a Prosavis!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Mensaje de éxito
                  Text(
                    'Ya has iniciado sesión exitosamente',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Mensaje informativo
                  Text(
                    'Ahora puedes comenzar a ofrecer tus servicios y conectar con clientes en tu área.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón principal - Ofrecer servicios
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onOfferServiceTapped();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Symbols.work,
                            size: 20,
                            fill: 1,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Comenzar a Ofrecer',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón secundario - Explorar después
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose?.call();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Explorar después',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
