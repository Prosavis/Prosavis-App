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
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';

import '../../widgets/common/service_card.dart';

import '../../widgets/dialogs/location_permission_dialog.dart';
import '../../widgets/dialogs/welcome_dialog.dart';
import '../../widgets/common/press_scale.dart';
import '../services/category_services_page.dart';
import '../services/service_details_page.dart';
import 'package:animations/animations.dart';


class HomePage extends StatefulWidget {
  final VoidCallback? onProfileTapped;
  final VoidCallback? onOfferServiceTapped;
  
  const HomePage({
    super.key, 
    this.onProfileTapped,
    this.onOfferServiceTapped,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _locationHighlightController;
  late Animation<double> _locationHighlightAnimation;
  
  bool _hasShownWelcomeDialog = false;
  
  final TextEditingController _searchController = TextEditingController();

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

    // Animación sutil para destacar la ubicación detectada
    _locationHighlightController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    
    _locationHighlightAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _locationHighlightController,
        curve: Curves.easeOutCubic,
      ),
    );


    _fadeController.forward();
    
    // Cargar servicios al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(LoadHomeServices());
      
      // Auto-detectar ubicación usando LocationBloc centralizado
      context.read<LocationBloc>().add(DetectLocationEvent());
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _locationHighlightController.dispose();
    _searchController.dispose();
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



  /// Muestra la animación de highlight para la ubicación detectada
  void _showLocationHighlight() {
    developer.log('✅ Ubicación GPS detectada y guardada en cache para cálculos de distancia', name: 'HomePage');

    // Ejecutar animación sutil para llamar la atención sobre la ubicación detectada
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        developer.log('🎯 Ejecutando animación de atención para ubicación detectada', name: 'HomePage');
        _locationHighlightController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _locationHighlightController.reverse();
            }
          });
        });
      }
    });
  }



  /// Muestra el dialog de configuración de ubicación
  void _showLocationDialog() async {
    final result = await LocationPermissionDialog.show(context);
    if (result == true && mounted) {
      // Si se configuró la ubicación correctamente, refrescar usando LocationBloc
      context.read<LocationBloc>().add(RefreshLocationEvent());
    }
  }

  /// Muestra el pop-up de bienvenida después del inicio de sesión exitoso
  void _showWelcomeDialog() {
    if (!mounted) return;
    
    WelcomeDialog.show(
      context,
      onOfferServiceTapped: () {
        // Navegar a la sección de "Ofrecer" servicios
        widget.onOfferServiceTapped?.call();
      },
      onClose: () {
        // El dialog ya se cierra automáticamente
        developer.log('🎉 Pop-up de bienvenida cerrado', name: 'HomePage');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Cuando el usuario inicia sesión, detectar ubicación si aún no está disponible
            if (state is AuthAuthenticated) {
              final locationBloc = context.read<LocationBloc>();
              if (!locationBloc.hasLocation) {
                developer.log('🔐 Usuario autenticado - Iniciando detección GPS', name: 'HomePage');
                locationBloc.add(DetectLocationEvent());
              }
              
              // Mostrar pop-up de bienvenida si es un login reciente
              if (state.isRecentLogin && !_hasShownWelcomeDialog) {
                _hasShownWelcomeDialog = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showWelcomeDialog();
                });
              }
            }
          },
        ),
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            // Cuando se detecta ubicación exitosamente, mostrar animación de highlight
            if (state is LocationLoaded) {
              _showLocationHighlight();
              // Recargar servicios cercanos con la nueva ubicación
              context.read<HomeBloc>().add(RefreshHomeServices());
            }
          },
        ),
      ],
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
            
            // Welcome + ubicación activa usando LocationBloc
            Expanded(
              child: AnimatedBuilder(
                animation: _locationHighlightAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _locationHighlightAnimation.value,
                    child: GestureDetector(
                      onTap: () {
                        _showLocationDialog();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${state.user.name.split(' ').first}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, locationState) {
                              return Row(
                                children: [
                                  Icon(
                                    locationState is LocationLoading
                                        ? Symbols.my_location
                                        : locationState is LocationLoaded
                                            ? Symbols.location_on
                                            : Symbols.location_off,
                                    size: 16,
                                    color: locationState is LocationLoading
                                        ? AppTheme.accentColor
                                        : AppTheme.getTextSecondary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationState is LocationLoading
                                          ? 'Detectando ubicación por GPS...'
                                          : locationState is LocationLoaded
                                              ? LocationUtils.normalizeAddress(locationState.address)
                                              : 'Toca para agregar ubicación',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontStyle: locationState is LocationLoading ? FontStyle.italic : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
            
            // Support
            IconButton(
              onPressed: () {
                context.push('/support');
              },
              icon: const Icon(
                Symbols.support_agent,
                color: AppTheme.accentColor,
                size: 28,
              ),
              tooltip: 'Soporte',
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
              child: const Hero(
                tag: 'header-avatar-anon',
                child: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(
                  Symbols.person,
                  color: Colors.white,
                  size: 28,
                ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Welcome Message for anonymous user + Ubicación GPS usando LocationBloc
            Expanded(
              child: AnimatedBuilder(
                animation: _locationHighlightAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _locationHighlightAnimation.value,
                    child: GestureDetector(
                      onTap: () {
                        _showLocationDialog();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, locationState) {
                              return Row(
                                children: [
                                  Icon(
                                    locationState is LocationLoading
                                        ? Symbols.my_location
                                        : locationState is LocationLoaded
                                            ? Symbols.location_on
                                            : Symbols.location_off,
                                    size: 16,
                                    color: locationState is LocationLoading
                                        ? AppTheme.accentColor
                                        : AppTheme.getTextSecondary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationState is LocationLoading
                                          ? 'Detectando ubicación por GPS...'
                                          : locationState is LocationLoaded
                                              ? LocationUtils.normalizeAddress(locationState.address)
                                              : 'Inicia sesión para gestionar direcciones',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
            
            // Support - Disponible para usuarios anónimos
            IconButton(
              onPressed: () {
                context.push('/support');
              },
              icon: const Icon(
                Symbols.support_agent,
                color: AppTheme.accentColor,
                size: 28,
              ),
              tooltip: 'Soporte',
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
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Categorías',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
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
            childAspectRatio: 0.68, // Mantener proporción; iconos aumentados
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = AppConstants.serviceCategories[index];
              return _buildCategoryGridItem(category, index: index);
            },
            childCount: AppConstants.serviceCategories.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildCategoryGridItem(Map<String, dynamic> category, {required int index}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1.0),
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: OpenContainer(
        transitionDuration: AppConstants.mediumAnimation,
        transitionType: ContainerTransitionType.fadeThrough,
        closedElevation: 0,
        closedColor: Colors.transparent,
        openBuilder: (context, _) => CategoryServicesPage(category: category),
        closedBuilder: (context, openContainer) {
          return PressScale(
            onPressed: openContainer,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BreathingScale(
                    delayMs: index * 120,
                    minScale: 1.0,
                    maxScale: 1.04,
                    duration: const Duration(milliseconds: 2600),
                    child: Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentColor.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Hero(
                        tag: "category-${category['name']}-icon",
                        child: _buildCategoryIconFromAsset(category, size: 64),
                      ),
                    ),
                  ),
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
          );
        },
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Servicios Destacados',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      if (state is HomeLoading)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
            child: OpenContainer(
              transitionDuration: AppConstants.mediumAnimation,
              transitionType: ContainerTransitionType.fadeThrough,
              closedElevation: 0,
              closedColor: Colors.transparent,
              openBuilder: (context, _) => ServiceDetailsPage(service: service),
              closedBuilder: (context, openContainer) => ServiceCard(
                service: service,
                onTap: openContainer,
                enableHero: false,
              ),
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
                    gradient: AppTheme.welcomeGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Cerca de ti',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
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
            child: OpenContainer(
              transitionDuration: AppConstants.mediumAnimation,
              transitionType: ContainerTransitionType.fadeThrough,
              closedElevation: 0,
              closedColor: Colors.transparent,
              openBuilder: (context, _) => ServiceDetailsPage(service: service),
              closedBuilder: (context, openContainer) => ServiceCard(
                service: service,
                isHorizontal: true,
                onTap: openContainer,
                enableHero: false,
              ),
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }


} 

class _BreathingScale extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const _BreathingScale({
    required this.child,
    this.delayMs = 0,
    this.minScale = 1.0,
    this.maxScale = 1.03,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<_BreathingScale> createState() => _BreathingScaleState();
}

class _BreathingScaleState extends State<_BreathingScale> {
  bool _grow = true;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() {
          _started = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 1.0,
        end: _started ? (_grow ? widget.maxScale : widget.minScale) : 1.0,
      ),
      duration: widget.duration,
      curve: Curves.easeInOut,
      onEnd: () {
        if (!mounted || !_started) return;
        setState(() {
          _grow = !_grow;
        });
      },
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}