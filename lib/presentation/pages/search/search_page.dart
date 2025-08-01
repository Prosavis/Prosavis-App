import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
import '../../widgets/common/service_card.dart';
import '../../blocs/search/search_bloc.dart';
import '../../blocs/search/search_event.dart';
import '../../blocs/search/search_state.dart';
import '../services/service_details_page.dart';
import '../services/category_services_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
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
    
    // Cargar búsquedas recientes al abrir la página
    context.read<SearchBloc>().add(LoadRecentSearches());
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  _buildSearchSection(),
                  if (state.hasSearched) ...[
                    _buildSearchResults(state),
                  ] else ...[
                    _buildRecentSearches(state),
                    _buildSuggestedCategories(),
                  ]
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Text(
          'Buscar',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (query) => _performSearch(query),
              decoration: InputDecoration(
                hintText: 'Buscar servicios, profesionales...',
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchBloc>().add(ClearSearchResults());
                        },
                        icon: const Icon(Symbols.close),
                      ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FiltersBottomSheet(
                            onFiltersApplied: (filters) {
                              _performSearchWithFilters(_convertFiltersToMap(filters));
                            },
                          ),
                        );
                      },
                      icon: const Icon(Symbols.tune),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(SearchState state) {
    if (state.recentSearches.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Búsquedas Recientes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<SearchBloc>().add(ClearAllRecentSearches());
                  },
                  child: Text(
                    'Limpiar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...state.recentSearches.map(
              (search) => _buildRecentSearchItem(
                search,
                () => _performSearch(search),
                () => context.read<SearchBloc>().add(RemoveRecentSearch(search)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search, VoidCallback onTap, VoidCallback onRemove) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              const Icon(
                Symbols.history,
                size: 20,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  search,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Symbols.close,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedCategories() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorías Populares',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.serviceCategories.map((category) {
                final categoryName = AppConstants.getCategoryName(category);
                return _buildCategoryChip(
                  categoryName,
                  () => _performSearchWithCategory(categoryName),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    if (state.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  Icon(
                    Symbols.error,
                    color: Colors.red.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SearchBloc>().add(ClearSearchResults());
                    },
                    child: const Text('Volver a buscar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (state.searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  const Icon(
                    Symbols.search_off,
                    color: AppTheme.textTertiary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron servicios',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con diferentes términos de búsqueda o filtros.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingMedium, 
                0, 
                AppConstants.paddingMedium, 
                AppConstants.paddingMedium
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.searchResults.length} servicios encontrados',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<SearchBloc>().add(ClearSearchResults());
                    },
                    child: const Text('Nueva búsqueda'),
                  ),
                ],
              ),
            );
          }

          final service = state.searchResults[index - 1];
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              0,
              AppConstants.paddingMedium,
              AppConstants.paddingSmall,
            ),
            child: ServiceCard(
              title: service.title,
              provider: service.providerName,
              price: service.price,
              rating: service.rating,
              onTap: () {
                // Convertir ServiceEntity a ServiceItem para detalles
                final serviceItem = ServiceItem(
                  id: service.id,
                  title: service.title,
                  provider: service.providerName,
                  price: service.price,
                  rating: service.rating,
                  category: service.category,
                  description: service.description,
                  isAvailable: service.isActive,
                  distance: 0.0, // Por ahora sin geolocalización
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
        childCount: state.searchResults.length + 1,
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    _searchController.text = query;
    context.read<SearchBloc>().add(AddRecentSearch(query.trim()));
    context.read<SearchBloc>().add(SearchServices(query: query.trim()));
  }

  void _performSearchWithCategory(String category) {
    context.read<SearchBloc>().add(SearchServices(category: category));
  }

  void _performSearchWithFilters(Map<String, dynamic> filters) {
    context.read<SearchBloc>().add(SearchServices(
      query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      category: filters['category'],
      minPrice: filters['minPrice'],
      maxPrice: filters['maxPrice'],
      priceType: filters['priceType'],
    ));
  }

  Map<String, dynamic> _convertFiltersToMap(FilterSettings filters) {
    return {
      'category': filters.selectedCategories.isNotEmpty ? filters.selectedCategories.first : null,
      'minPrice': filters.minPrice != 0.0 ? filters.minPrice : null,
      'maxPrice': filters.maxPrice != 500.0 ? filters.maxPrice : null,
      'priceType': null, // FilterSettings no tiene priceType, se puede añadir si es necesario
    };
  }
}