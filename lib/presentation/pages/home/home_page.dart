import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/service_card.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
import '../services/category_services_page.dart';
import '../services/service_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
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
            _buildRecentSearches(),
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
            _buildRecentSearches(),
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
            // User Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: state.user.photoUrl != null
                  ? NetworkImage(state.user.photoUrl!)
                  : null,
              backgroundColor: AppTheme.primaryColor,
              child: state.user.photoUrl == null
                  ? Text(
                      state.user.name.isNotEmpty 
                          ? state.user.name[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
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
            // User Avatar for anonymous user
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                'U',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar servicios...',
            prefixIcon: const Icon(Symbols.search),
            suffixIcon: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FiltersBottomSheet(
                    onFiltersApplied: (filters) {
                      // Handle filters applied
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filtros aplicados')),
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Symbols.tune),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    // Mock data para búsquedas recientes
    final List<String> recentSearches = ['Limpieza', 'Plomería urgente', 'Belleza'];
    
    if (recentSearches.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppConstants.paddingMedium, 0, AppConstants.paddingMedium, AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Búsquedas recientes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildRecentSearchChip(recentSearches[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchChip(String search) {
    return GestureDetector(
      onTap: () {
        _searchController.text = search;
        // Aquí podrías agregar lógica para ejecutar la búsqueda
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Symbols.history,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              search,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
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
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              'Servicios Destacados',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              itemCount: 5, // Mock data
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ServiceCard(
                    title: 'Servicio ${index + 1}',
                    provider: 'Proveedor ${index + 1}',
                    price: 50.0 + (index * 10),
                    rating: 4.5 + (index * 0.1),
                    onTap: () {
                      final mockService = ServiceItem(
                        id: 'featured_$index',
                        title: 'Servicio ${index + 1}',
                        provider: 'Proveedor ${index + 1}',
                        price: 50.0 + (index * 10),
                        rating: 4.5 + (index * 0.1),
                        category: 'General',
                        description: 'Servicio profesional destacado con años de experiencia.',
                        isAvailable: true,
                        distance: 2.5 + index,
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailsPage(service: mockService),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyServicesSection() {
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
            // Mock nearby services
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ServiceCard(
                  title: 'Servicio Cercano ${index + 1}',
                  provider: 'Proveedor Local ${index + 1}',
                  price: 30.0 + (index * 15),
                  rating: 4.0 + (index * 0.2),
                  isHorizontal: true,
                  onTap: () {
                    final mockService = ServiceItem(
                      id: 'nearby_$index',
                      title: 'Servicio Cercano ${index + 1}',
                      provider: 'Proveedor Local ${index + 1}',
                      price: 30.0 + (index * 15),
                      rating: 4.0 + (index * 0.2),
                      category: 'Local',
                      description: 'Servicio local cercano a tu ubicación.',
                      isAvailable: true,
                      distance: 0.5 + (index * 0.3),
                    );
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPage(service: mockService),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


} 