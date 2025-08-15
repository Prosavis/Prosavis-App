import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
import '../../../core/utils/location_utils.dart';
import '../../widgets/common/service_card.dart';
import '../../blocs/search/search_bloc.dart';
import '../../blocs/search/search_event.dart';
import '../../blocs/search/search_state.dart';
import '../services/service_details_page.dart';
import '../../../core/services/haptics_service.dart';

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
          child: Stack(
            children: [
              // Degradado naranja sutil como en Home, extendido hasta un poco debajo del buscador
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 240,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentColor.withValues(alpha: 0.14),
                          AppTheme.accentColor.withValues(alpha: 0.06),
                          AppTheme.accentColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  return StretchingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // Botón de atrás para ir al inicio
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Symbols.arrow_back,
                color: AppTheme.getTextPrimary(context),
              ),
              tooltip: 'Volver al inicio',
            ),
            const SizedBox(width: 8),
            // Título
            Text(
              'Buscar',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ],
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
                 prefixIcon: Icon(
                   Symbols.search,
                   color: Theme.of(context).brightness == Brightness.dark
                       ? Colors.white
                       : null,
                 ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchBloc>().add(ClearSearchResults());
                        },
                        icon: Icon(
                          Symbols.close,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : null,
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
                              _performSearchWithFilters(_convertFiltersToMap(filters));
                            },
                          ),
                        );
                      },
                      icon: Icon(
                        Symbols.tune,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
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
                    color: AppTheme.getTextPrimary(context),
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
              Icon(
                Symbols.history,
                size: 20,
                color: AppTheme.getTextTertiary(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  search,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Symbols.close,
                  size: 16,
                  color: AppTheme.getTextTertiary(context),
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
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.serviceCategories
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final category = entry.value;
                final categoryName = AppConstants.getCategoryName(category);
                return _buildCategoryChip(
                  categoryName,
                  () => _performSearchWithCategory(categoryName),
                  index: index,
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, VoidCallback onTap, {required int index}) {
    return _AppearScale(
      delayMs: index * 80,
      child: _PressScale(
        onPressed: () {
          HapticsService.onPrimaryAction();
          onTap();
        },
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
                  Icon(
                    Symbols.search_off,
                    color: AppTheme.getTextTertiary(context),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron servicios',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con diferentes términos de búsqueda o filtros.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.getTextSecondary(context),
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
                      color: AppTheme.getTextPrimary(context),
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

  Future<void> _performSearchWithFilters(Map<String, dynamic> filters) async {
    final searchBloc = context.read<SearchBloc>();
    Map<String, double>? userLocation;
    // Si se requiere ordenar por distancia o hay radio personalizado, obtener ubicación
    if (filters['sortBy'] == 'distance' || (filters['radiusKm'] != null && filters['radiusKm'] != 10.0)) {
      userLocation = await LocationUtils.getCurrentUserLocation();
    }

    if (!mounted) return;

    searchBloc.add(SearchServices(
      query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      category: filters['category'],
      categories: (filters['categories'] as List<String>?)?.toList(),
      minPrice: filters['minPrice'],
      maxPrice: filters['maxPrice'],
      priceType: filters['priceType'],
      minRating: filters['minRating'],
      sortBy: filters['sortBy'],
      radiusKm: filters['radiusKm'],
      userLatitude: userLocation?['latitude'],
      userLongitude: userLocation?['longitude'],
    ));
  }

  Map<String, dynamic> _convertFiltersToMap(FilterSettings filters) {
    return {
      'category': filters.selectedCategories.isNotEmpty ? filters.selectedCategories.first : null,
      'categories': filters.selectedCategories.isNotEmpty ? filters.selectedCategories : null,
      'minPrice': filters.minPrice != 0.0 ? filters.minPrice : null,
      'maxPrice': filters.maxPrice != 2000000.0 ? filters.maxPrice : null,
      'priceType': null,
      'minRating': filters.minRating != 0.0 ? filters.minRating : null,
      'sortBy': _mapSortOptionToKey(filters.sortBy),
      'radiusKm': filters.radiusKm != 10.0 ? filters.radiusKm : null,
    };
  }

  String _mapSortOptionToKey(SortOption option) {
    switch (option) {
      case SortOption.priceLowToHigh:
        return 'priceLowToHigh';
      case SortOption.priceHighToLow:
        return 'priceHighToLow';
      case SortOption.rating:
        return 'rating';
      case SortOption.distance:
        return 'distance';
      case SortOption.newest:
        return 'newest';
    }
  }
}

class _AppearScale extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AppearScale({required this.child, this.delayMs = 0});

  @override
  State<_AppearScale> createState() => _AppearScaleState();
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;
  final Color color;

  const _PressScale({
    required this.child,
    required this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.color = Colors.transparent,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: widget.color,
        borderRadius: widget.borderRadius,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onPressed,
          onHighlightChanged: (value) {
            setState(() => _pressed = value);
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _AppearScaleState extends State<_AppearScale> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _visible ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}