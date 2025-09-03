import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/config/performance_config.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';

import '../../widgets/common/service_card.dart';
import '../../widgets/common/help_button_widget.dart';
import '../../widgets/common/limited_address_widget.dart';

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

class SectionCard extends StatelessWidget {
  final String title;
  final Gradient gradient;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Widget? headerTrailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.gradient,
    required this.child,
    this.padding,
    this.headerTrailing,
  });

  /// Crea gradientes sutiles según el título de la sección y el tema actual
  Gradient _createSoftGradient(Gradient originalGradient, BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Usar gradientes predefinidos según el tema
    switch (title.toLowerCase()) {
      case 'categorías':
        return isDarkMode 
            ? AppTokens.categoriesGradientDark 
            : AppTokens.categoriesGradient;
        
      case 'servicios destacados':
        return isDarkMode 
            ? AppTokens.featuredGradientDark 
            : AppTokens.featuredGradient;
        
      case 'cerca de ti':
        return isDarkMode 
            ? AppTokens.nearbyGradientDark 
            : AppTokens.nearbyGradient;
        
      default:
        // Fallback según el tema
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode ? [
            const Color(0xFF1F2937), // Superficie elevada oscura
            const Color(0xFF111827), // Fondo oscuro
          ] : [
            const Color(0xFFFAFBFC), // Superficie elevada clara
            AppTokens.surface,        // Blanco puro
          ],
          stops: const [0.0, 1.0],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: _createSoftGradient(gradient, context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade700
              : AppTokens.outline
        ),
        boxShadow: [
          AppTokens.cardShadow,
        ],
      ),
      child: Column(
        children: [
          // Header integrado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white
                        : AppTokens.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: 8),
                  headerTrailing!,
                ],
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(
              AppConstants.paddingMedium, 
              0, 
              AppConstants.paddingMedium, 
              AppConstants.paddingMedium
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  

  
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
        developer.log('🎯 Ubicación detectada correctamente', name: 'HomePage');
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
        padding: const EdgeInsets.only(
          left: AppConstants.paddingMedium,
          right: AppConstants.paddingMedium,
          top: AppConstants.paddingMedium,
          bottom: 8, // Reducido el padding inferior para acercar a la barra de búsqueda
        ),
        child: Stack(
          children: [
            // Contenido principal: Avatar + Saludo + Dirección
            Row(
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
                
                // Welcome message + ubicación minimalista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Hola, ${state.user.name.split(' ').first}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      // Dirección limitada con scroll automático
                      LimitedAddressWidget(
                        maxWidth: MediaQuery.of(context).size.width - 
                                  AppConstants.paddingMedium * 2 - // Padding del container
                                  48 - // Avatar (radius 24 * 2)
                                  12 - // Espacio entre avatar y texto
                                  100 - // Espacio reservado para el botón de ayuda
                                  20,   // Margen de seguridad
                        onTap: () {
                          _showLocationDialog();
                        },
                        anonymousText: 'Toca para agregar ubicación',
                      ),
                    ],
                  ),
                ),
                
                // Espacio para el botón que estará positioned
                const SizedBox(width: 80),
              ],
            ),
            
            // Botón de ayuda en la esquina superior derecha
            Positioned(
              top: 0,
              right: 0,
              child: HelpButtonWidget(
                onTap: () {
                  context.push('/support');
                },
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
        padding: const EdgeInsets.only(
          left: AppConstants.paddingMedium,
          right: AppConstants.paddingMedium,
          top: AppConstants.paddingMedium,
          bottom: 8, // Reducido el padding inferior para acercar a la barra de búsqueda
        ),
        child: Stack(
          children: [
            // Contenido principal: Avatar + Saludo + Dirección
            Row(
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
                
                // Welcome message + ubicación minimalista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Hola!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      // Dirección limitada con scroll automático
                      LimitedAddressWidget(
                        maxWidth: MediaQuery.of(context).size.width - 
                                  AppConstants.paddingMedium * 2 - // Padding del container
                                  48 - // Avatar (radius 24 * 2)
                                  12 - // Espacio entre avatar y texto
                                  100 - // Espacio reservado para el botón de ayuda
                                  20,   // Margen de seguridad
                        onTap: () {
                          _showLocationDialog();
                        },
                        anonymousText: 'Inicia sesión para gestionar direcciones',
                      ),
                    ],
                  ),
                ),
                
                // Espacio para el botón que estará positioned
                const SizedBox(width: 80),
              ],
            ),
            
            // Botón de ayuda en la esquina superior derecha
            Positioned(
              top: 0,
              right: 0,
              child: HelpButtonWidget(
                onTap: () {
                  context.push('/support');
                },
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
        padding: const EdgeInsets.only(
          left: AppConstants.paddingMedium,
          right: AppConstants.paddingMedium,
          top: 8, // Reducido significativamente el espacio superior
          bottom: AppConstants.paddingMedium,
        ),
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
          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
          child: SectionCard(
            title: 'Categorías',
            gradient: AppTheme.primaryGradient,
            padding: EdgeInsets.zero,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: AppConstants.serviceCategories.length,
              itemBuilder: (context, index) {
                final category = AppConstants.serviceCategories[index];
                return _buildCategoryGridItem(category, index: index);
              },
            ),
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
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    flex: 3,
                    child: Hero(
                      tag: "category-${category['name']}-icon",
                      child: _buildCategoryIconFromAsset(category, size: 75, context: context, delayMs: index * 120),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    flex: 1,
                    child: Text(
                      category['name'],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white
                            : AppTokens.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryIconFromAsset(Map<String, dynamic> category, {double size = 32, required BuildContext context, int delayMs = 0}) {
    final String? asset = category['asset'] as String?;
    final categoryName = category['name'] as String? ?? '';
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Widget iconWidget;
    if (asset != null && asset.isNotEmpty) {
      iconWidget = Image.asset(
        asset,
        height: size * 0.75, // Aumentar el tamaño del ícono para que se vea más grande
        width: size * 0.75,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          category['icon'],
          color: AppTokens.getCategoryIconColor(categoryName, isDarkMode: isDarkMode),
          size: size * 0.75,
        ),
      );
    } else {
      iconWidget = Icon(
        category['icon'],
        color: AppTokens.getCategoryIconColor(categoryName, isDarkMode: isDarkMode),
        size: size * 0.75,
      );
    }
    
    // Contenedor blanco redondeado para hacer resaltar el ícono
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _BreathingScale(
          delayMs: delayMs,
          minScale: 1.0,
          maxScale: 1.15,
          duration: const Duration(milliseconds: 2600),
          child: iconWidget,
        ),
      ),
    );
  }

  Widget _buildFeaturedServicesSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
            child: SectionCard(
              title: 'Servicios Destacados',
              gradient: AppTheme.secondaryGradient,
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingMedium, // lateral izquierdo
                0, // superior (sin padding)
                AppConstants.paddingMedium, // lateral derecho
                30, // inferior aumentado para dar más espacio a las tarjetas
              ),
              headerTrailing: null,
              child: SizedBox(
                height: ServiceCard.preferredVerticalListHeight(context),
                child: _buildFeaturedServicesList(state),
              ),
            ),
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
                transparentBackground: true,
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
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMedium,
              horizontal: 0,
            ),
            child: SectionCard(
              title: 'Cerca de ti',
              gradient: AppTheme.welcomeGradient,
              child: _buildNearbyServicesList(state),
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
                transparentBackground: true,
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