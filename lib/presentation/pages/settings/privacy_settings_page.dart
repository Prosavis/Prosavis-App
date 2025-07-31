import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Estados de privacidad
  bool _profileVisible = true;
  bool _phoneVisible = false;
  bool _emailVisible = false;
  bool _locationSharing = true;
  bool _activityStatus = true;
  bool _dataAnalytics = false;
  bool _personalizedAds = false;

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

    _loadPrivacySettings();
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
              icon: const Icon(
                Symbols.arrow_back,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Privacidad y Seguridad',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
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
              'Controla quién puede ver tu información y cómo usamos tus datos',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Sección Visibilidad del Perfil
            _buildSectionTitle('Visibilidad del Perfil'),
            const SizedBox(height: 16),
            
            _buildPrivacyTile(
              icon: Symbols.visibility,
              title: 'Perfil Público',
              subtitle: 'Los proveedores pueden ver tu perfil',
              value: _profileVisible,
              onChanged: (value) => setState(() => _profileVisible = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildPrivacyTile(
              icon: Symbols.phone,
              title: 'Teléfono Visible',
              subtitle: 'Mostrar número de teléfono a proveedores',
              value: _phoneVisible,
              onChanged: (value) => setState(() => _phoneVisible = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildPrivacyTile(
              icon: Symbols.email,
              title: 'Email Visible',
              subtitle: 'Mostrar correo electrónico a proveedores',
              value: _emailVisible,
              onChanged: (value) => setState(() => _emailVisible = value),
            ),

            const SizedBox(height: 32),

            // Sección Ubicación y Actividad
            _buildSectionTitle('Ubicación y Actividad'),
            const SizedBox(height: 16),
            
            _buildPrivacyTile(
              icon: Symbols.location_on,
              title: 'Compartir Ubicación',
              subtitle: 'Permitir que los proveedores vean tu ubicación',
              value: _locationSharing,
              onChanged: (value) => setState(() => _locationSharing = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildPrivacyTile(
              icon: Symbols.radio_button_checked,
              title: 'Estado de Actividad',
              subtitle: 'Mostrar cuando estás en línea',
              value: _activityStatus,
              onChanged: (value) => setState(() => _activityStatus = value),
            ),

            const SizedBox(height: 32),

            // Sección Datos y Análisis
            _buildSectionTitle('Datos y Análisis'),
            const SizedBox(height: 16),
            
            _buildPrivacyTile(
              icon: Symbols.analytics,
              title: 'Análisis de Datos',
              subtitle: 'Ayúdanos a mejorar la app con datos anónimos',
              value: _dataAnalytics,
              onChanged: (value) => setState(() => _dataAnalytics = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildPrivacyTile(
              icon: Symbols.ads_click,
              title: 'Anuncios Personalizados',
              subtitle: 'Recibir anuncios basados en tus preferencias',
              value: _personalizedAds,
              onChanged: (value) => setState(() => _personalizedAds = value),
            ),

            const SizedBox(height: 32),

            // Acciones adicionales
            _buildSectionTitle('Administrar Datos'),
            const SizedBox(height: 16),

            _buildActionTile(
              icon: Symbols.download,
              title: 'Descargar mis Datos',
              subtitle: 'Obtén una copia de tu información',
              onTap: _requestDataDownload,
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              icon: Symbols.delete_forever,
              title: 'Eliminar mi Cuenta',
              subtitle: 'Eliminar permanentemente tu cuenta y datos',
              onTap: _requestAccountDeletion,
              isDestructive: true,
            ),

            const SizedBox(height: 32),

            // Información legal
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Symbols.shield,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tu Privacidad es Importante',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Protegemos tu información personal con encriptación de extremo a extremo y nunca la compartimos con terceros sin tu consentimiento.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePrivacySettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Guardar Configuración',
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
      ),
    );
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cargar desde Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _profileVisible = data['profileVisible'] ?? true;
            _phoneVisible = data['phoneVisible'] ?? false;
            _emailVisible = data['emailVisible'] ?? false;
            _locationSharing = data['locationSharing'] ?? true;
            _activityStatus = data['activityStatus'] ?? true;
            _dataAnalytics = data['dataAnalytics'] ?? false;
            _personalizedAds = data['personalizedAds'] ?? false;
          });
        }
      } else {
        // Cargar desde SharedPreferences si no hay usuario autenticado
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _profileVisible = prefs.getBool('privacy_profileVisible') ?? true;
          _phoneVisible = prefs.getBool('privacy_phoneVisible') ?? false;
          _emailVisible = prefs.getBool('privacy_emailVisible') ?? false;
          _locationSharing = prefs.getBool('privacy_locationSharing') ?? true;
          _activityStatus = prefs.getBool('privacy_activityStatus') ?? true;
          _dataAnalytics = prefs.getBool('privacy_dataAnalytics') ?? false;
          _personalizedAds = prefs.getBool('privacy_personalizedAds') ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando configuración de privacidad: $e');
    }
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

  Widget _buildPrivacyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
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
            color: AppTheme.primaryColor,
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
                    color: AppTheme.textPrimary,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
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
            color: AppTheme.surfaceColor,
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
              const Icon(
                Symbols.chevron_right,
                size: 20,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDataDownloadRequest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Crear solicitud de descarga en Firestore
        await FirebaseFirestore.instance
            .collection('data_requests')
            .add({
          'userId': user.uid,
          'type': 'data_download',
          'status': 'pending',
          'requestDate': FieldValue.serverTimestamp(),
          'userEmail': user.email,
          'estimatedCompletion': DateTime.now().add(const Duration(hours: 48)),
        });

        // Enviar notificación al equipo de soporte (esto se puede implementar con Cloud Functions)
        // También se puede enviar un email automático
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Solicitud enviada exitosamente. Recibirás un correo en 48 horas.',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Debes iniciar sesión para solicitar tus datos.',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al procesar solicitud: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _requestDataDownload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Descargar Datos',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Te enviaremos un enlace por correo electrónico para descargar todos tus datos en un plazo de 48 horas.',
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
              _handleDataDownloadRequest();
            },
            child: Text(
              'Solicitar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccountDeletion() async {
    // Mostrar otro diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '⚠️ Confirmar Eliminación',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.errorColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción es IRREVERSIBLE. Se eliminará:',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('• Tu perfil y datos personales', style: GoogleFonts.inter()),
            Text('• Tu historial de servicios', style: GoogleFonts.inter()),
            Text('• Todas tus reseñas y calificaciones', style: GoogleFonts.inter()),
            Text('• Configuraciones y preferencias', style: GoogleFonts.inter()),
            const SizedBox(height: 12),
            Text(
              'Escribe "ELIMINAR" para confirmar:',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          StatefulBuilder(
            builder: (context, setState) {
              final confirmController = TextEditingController();
              return Column(
                children: [
                  TextField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe "ELIMINAR"',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: confirmController.text == 'ELIMINAR'
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    child: Text(
                      'Eliminar Cuenta',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Crear solicitud de eliminación en Firestore
          await FirebaseFirestore.instance
              .collection('deletion_requests')
              .add({
            'userId': user.uid,
            'status': 'pending',
            'requestDate': FieldValue.serverTimestamp(),
            'userEmail': user.email,
            'scheduledDeletion': DateTime.now().add(const Duration(days: 7)),
          });

          // Marcar la cuenta como pendiente de eliminación
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'accountStatus': 'pending_deletion',
            'deletionRequestDate': FieldValue.serverTimestamp(),
          });

          // Cerrar sesión del usuario
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Solicitud de eliminación procesada. Tu cuenta será eliminada en 7 días.',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );

            // Navegar a la pantalla de login
            if (mounted) {
              context.go('/login');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al procesar eliminación: ${e.toString()}',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _requestAccountDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Cuenta',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.errorColor,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos permanentemente.',
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
              _handleAccountDeletion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _savePrivacySettings() async {
    try {
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Guardando configuración...',
                style: GoogleFonts.inter(),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      final privacyData = {
        'profileVisible': _profileVisible,
        'phoneVisible': _phoneVisible,
        'emailVisible': _emailVisible,
        'locationSharing': _locationSharing,
        'activityStatus': _activityStatus,
        'dataAnalytics': _dataAnalytics,
        'personalizedAds': _personalizedAds,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (user != null) {
        // Guardar en Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .set(privacyData, SetOptions(merge: true));

        // También actualizar en el documento principal del usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'privacySettings': privacyData,
        });
      }

      // Guardar también en SharedPreferences como backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_profileVisible', _profileVisible);
      await prefs.setBool('privacy_phoneVisible', _phoneVisible);
      await prefs.setBool('privacy_emailVisible', _emailVisible);
      await prefs.setBool('privacy_locationSharing', _locationSharing);
      await prefs.setBool('privacy_activityStatus', _activityStatus);
      await prefs.setBool('privacy_dataAnalytics', _dataAnalytics);
      await prefs.setBool('privacy_personalizedAds', _personalizedAds);

      // Mostrar mensaje de éxito
      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Configuración de privacidad guardada exitosamente',
          style: GoogleFonts.inter(),
                ),
              ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
      }
    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al guardar: ${e.toString()}',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error guardando configuración de privacidad: $e');
    }
  }
}