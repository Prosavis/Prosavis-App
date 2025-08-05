import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/injection/injection_container.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/usecases/services/search_services_usecase.dart';
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
  late SearchServicesUseCase _searchServicesUseCase;

  final TextEditingController _searchController = TextEditingController();
  FilterSettings _currentFilters = FilterSettings();
  List<ServiceEntity> _services = [];
  List<ServiceEntity> _filteredServices = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchServicesUseCase = sl<SearchServicesUseCase>();
    
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
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildServicesList(),
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
            provider: service.providerName,
            price: service.price,
            rating: service.rating,
            imageUrl: service.images.isNotEmpty ? service.images.first : null,
            isHorizontal: true,
            onTap: () => _navigateToServiceDetails(service),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Symbols.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar servicios',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Ha ocurrido un error inesperado',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Reintentar',
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

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener servicios reales filtrados por categoría desde Firestore
      final categoryName = widget.category['name'] as String;
      final services = await _searchServicesUseCase.call(
        SearchServicesParams(
          category: categoryName,
          limit: 50, // Cargar más servicios para poder filtrar
        ),
      );

      if (mounted) {
        setState(() {
          _services = services;
          _filteredServices = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _services = [];
          _filteredServices = [];
          _isLoading = false;
          _errorMessage = 'Error al cargar servicios: $e';
        });
      }
    }
  }

  void _filterServices([String? query]) {
    final searchQuery = query ?? _searchController.text;
    
    setState(() {
      _filteredServices = _services.where((service) {
        final matchesSearch = searchQuery.isEmpty ||
            service.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            service.providerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            service.description.toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesFilters = _matchesFilters(service);
        
        return matchesSearch && matchesFilters;
      }).toList();
      
      // Apply sorting
      _applySorting();
    });
  }

  bool _matchesFilters(ServiceEntity service) {
    if (_currentFilters.minPrice > 0 && service.price < _currentFilters.minPrice) {
      return false;
    }
    
    if (_currentFilters.maxPrice < 1000 && service.price > _currentFilters.maxPrice) {
      return false;
    }
    
    if (_currentFilters.minRating > 0 && service.rating < _currentFilters.minRating) {
      return false;
    }
    
    if (_currentFilters.availableNow && !service.isActive) {
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
        // Para distancia, podríamos calcular basado en ubicación
        // Por ahora mantener orden original
        break;
      case SortOption.newest:
        _filteredServices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.relevance:
        // Mantener orden original para relevancia
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

  void _navigateToServiceDetails(ServiceEntity service) {
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