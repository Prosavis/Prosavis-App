import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/config/performance_config.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';

import '../../widgets/common/service_card.dart';
import '../../widgets/common/auth_required_dialog.dart';
import '../services/category_services_page.dart';
import '../services/service_details_page.dart';

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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return _buildHomeContent(state);
        } else {
          // Mostrar home sin autenticación (usuario anónimo)
          return _buildHomeContentAnonymous();
        }
      },
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
            
            // Welcome Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${state.user.name.split(' ').first}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '¿Qué servicio necesitas hoy?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
            
            // Welcome Message for anonymous user
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '¿Qué servicio necesitas hoy?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
            child: Row(
              children: [
                Icon(Symbols.search, color: AppTheme.getTextTertiary(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buscar servicios...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.getTextTertiary(context)),
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
              Text(
                'Categorías',
                style: Theme.of(context).textTheme.headlineMedium,
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
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Servicios Destacados',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (state is HomeLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
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
                Text(
                  'Cerca de ti',
                  style: Theme.of(context).textTheme.headlineMedium,
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