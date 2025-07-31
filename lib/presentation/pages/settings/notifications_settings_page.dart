import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Estados de las notificaciones
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _bookingUpdates = true;
  bool _promotions = false;
  bool _messageNotifications = true;
  bool _reminderNotifications = true;

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

    _loadNotificationSettings();
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
              'Notificaciones',
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
              'Configura cómo quieres recibir notificaciones',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Sección General
            _buildSectionTitle('General'),
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Symbols.notifications,
              title: 'Notificaciones Push',
              subtitle: 'Recibir notificaciones en tu dispositivo',
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildNotificationTile(
              icon: Symbols.email,
              title: 'Notificaciones por Email',
              subtitle: 'Recibir actualizaciones en tu correo',
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),

            const SizedBox(height: 32),

            // Sección Servicios
            _buildSectionTitle('Servicios'),
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Symbols.event_available,
              title: 'Actualizaciones de Reservas',
              subtitle: 'Confirmaciones, cambios y recordatorios',
              value: _bookingUpdates,
              onChanged: (value) => setState(() => _bookingUpdates = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildNotificationTile(
              icon: Symbols.schedule,
              title: 'Recordatorios',
              subtitle: 'Antes de tus citas programadas',
              value: _reminderNotifications,
              onChanged: (value) => setState(() => _reminderNotifications = value),
            ),
            
            const SizedBox(height: 12),
            
            _buildNotificationTile(
              icon: Symbols.chat,
              title: 'Mensajes',
              subtitle: 'Nuevos mensajes de proveedores',
              value: _messageNotifications,
              onChanged: (value) => setState(() => _messageNotifications = value),
            ),

            const SizedBox(height: 32),

            // Sección Marketing
            _buildSectionTitle('Marketing'),
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Symbols.local_offer,
              title: 'Promociones y Ofertas',
              subtitle: 'Descuentos y ofertas especiales',
              value: _promotions,
              onChanged: (value) => setState(() => _promotions = value),
            ),

            const SizedBox(height: 48),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNotificationSettings,
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

  Future<void> _loadNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cargar desde Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _pushNotifications = data['pushNotifications'] ?? true;
            _emailNotifications = data['emailNotifications'] ?? false;
            _bookingUpdates = data['bookingUpdates'] ?? true;
            _promotions = data['promotions'] ?? false;
            _messageNotifications = data['messageNotifications'] ?? true;
            _reminderNotifications = data['reminderNotifications'] ?? true;
          });
        }
      } else {
        // Cargar desde SharedPreferences si no hay usuario autenticado
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _pushNotifications = prefs.getBool('notif_pushNotifications') ?? true;
          _emailNotifications = prefs.getBool('notif_emailNotifications') ?? false;
          _bookingUpdates = prefs.getBool('notif_bookingUpdates') ?? true;
          _promotions = prefs.getBool('notif_promotions') ?? false;
          _messageNotifications = prefs.getBool('notif_messageNotifications') ?? true;
          _reminderNotifications = prefs.getBool('notif_reminderNotifications') ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando configuración de notificaciones: $e');
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

  Widget _buildNotificationTile({
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

  void _saveNotificationSettings() async {
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
      final notificationData = {
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'bookingUpdates': _bookingUpdates,
        'promotions': _promotions,
        'messageNotifications': _messageNotifications,
        'reminderNotifications': _reminderNotifications,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (user != null) {
        // Guardar en Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .set(notificationData, SetOptions(merge: true));

        // También actualizar en el documento principal del usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'notificationSettings': notificationData,
        });
      }

      // Guardar también en SharedPreferences como backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_pushNotifications', _pushNotifications);
      await prefs.setBool('notif_emailNotifications', _emailNotifications);
      await prefs.setBool('notif_bookingUpdates', _bookingUpdates);
      await prefs.setBool('notif_promotions', _promotions);
      await prefs.setBool('notif_messageNotifications', _messageNotifications);
      await prefs.setBool('notif_reminderNotifications', _reminderNotifications);

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
                  'Configuración de notificaciones guardada exitosamente',
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
      debugPrint('Error guardando configuración de notificaciones: $e');
    }
  }
}