import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/service_card.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
import 'service_details_page.dart';

class CategoryServicesPage extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryServicesPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryServicesPage> createState() => _CategoryServicesPageState();
}

class _CategoryServicesPageState extends State<CategoryServicesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  FilterSettings _currentFilters = FilterSettings();
  List<ServiceItem> _services = [];
  List<ServiceItem> _filteredServices = [];
  bool _isLoading = false;

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

    _loadServices();
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
        ),
        title: Text(
          widget.category['name'] as String,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchAndFilters(),
            _buildResultsHeader(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildServicesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterServices,
              decoration: InputDecoration(
                hintText: 'Buscar en ${widget.category['name']}...',
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterServices('');
                        },
                        icon: const Icon(Symbols.clear),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _showFilters,
              icon: Stack(
                children: [
                  const Icon(Symbols.tune),
                  if (_currentFilters.hasActiveFilters)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            widget.category['icon'] as IconData,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '${_filteredServices.length} servicios encontrados',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          if (_currentFilters.hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Limpiar filtros',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    if (_filteredServices.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            title: service.title,
            provider: service.provider,
            price: service.price,
            rating: service.rating,
            imageUrl: service.imageUrl,
            isHorizontal: true,
            onTap: () => _navigateToServiceDetails(service),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Symbols.search_off,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron servicios',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros o buscar algo diferente',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Limpiar filtros',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadServices() {
    setState(() {
      _isLoading = true;
    });

    // Mock data - in real app, this would load from your data source
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _services = _generateMockServices();
          _filteredServices = _services;
          _isLoading = false;
        });
      }
    });
  }

  List<ServiceItem> _generateMockServices() {
    final categoryName = widget.category['name'] as String;
    final List<ServiceItem> services = [];
    
    // Generate mock services based on category
    for (int i = 1; i <= 15; i++) {
      services.add(ServiceItem(
        id: '${categoryName.toLowerCase()}_$i',
        title: _getServiceTitle(categoryName, i),
        provider: _getProviderName(i),
        price: _getServicePrice(categoryName, i),
        rating: 3.5 + (i % 4) * 0.3,
        imageUrl: null,
        category: categoryName,
        description: _getServiceDescription(categoryName, i),
        isAvailable: i % 4 != 0,
        distance: (i % 10) + 1.0,
      ));
    }
    
    return services;
  }

  String _getServiceTitle(String category, int index) {
    final Map<String, List<String>> categoryTitles = {
      'Limpieza': [
        'Limpieza profunda de hogar',
        'Limpieza de oficinas',
        'Limpieza post-construcción',
        'Limpieza de alfombras',
        'Limpieza de ventanas',
      ],
      'Plomería': [
        'Reparación de tuberías',
        'Instalación de grifos',
        'Destape de drenajes',
        'Reparación de inodoros',
        'Instalación de regaderas',
      ],
      'Electricidad': [
        'Instalación eléctrica',
        'Reparación de contactos',
        'Instalación de lámparas',
        'Cableado de casas',
        'Reparación de tableros',
      ],
      // Add more categories as needed
    };
    
    final titles = categoryTitles[category] ?? ['Servicio de $category'];
    return titles[(index - 1) % titles.length];
  }

  String _getProviderName(int index) {
    final List<String> names = [
      'Juan Pérez', 'María García', 'Carlos López', 'Ana Martínez',
      'Luis Rodríguez', 'Carmen Silva', 'Miguel Torres', 'Laura Jiménez',
      'Roberto Díaz', 'Patricia Ruiz', 'Fernando Morales', 'Isabel Castro',
      'Andrés Herrera', 'Mónica Vargas', 'Daniel Romero'
    ];
    
    return names[(index - 1) % names.length];
  }

  double _getServicePrice(String category, int index) {
    final Map<String, double> basePrices = {
      'Limpieza': 25.0,
      'Plomería': 40.0,
      'Electricidad': 50.0,
      'Carpintería': 35.0,
      'Pintura': 30.0,
      'Jardinería': 20.0,
      'Tecnología': 60.0,
      'Mecánica': 45.0,
      'Cocina': 80.0,
      'Tutorías': 15.0,
      'Belleza': 25.0,
      'Mudanzas': 100.0,
    };
    
    final basePrice = basePrices[category] ?? 30.0;
    return basePrice + (index % 5) * 10.0;
  }

  String _getServiceDescription(String category, int index) {
    return 'Servicio profesional de $category con años de experiencia. Trabajo garantizado y materiales de calidad incluidos.';
  }

  void _filterServices([String? query]) {
    final searchQuery = query ?? _searchController.text;
    
    setState(() {
      _filteredServices = _services.where((service) {
        final matchesSearch = searchQuery.isEmpty ||
            service.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            service.provider.toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesFilters = _matchesFilters(service);
        
        return matchesSearch && matchesFilters;
      }).toList();
      
      // Apply sorting
      _applySorting();
    });
  }

  bool _matchesFilters(ServiceItem service) {
    if (_currentFilters.minPrice > 0 && service.price < _currentFilters.minPrice) {
      return false;
    }
    
    if (_currentFilters.maxPrice < 1000 && service.price > _currentFilters.maxPrice) {
      return false;
    }
    
    if (_currentFilters.minRating > 0 && service.rating < _currentFilters.minRating) {
      return false;
    }
    
    if (_currentFilters.radiusKm < 50 && service.distance > _currentFilters.radiusKm) {
      return false;
    }
    
    if (_currentFilters.availableNow && !service.isAvailable) {
      return false;
    }
    
    return true;
  }

  void _applySorting() {
    switch (_currentFilters.sortBy) {
      case SortOption.priceLowToHigh:
        _filteredServices.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        _filteredServices.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.rating:
        _filteredServices.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.distance:
        _filteredServices.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case SortOption.newest:
        // Keep original order for newest
        break;
      case SortOption.relevance:
        // Keep original order for relevance
        break;
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersBottomSheet(
        initialFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _filterServices();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = FilterSettings();
      _searchController.clear();
    });
    _filterServices('');
  }

  void _navigateToServiceDetails(ServiceItem service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsPage(service: service),
      ),
    );
  }
}

class ServiceItem {
  final String id;
  final String title;
  final String provider;
  final double price;
  final double rating;
  final String? imageUrl;
  final String category;
  final String description;
  final bool isAvailable;
  final double distance;

  ServiceItem({
    required this.id,
    required this.title,
    required this.provider,
    required this.price,
    required this.rating,
    this.imageUrl,
    required this.category,
    required this.description,
    required this.isAvailable,
    required this.distance,
  });
} 