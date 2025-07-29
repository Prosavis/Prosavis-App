import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/category_card.dart';
import '../../widgets/common/service_card.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
import '../notifications/notifications_page.dart';
import '../services/service_request_page.dart';
import '../services/service_creation_page.dart';
import '../categories/categories_page.dart';
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
  int _selectedIndex = 0;

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
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildHomeContent(state);
          }
          return _buildLoadingContent();
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
            _buildQuickActions(),
            _buildCategoriesSection(),
            _buildFeaturedServicesSection(),
            _buildNearbyServicesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
              icon: const Icon(
                Symbols.notifications,
                color: AppTheme.textSecondary,
              ),
            ),
            
            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(AuthSignOutRequested());
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Symbols.person, size: 20),
                      SizedBox(width: 8),
                      Text('Mi Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Symbols.settings, size: 20),
                      SizedBox(width: 8),
                      Text('Configuración'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Symbols.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Cerrar Sesión'),
                    ],
                  ),
                ),
              ],
              child: const Icon(
                Symbols.more_vert,
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

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Solicitar Servicio',
                subtitle: 'Encuentra profesionales',
                icon: Symbols.search,
                gradient: AppTheme.primaryGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceRequestPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Ofrecer Servicio',
                subtitle: 'Comparte tus habilidades',
                icon: Symbols.work,
                gradient: AppTheme.secondaryGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceCreationPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
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
                  'Categorías',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoriesPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Ver todas',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              itemCount: AppConstants.serviceCategories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CategoryCard(
                    category: AppConstants.getCategoryName(AppConstants.serviceCategories[index]),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryServicesPage(
                            category: AppConstants.serviceCategories[index],
                          ),
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textTertiary,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Symbols.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.search),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.bookmark),
          label: 'Guardados',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.chat),
          label: 'Mensajes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.person),
          label: 'Perfil',
        ),
      ],
    );
  }
} 