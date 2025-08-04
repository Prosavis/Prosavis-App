import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';

import '../../widgets/common/service_card.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
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
        child: CustomScrollView(
          slivers: [
            _buildAppBar(state),
            _buildSearchBar(),
            _buildCategoriesSection(),
            _buildFeaturedServicesSection(),
            _buildNearbyServicesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContentAnonymous() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildAppBarAnonymous(),
            _buildSearchBar(),
            _buildCategoriesSection(),
            _buildFeaturedServicesSection(),
            _buildNearbyServicesSection(),
          ],
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '¿Qué servicio necesitas hoy?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '¿Qué servicio necesitas hoy?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Notifications - Protegido para usuarios anónimos
            IconButton(
              onPressed: () {
                _showAuthRequiredDialog('las notificaciones');
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Symbols.search, color: AppTheme.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buscar servicios...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => FiltersBottomSheet(
                        onFiltersApplied: (filters) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Filtros aplicados')),
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Symbols.tune, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorías',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Grid de categorías 4x2
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85, // Proporción de aspecto para las tarjetas
              ),
              itemCount: AppConstants.serviceCategories.length,
              itemBuilder: (context, index) {
                final category = AppConstants.serviceCategories[index];
                return _buildCategoryGridItem(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridItem(Map<String, dynamic> category) {
    return GestureDetector(
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getCategoryColor(category['name']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'],
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'limpieza':
        return const Color(0xFF10B981);
      case 'belleza y bienestar':
        return const Color(0xFFDB2777);
      case 'plomería':
        return const Color(0xFF3B82F6);
      case 'electricidad':
        return const Color(0xFFF59E0B);
      case 'pintura':
        return const Color(0xFFDC2626);
      case 'carpintería':
        return const Color(0xFF92400E);
      case 'jardinería':
        return const Color(0xFF059669);
      case 'mecánica':
        return const Color(0xFF374151);
      default:
        return AppTheme.primaryColor;
    }
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
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
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
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        );
      }

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        itemCount: state.featuredServices.length,
        itemBuilder: (context, index) {
          final service = state.featuredServices[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ServiceCard(
              title: service.title,
              provider: service.providerName,
              price: service.price,
              rating: service.rating,
              imageUrl: service.images.isNotEmpty ? service.images.first : null,
              onTap: () {
                final serviceItem = ServiceItem(
                  id: service.id,
                  title: service.title,
                  provider: service.providerName,
                  price: service.price,
                  rating: service.rating,
                  category: service.category,
                  description: service.description,
                  isAvailable: service.isActive,
                  distance: 2.5, // Por defecto, puede ser calculado en el futuro
                  imageUrl: service.images.isNotEmpty ? service.images.first : null,
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsPage(service: serviceItem),
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
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
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
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        );
      }

      return Column(
        children: state.nearbyServices.map((service) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ServiceCard(
              title: service.title,
              provider: service.providerName,
              price: service.price,
              rating: service.rating,
              imageUrl: service.images.isNotEmpty ? service.images.first : null,
              isHorizontal: true,
              onTap: () {
                final serviceItem = ServiceItem(
                  id: service.id,
                  title: service.title,
                  provider: service.providerName,
                  price: service.price,
                  rating: service.rating,
                  category: service.category,
                  description: service.description,
                  isAvailable: service.isActive,
                  distance: 0.5, // Por defecto, puede ser calculado en el futuro
                  imageUrl: service.images.isNotEmpty ? service.images.first : null,
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsPage(service: serviceItem),
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