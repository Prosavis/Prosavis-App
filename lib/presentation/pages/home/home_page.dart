import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/config/performance_config.dart';
import '../../../core/utils/location_utils.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';

import '../../widgets/common/service_card.dart';
import '../../widgets/common/auth_required_dialog.dart';
import '../services/category_services_page.dart';
import '../services/service_details_page.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_state.dart';
import '../../blocs/address/address_event.dart';
import '../../../domain/entities/saved_address_entity.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onProfileTapped;
  
  const HomePage({super.key, this.onProfileTapped});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _locationHighlightController;
  late Animation<double> _locationHighlightAnimation;
  late Animation<Color?> _locationColorAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  
  String? _currentGpsAddress;
  bool _isDetectingLocation = false;
  bool _hasDetectedGPS = false; // Flag para evitar múltiples detecciones
  bool _showGpsBadge = false; // Flag para mostrar/ocultar badge GPS temporal
  Timer? _gpsBadgeTimer; // Timer para ocultar badge después de 5 segundos

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

    // Animación para destacar la ubicación (rápida - 1 segundo total)
    _locationHighlightController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _locationHighlightAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _locationHighlightController,
        curve: Curves.elasticOut,
      ),
    );
    
    _locationColorAnimation = ColorTween(
      begin: AppTheme.accentColor,
      end: AppTheme.primaryColor,
    ).animate(CurvedAnimation(
      parent: _locationHighlightController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    
    // Cargar servicios al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(LoadHomeServices());
      
      // SIEMPRE auto-detectar ubicación GPS al inicio (independiente de autenticación)
      _autoDetectLocation();
      
      // Precargar direcciones solo si el usuario está autenticado
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<AddressBloc>().add(LoadAddresses(authState.user.id));
          // conectar HomeBloc con AddressBloc para usar coordenadas activas
          context.read<HomeBloc>().addressBloc = context.read<AddressBloc>();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _locationHighlightController.dispose();
    _searchController.dispose();
    _gpsBadgeTimer?.cancel(); // Cancelar timer si existe
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

  /// Auto-detecta la ubicación GPS al iniciar la aplicación (solo una vez)
  Future<void> _autoDetectLocation() async {
    developer.log('🔍 Iniciando auto-detección de ubicación GPS...', name: 'HomePage');
    
    if (!mounted || _hasDetectedGPS) {
      developer.log('❌ Widget no montado o GPS ya detectado, cancelando detección', name: 'HomePage');
      return;
    }
    
    setState(() {
      _isDetectingLocation = true;
      _hasDetectedGPS = true; // Marcar como detectado para evitar repeticiones
    });

    try {
      developer.log('📍 Obteniendo ubicación GPS...', name: 'HomePage');
      // Obtener ubicación GPS con detalles completos
      final locationDetails = await LocationUtils.getCurrentLocationDetails();
      
      if (!mounted) {
        developer.log('❌ Widget no montado después de obtener ubicación', name: 'HomePage');
        return;
      }
      
      if (locationDetails != null && locationDetails['address'] != null) {
        developer.log('✅ Ubicación GPS obtenida: ${locationDetails['address']}', name: 'HomePage');
        
        setState(() {
          _currentGpsAddress = locationDetails['address'] as String;
          _isDetectingLocation = false;
          _showGpsBadge = true; // Mostrar badge GPS temporal
        });

        // Timer para ocultar badge después de 5 segundos
        _gpsBadgeTimer?.cancel(); // Cancelar timer anterior si existe
        _gpsBadgeTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showGpsBadge = false;
            });
          }
        });

        // Crear entidad de dirección temporal basada en GPS
        final gpsAddress = SavedAddressEntity(
          id: 'gps_current',
          userId: '',
          label: 'Ubicación Actual (GPS)',
          addressLine: _currentGpsAddress!,
          latitude: (locationDetails['latitude'] as num).toDouble(),
          longitude: (locationDetails['longitude'] as num).toDouble(),
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Establecer como dirección activa temporal
        try {
          final authState = context.read<AuthBloc>().state;
          if (mounted) {
            developer.log('🔄 Estableciendo dirección GPS como activa...', name: 'HomePage');
            // SIEMPRE establecer dirección GPS localmente (temporal)
            context.read<AddressBloc>().add(SetActiveAddressLocal(gpsAddress));
            
            // Solo sincronizar con BD si está autenticado
            if (authState is AuthAuthenticated) {
              developer.log('🔐 Usuario autenticado - Sincronizando con base de datos', name: 'HomePage');
              context.read<AddressBloc>().add(SyncActiveAddressToProfile(authState.user.id, gpsAddress));
              developer.log('✅ Dirección GPS establecida y sincronizada', name: 'HomePage');
            } else {
              developer.log('👤 Usuario no autenticado - Usando dirección temporal', name: 'HomePage');
              developer.log('✅ Dirección GPS establecida temporalmente', name: 'HomePage');
            }
          }
        } catch (e) {
          developer.log('❌ Error estableciendo dirección GPS: $e', name: 'HomePage');
        }

        // Ejecutar animación rápida para llamar la atención (1 segundo total)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            developer.log('🎯 Ejecutando animación de atención', name: 'HomePage');
            _locationHighlightController.forward().then((_) {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) {
                  _locationHighlightController.reverse();
                }
              });
            });
          }
        });
      } else {
        developer.log('❌ No se pudo obtener dirección GPS', name: 'HomePage');
        setState(() {
          _isDetectingLocation = false;
        });
      }
    } catch (e) {
      developer.log('❌ Error en auto-detección GPS: $e', name: 'HomePage');
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  /// Muestra diálogo de autenticación requerida
  void _showAuthRequiredDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AuthRequiredDialog(
        title: 'Inicia Sesión',
        message: 'Para acceder a $featureName necesitas iniciar sesión en tu cuenta.',
        onLoginTapped: () {
          widget.onProfileTapped?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Cuando el usuario inicia sesión, auto-detectar ubicación si no se ha hecho
        if (state is AuthAuthenticated && !_hasDetectedGPS) {
          developer.log('🔐 Usuario autenticado - Iniciando auto-detección GPS', name: 'HomePage');
          _autoDetectLocation();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildHomeContent(state);
          } else {
            // Mostrar home sin autenticación (usuario anónimo)
            return _buildHomeContentAnonymous();
          }
        },
      ),
    );
  }

  Widget _buildHomeContent(AuthAuthenticated state) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(RefreshHomeServices());
            // También refrescar direcciones si el AddressBloc está presente
            try {
              context.read<AddressBloc>();
              // ignorar si no existe provider
            } catch (_) {}
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(state),
              _buildSearchBar(),
              ..._buildCategoriesSection(),
              _buildFeaturedServicesSection(),
              _buildNearbyServicesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContentAnonymous() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(RefreshHomeServices());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBarAnonymous(),
              _buildSearchBar(),
              ..._buildCategoriesSection(),
              _buildFeaturedServicesSection(),
              _buildNearbyServicesSection(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildAppBar(AuthAuthenticated state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // User Avatar - Clickeable para ir al perfil
            GestureDetector(
              onTap: () {
                widget.onProfileTapped?.call();
              },
              child: CircleAvatar(
                radius: 24,
                backgroundImage: _getImageProvider(state.user.photoUrl),
                backgroundColor: AppTheme.primaryColor,
                child: state.user.photoUrl == null
                    ? const Icon(
                        Symbols.person,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Welcome + ubicación activa
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/addresses', extra: {'userId': state.user.id}),
                child: AnimatedBuilder(
                  animation: _locationHighlightAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _locationHighlightAnimation.value,
                      child: BlocBuilder<AddressBloc, AddressState>(
                        builder: (context, addrState) {
                          String subtitle = 'Toca para agregar ubicación';
                          String? locationIndicator;
                          bool isGpsLocation = false;
                          
                          if (_isDetectingLocation) {
                          subtitle = 'Detectando ubicación GPS...';
                          locationIndicator = '🔍 GPS';
                          isGpsLocation = true;
                        } else if (addrState is AddressLoaded && addrState.active != null) {
                          final active = addrState.active!;
                          isGpsLocation = active.id == 'gps_current';
                          
                          if (isGpsLocation) {
                            subtitle = active.addressLine;
                            locationIndicator = _showGpsBadge ? '📍 GPS Actual' : null;
                          } else {
                            subtitle = active.label.isNotEmpty
                                ? '${active.label} · ${active.addressLine}'
                                : active.addressLine;
                            locationIndicator = '💾 Guardada';
                          }
                        } else if (_currentGpsAddress != null) {
                          subtitle = _currentGpsAddress!;
                          locationIndicator = _showGpsBadge ? '📍 GPS Actual' : null;
                          isGpsLocation = true;
                        } else {
                          subtitle = 'Toca para agregar ubicación';
                        }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, ${state.user.name.split(' ').first}!',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _locationColorAnimation,
                                    builder: (context, child) {
                                      return Icon(
                                        _isDetectingLocation 
                                          ? Symbols.my_location 
                                          : (isGpsLocation ? Symbols.gps_fixed : Symbols.location_on), 
                                        size: 16, 
                                        color: _locationColorAnimation.value ?? AppTheme.accentColor,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  if (locationIndicator != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isGpsLocation ? Colors.green.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isGpsLocation ? Colors.green.withValues(alpha: 0.5) : AppTheme.primaryColor.withValues(alpha: 0.5),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        locationIndicator,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isGpsLocation ? Colors.green[700] : AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontStyle: _isDetectingLocation ? FontStyle.italic : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Notifications
            IconButton(
              onPressed: () {
                context.push('/notifications');
              },
              icon: const Icon(
                Symbols.notifications,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarAnonymous() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // User Avatar for anonymous user - Clickeable para ir al perfil
            GestureDetector(
              onTap: () {
                widget.onProfileTapped?.call();
              },
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(
                  Symbols.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Welcome Message for anonymous user + Ubicación GPS temporal
            Expanded(
              child: AnimatedBuilder(
                animation: _locationHighlightAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _locationHighlightAnimation.value,
                    child: GestureDetector(
                      onTap: () {
                        _showAuthRequiredDialog('gestionar direcciones');
                      },
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    BlocBuilder<AddressBloc, AddressState>(
                      builder: (context, addrState) {
                        String subtitle = 'Toca para agregar ubicación';
                        String? locationIndicator;
                        bool isGpsLocation = false;
                        
                        if (_isDetectingLocation) {
                          subtitle = 'Detectando ubicación GPS...';
                          locationIndicator = '🔍 GPS';
                          isGpsLocation = true;
                        } else if (addrState is AddressLoaded && addrState.active != null) {
                          final active = addrState.active!;
                          isGpsLocation = active.id == 'gps_current';
                          
                          if (isGpsLocation) {
                            subtitle = active.addressLine;
                            locationIndicator = _showGpsBadge ? '📍 GPS Temporal' : null;
                          } else {
                            subtitle = active.label.isNotEmpty
                                ? '${active.label} · ${active.addressLine}'
                                : active.addressLine;
                            locationIndicator = '💾 Guardada';
                          }
                        } else if (_currentGpsAddress != null) {
                          subtitle = _currentGpsAddress!;
                          locationIndicator = _showGpsBadge ? '📍 GPS Temporal' : null;
                          isGpsLocation = true;
                        } else {
                          subtitle = 'Inicia sesión para gestionar direcciones';
                        }
                        
                        return Row(
                          children: [
                            AnimatedBuilder(
                              animation: _locationColorAnimation,
                              builder: (context, child) {
                                return Icon(
                                  isGpsLocation ? Symbols.gps_fixed : Symbols.location_on,
                                  size: 16,
                                  color: isGpsLocation 
                                    ? _locationColorAnimation.value ?? AppTheme.accentColor
                                    : AppTheme.accentColor,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (locationIndicator != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isGpsLocation 
                                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isGpsLocation 
                                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                      : Colors.green.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  locationIndicator,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isGpsLocation 
                                      ? AppTheme.primaryColor
                                      : Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
                      ),
                    );
                },
              ),
            ),
            
            // Notifications - Protegido para usuarios anónimos
            IconButton(
              onPressed: () {
                _showAuthRequiredDialog('las notificaciones');
              },
              icon: Icon(
                Symbols.notifications,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        child: GestureDetector(
          onTap: () {
            // Navegar a la página de búsqueda independiente
            context.push('/search');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.secondaryColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                Icon(Symbols.search, color: AppTheme.getTextSecondary(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buscar servicios...'
                    ,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  List<Widget> _buildCategoriesSection() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.welcomeGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Categorías',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.only(
          left: AppConstants.paddingMedium,
          right: AppConstants.paddingMedium,
          bottom: AppConstants.paddingMedium,
        ),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68, // Más alto para acomodar iconos de 56px
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = AppConstants.serviceCategories[index];
              return _buildCategoryGridItem(category);
            },
            childCount: AppConstants.serviceCategories.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildCategoryGridItem(Map<String, dynamic> category) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1.0),
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryServicesPage(category: category),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryIconFromAsset(category, size: 56),
              const SizedBox(height: 8),
              Text(
                category['name'],
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIconFromAsset(Map<String, dynamic> category, {double size = 32}) {
    final String? asset = category['asset'] as String?;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        height: size,
        width: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          category['icon'],
          color: _getCategoryColor(category['name']),
          size: size,
        ),
      );
    }
    return Icon(
      category['icon'],
      color: _getCategoryColor(category['name']),
      size: size,
    );
  }
 
  Color _getCategoryColor(String categoryName) {
    // Si en el futuro queremos reintroducir colores por categoría, aquí es el punto.
    // Por ahora, usamos un color de énfasis consistente para simplificar diseño.
    return AppTheme.primaryColor;
  }

  Widget _buildFeaturedServicesSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(
                  left: AppConstants.paddingMedium,
                  right: AppConstants.paddingMedium,
                  top: AppConstants.paddingMedium,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.secondaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Servicios Destacados',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    if (state is HomeLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: ServiceCard.preferredVerticalListHeight(context),
                child: _buildFeaturedServicesList(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedServicesList(HomeState state) {
    if (state is HomeLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is HomeError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.error,
              color: AppTheme.errorColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Error al cargar servicios',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                context.read<HomeBloc>().add(RefreshHomeServices());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is HomeLoaded) {
      if (state.featuredServices.isEmpty) {
        return Center(
          child: Text(
            'No hay servicios disponibles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        cacheExtent: PerformanceConfig.optimizedCacheExtent,
        itemCount: state.featuredServices.length,
        itemBuilder: (context, index) {
          final service = state.featuredServices[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ServiceCard(
              service: service,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsPage(service: service),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNearbyServicesSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Cerca de ti',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNearbyServicesList(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearbyServicesList(HomeState state) {
    if (state is HomeLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is HomeError) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Symbols.error,
              color: AppTheme.errorColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Error al cargar servicios cercanos',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                context.read<HomeBloc>().add(RefreshHomeServices());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is HomeLoaded) {
      if (state.nearbyServices.isEmpty) {
        return Center(
          child: Text(
            'No hay servicios cercanos disponibles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return Column(
        children: state.nearbyServices.map((service) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ServiceCard(
              service: service,
              isHorizontal: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsPage(service: service),
                  ),
                );
              },
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }


} 