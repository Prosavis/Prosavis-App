import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Mock notifications data
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Nuevo servicio disponible',
      message: 'Juan Pérez está ofreciendo servicios de plomería en tu área',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      type: NotificationType.serviceAvailable,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Solicitud aceptada',
      message: 'María García ha aceptado tu solicitud de limpieza',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.requestAccepted,
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Servicio completado',
      message: 'El servicio de carpintería ha sido marcado como completado',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.serviceCompleted,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Nueva reseña',
      message: 'Has recibido una reseña de 5 estrellas por tu servicio',
      time: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.newReview,
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'Recordatorio de pago',
      message: 'Tienes un pago pendiente por el servicio de electricidad',
      time: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.paymentReminder,
      isRead: true,
    ),
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
          onPressed: () => context.pop(),
          icon: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Marcar como leídas',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildNotificationsList(),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    final readNotifications = _notifications.where((n) => n.isRead).toList();

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        if (unreadNotifications.isNotEmpty) ...[
          _buildSectionHeader('Nuevas'),
          ...unreadNotifications.map((notification) => 
            _buildNotificationTile(notification)),
          const SizedBox(height: 24),
        ],
        
        if (readNotifications.isNotEmpty) ...[
          _buildSectionHeader('Anteriores'),
          ...readNotifications.map((notification) => 
            _buildNotificationTile(notification)),
        ],
        
        if (_notifications.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade200 : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.1),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.time),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        onTap: () => _onNotificationTap(notification),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          const Icon(
            Symbols.notifications_off,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te notificaremos cuando tengas actualizaciones importantes',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.serviceAvailable:
        return Symbols.work;
      case NotificationType.requestAccepted:
        return Symbols.check_circle;
      case NotificationType.serviceCompleted:
        return Symbols.task_alt;
      case NotificationType.newReview:
        return Symbols.star;
      case NotificationType.paymentReminder:
        return Symbols.payment;
      case NotificationType.message:
        return Symbols.chat;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.serviceAvailable:
        return AppTheme.primaryColor;
      case NotificationType.requestAccepted:
        return Colors.green;
      case NotificationType.serviceCompleted:
        return Colors.blue;
      case NotificationType.newReview:
        return Colors.orange;
      case NotificationType.paymentReminder:
        return Colors.red;
      case NotificationType.message:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 30) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _onNotificationTap(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.serviceAvailable:
        // Navigate to service details
        break;
      case NotificationType.requestAccepted:
        // Navigate to service tracking
        break;
      case NotificationType.serviceCompleted:
        // Navigate to review page
        break;
      case NotificationType.newReview:
        // Navigate to reviews page
        break;
      case NotificationType.paymentReminder:
        // Navigate to payment page
        break;
      case NotificationType.message:
        // Navigate to chat
        break;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification.isRead = true;
      }
    });
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}

enum NotificationType {
  serviceAvailable,
  requestAccepted,
  serviceCompleted,
  newReview,
  paymentReminder,
  message,
} 