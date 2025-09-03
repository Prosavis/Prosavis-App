import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/favorites/favorites_event.dart';
import '../../blocs/favorites/favorites_state.dart';

import '../../widgets/common/service_card.dart';
import '../../../domain/entities/service_entity.dart';
import '../../widgets/common/filters_bottom_sheet.dart';
import '../../../core/utils/location_utils.dart';

class SavedPage extends StatefulWidget {
  final VoidCallback? onExploreServicesTapped;
  
  const SavedPage({super.key, this.onExploreServicesTapped});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  FilterSettings? _favoriteFilters;
  Map<String, double>? _userLocationForFilters;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    if (authState is AuthAuthenticated) {
                      // Usar la instancia global y cargar favoritos si es necesario
                      final favoritesBloc = context.read<FavoritesBloc>();
                      
                      // Solo cargar favoritos si no están cargados o el estado es inicial
                      if (favoritesBloc.state is FavoritesInitial) {
                        favoritesBloc.add(LoadUserFavorites(authState.user.id));
                      }
                      
                      return _buildFavoritesContent(authState.user.id);
                    } else {
                      return const LoginRequiredWidget(
                        title: 'Inicia sesión para ver tus favoritos',
                        subtitle: 'Necesitas tener una cuenta para guardar servicios favoritos.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesContent(String userId) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (state is FavoritesError) {
          return _buildErrorState(state.message, userId);
        }
        
        if (state is FavoritesLoaded) {
          if (state.favorites.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildFavoritesList(state, userId);
        }
        
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildFavoritesList(FavoritesLoaded state, String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FavoritesBloc>().add(RefreshFavorites(userId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           _buildFavoritesHeader(state),
          const SizedBox(height: 16),
          _buildServicesColumn(_getFilteredFavorites(state.favorites), userId),
        ],
      ),
    );
  }

  Widget _buildFavoritesHeader(FavoritesLoaded state) {
    final total = state.favorites.length;
    final visible = _getFilteredFavorites(state.favorites).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.red.withValues(alpha: 0.25)
                  : Colors.red.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Symbols.favorite,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasActiveFavoriteFilters
                      ? 'Mostrando $visible de $total'
                      : '$total servicio${total != 1 ? 's' : ''} guardado${total != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                Text(
                  _hasActiveFavoriteFilters
                      ? 'Filtros activos aplicados'
                      : 'Tus servicios favoritos guardados',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_hasActiveFavoriteFilters)
            TextButton(
              onPressed: _clearFavoriteFilters,
              child: Text(
                'Limpiar',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            onPressed: _openFavoriteFilters,
            tooltip: 'Filtros',
            icon: Icon(
              Symbols.tune,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesColumn(List<ServiceEntity> services, String userId) {
    return Column(
      children: services.map((service) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ServiceCard(
          service: service,
          fullWidth: true,
          showFavoriteButton: true,
          isFavorite: true,
          onFavoriteToggle: () {
            _confirmRemoveFavorite(userId, service);
          },
        ),
      )).toList(),
    );
  }

  Future<void> _confirmRemoveFavorite(String userId, ServiceEntity service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Quitar de favoritos',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Quieres quitar "${service.title}" de tus favoritos?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<FavoritesBloc>().add(
        ToggleFavorite(userId: userId, serviceId: service.id),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.favorite_border,
              size: 80,
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes favoritos aún',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Explora servicios y guarda tus favoritos tocando el ícono de corazón. Aparecerán aquí para acceso rápido.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onExploreServicesTapped,
              icon: const Icon(Symbols.search),
              label: const Text('Explorar servicios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.error,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar favoritos',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FavoritesBloc>().add(LoadUserFavorites(userId));
              },
              icon: const Icon(Symbols.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Text(
        'Favoritos',
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.getTextPrimary(context),
        ),
      ),
    );
  }

  bool get _hasActiveFavoriteFilters => _favoriteFilters?.hasActiveFilters == true;

  Future<void> _openFavoriteFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersBottomSheet(
        initialFilters: _favoriteFilters,
        onFiltersApplied: (filters) async {
          // Guardar filtros seleccionados
          setState(() {
            _favoriteFilters = filters;
          });
          // Si se requiere ubicación, obtenerla
          if (filters.sortBy == SortOption.distance || filters.radiusKm != 10.0) {
            final userLoc = await LocationUtils.getCurrentUserLocation();
            if (!mounted) return;
            setState(() {
              _userLocationForFilters = userLoc;
            });
          }
        },
      ),
    );
  }

  void _clearFavoriteFilters() {
    setState(() {
      _favoriteFilters = FilterSettings();
      _userLocationForFilters = null;
    });
  }

  List<ServiceEntity> _getFilteredFavorites(List<ServiceEntity> favorites) {
    final filters = _favoriteFilters;
    if (filters == null || !filters.hasActiveFilters) {
      return List<ServiceEntity>.from(favorites);
    }

    final result = favorites.where((s) {
      // Categorías
      if (filters.selectedCategories.isNotEmpty &&
          !filters.selectedCategories.contains(s.category)) {
        return false;
      }
      // Precio
      if (s.price < filters.minPrice || s.price > filters.maxPrice) {
        return false;
      }
      // Rating
      if (s.rating < filters.minRating) {
        return false;
      }
      // Radio de distancia
      if (filters.radiusKm != 10.0) {
        final dist = _computeDistanceKm(s);
        if (dist == null || dist > filters.radiusKm) {
          return false;
        }
      }
      return true;
    }).toList();

    // Ordenar
    switch (filters.sortBy) {
      case SortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.distance:
        result.sort((a, b) {
          final da = _computeDistanceKm(a);
          final db = _computeDistanceKm(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
      case SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }

  double? _computeDistanceKm(ServiceEntity service) {
    final loc = service.location;
    final userLoc = _userLocationForFilters;
    if (loc == null || userLoc == null) return null;
    final lat = (loc['latitude'] as num?)?.toDouble();
    final lon = (loc['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return LocationUtils.calculateDistance(
      userLoc['latitude']!,
      userLoc['longitude']!,
      lat,
      lon,
    );
  }
}