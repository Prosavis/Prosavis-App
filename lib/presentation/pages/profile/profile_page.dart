import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../blocs/theme/theme_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../widgets/common/image_picker_bottom_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Determina si usar FileImage o NetworkImage
  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    
    // Si es una ruta local (archivo), usar FileImage
    if (photoUrl.startsWith('/') || photoUrl.contains('Documents')) {
      return FileImage(File(photoUrl));
    }
    
    // Si es una URL, usar NetworkImage
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  _buildProfileHeader(authState),
                  _buildProfileOptions(authState),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Text(
          'Perfil',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthState authState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Avatar y información del usuario
            if (authState is AuthAuthenticated) ...[
              BlocConsumer<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  } else if (state is ProfilePhotoUpdated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto de perfil actualizada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is ProfilePhotoRemoved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto de perfil eliminada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                builder: (context, profileState) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showImagePicker(context, authState.user.photoUrl),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _getImageProvider(authState.user.photoUrl),
                          backgroundColor: AppTheme.primaryColor,
                          child: authState.user.photoUrl == null
                              ? const Icon(
                                  Symbols.person,
                                  color: Colors.white,
                                  size: 50,
                                )
                              : null,
                        ),
                      ),
                      // Indicador de carga
                      if (profileState is ProfileUpdating)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      // Indicador de edición
                      if (profileState is! ProfileUpdating)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Symbols.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                authState.user.name,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authState.user.email,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ] else ...[
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(
                  Symbols.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Usuario Invitado',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inicia sesión para acceder a todas las funciones',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptions(AuthState authState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Cuenta
            if (authState is! AuthAuthenticated) ...[
              _buildSectionTitle('Cuenta'),
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Symbols.login,
                title: 'Iniciar Sesión',
                subtitle: 'Accede con tu cuenta de Google',
                onTap: () => context.go('/login'),
                showArrow: true,
              ),
              const SizedBox(height: 24),
            ],

            // Sección de Configuración
            _buildSectionTitle('Configuración'),
            const SizedBox(height: 12),
            
            // Modo Oscuro/Claro
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                return _buildThemeOption(themeState);
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildOptionTile(
              icon: Symbols.notifications,
              title: 'Notificaciones',
              subtitle: 'Configura tus notificaciones',
              onTap: () => context.push('/settings/notifications'),
              showArrow: true,
            ),
            
            const SizedBox(height: 12),
            
            _buildOptionTile(
              icon: Symbols.language,
              title: 'Idioma',
              subtitle: 'Español',
              onTap: () => context.push('/settings/language'),
              showArrow: true,
            ),
            
            // Opción de diagnóstico (solo en desarrollo)
            if (const bool.fromEnvironment('dart.vm.product') == false) ...[
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Symbols.bug_report,
                title: 'Diagnóstico',
                subtitle: 'Herramientas de depuración',
                onTap: () => _showDiagnosticDialog(),
                showArrow: true,
              ),
            ],

            // Sección de Usuario Autenticado
            if (authState is AuthAuthenticated) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Cuenta'),
              const SizedBox(height: 12),
              
              _buildOptionTile(
                icon: Symbols.edit,
                title: 'Editar Perfil',
                subtitle: 'Actualiza tu información personal',
                onTap: () => context.push('/settings/edit-profile'),
                showArrow: true,
              ),
              
              const SizedBox(height: 12),
              
              _buildOptionTile(
                icon: Symbols.security,
                title: 'Privacidad y Seguridad',
                subtitle: 'Gestiona la privacidad de tu cuenta',
                onTap: () => context.push('/settings/privacy'),
                showArrow: true,
              ),
              
              const SizedBox(height: 24),
              
              // Cerrar Sesión
              _buildOptionTile(
                icon: Symbols.logout,
                title: 'Cerrar Sesión',
                subtitle: 'Salir de tu cuenta',
                onTap: () => _showLogoutDialog(),
                showArrow: false,
                isDestructive: true,
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Información de la app
            _buildSectionTitle('Acerca de'),
            const SizedBox(height: 12),
            
            _buildOptionTile(
              icon: Symbols.info,
              title: 'Acerca de ${AppConstants.appName}',
              subtitle: 'Versión 1.0.0',
              onTap: () {
                _showAboutDialog();
              },
              showArrow: true,
            ),
            
            const SizedBox(height: 12),
            
            _buildOptionTile(
              icon: Symbols.description,
              title: 'Términos y Condiciones',
              subtitle: 'Lee nuestros términos de uso',
              onTap: () => context.push('/settings/terms'),
              showArrow: true,
            ),
            
            const SizedBox(height: 48),
          ],
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

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
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
              if (showArrow)
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

  Widget _buildThemeOption(ThemeState themeState) {
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
            themeState.isDark ? Symbols.dark_mode : Symbols.light_mode,
            size: 24,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo de Apariencia',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getThemeDescription(themeState),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'light':
                  context.read<ThemeBloc>().add(ThemeChanged(false));
                  break;
                case 'dark':
                  context.read<ThemeBloc>().add(ThemeChanged(true));
                  break;
                case 'system':
                  context.read<ThemeBloc>().add(ThemeSystemChanged());
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'light',
                child: Row(
                  children: [
                    Icon(Symbols.light_mode, size: 20),
                    SizedBox(width: 8),
                    Text('Claro'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dark',
                child: Row(
                  children: [
                    Icon(Symbols.dark_mode, size: 20),
                    SizedBox(width: 8),
                    Text('Oscuro'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'system',
                child: Row(
                  children: [
                    Icon(Symbols.brightness_auto, size: 20),
                    SizedBox(width: 8),
                    Text('Sistema'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getThemeButtonText(themeState),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Symbols.expand_more,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeDescription(ThemeState themeState) {
    if (themeState is ThemeLight) {
      return 'Interfaz clara activa';
    } else if (themeState is ThemeDark) {
      return 'Interfaz oscura activa';
    } else {
      return 'Sigue la configuración del sistema';
    }
  }

  String _getThemeButtonText(ThemeState themeState) {
    if (themeState is ThemeLight) {
      return 'Claro';
    } else if (themeState is ThemeDark) {
      return 'Oscuro';
    } else {
      return 'Sistema';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
        ),
        child: const Icon(
          Symbols.handyman,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Conectamos profesionales con personas que necesitan servicios de calidad.',
            style: GoogleFonts.inter(),
          ),
        ),
      ],
    );
  }

  void _showImagePicker(BuildContext context, String? currentPhotoUrl) {
    ImagePickerBottomSheet.show(
      context,
      onImageSelected: (imageFile) {
        context.read<ProfileBloc>().add(UpdateProfilePhoto(imageFile));
      },
      onRemoveImage: currentPhotoUrl != null && currentPhotoUrl.isNotEmpty
          ? () {
              context.read<ProfileBloc>().add(RemoveProfilePhoto());
            }
          : null,
      hasCurrentImage: currentPhotoUrl != null && currentPhotoUrl.isNotEmpty,
    );
  }

  void _showDiagnosticDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Symbols.bug_report, size: 24),
            const SizedBox(width: 8),
            Text(
              'Herramientas de Diagnóstico',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estas herramientas pueden ayudar a solucionar problemas:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Botón de limpieza completa
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _performCompleteCleanup(),
                icon: const Icon(Symbols.delete_sweep),
                label: Text(
                  'Limpieza Completa',
                  style: GoogleFonts.inter(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botón de diagnóstico de auth
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _performAuthDiagnosis(),
                icon: const Icon(Symbols.search),
                label: Text(
                  'Diagnóstico de Auth',
                  style: GoogleFonts.inter(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCompleteCleanup() async {
    Navigator.of(context).pop(); // Cerrar diálogo
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Realizando limpieza completa...'),
          ],
        ),
      ),
    );
    
    try {
      // Enviar evento de limpieza completa al AuthBloc
      context.read<AuthBloc>().add(AuthSignOutRequested());
      
      // Esperar un momento para que se procese
      await Future.delayed(const Duration(seconds: 1));
      
      // Cerrar diálogo de carga
      Navigator.of(context).pop();
      
      // Mostrar resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Limpieza completa realizada. Reinicia la app si es necesario.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga
      Navigator.of(context).pop();
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error en limpieza: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performAuthDiagnosis() {
    Navigator.of(context).pop(); // Cerrar diálogo
    
    // Mostrar información básica del estado actual
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    
    String diagnosisMessage;
    if (authState is AuthAuthenticated) {
      diagnosisMessage = '👤 Usuario autenticado: ${authState.user.email}';
    } else if (authState is AuthUnauthenticated) {
      diagnosisMessage = '📱 Usuario no autenticado (estado correcto para navegación pública)';
    } else if (authState is AuthLoading) {
      diagnosisMessage = '⏳ Cargando estado de autenticación...';
    } else if (authState is AuthError) {
      diagnosisMessage = '❌ Error de autenticación: ${authState.message}';
    } else {
      diagnosisMessage = '🔍 Estado desconocido: ${authState.runtimeType}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          diagnosisMessage,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}