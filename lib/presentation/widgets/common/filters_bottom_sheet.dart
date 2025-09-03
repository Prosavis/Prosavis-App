import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class FiltersBottomSheet extends StatefulWidget {
  final Function(FilterSettings) onFiltersApplied;
  final FilterSettings? initialFilters;

  const FiltersBottomSheet({
    super.key,
    required this.onFiltersApplied,
    this.initialFilters,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  late FilterSettings _currentFilters;

  @override
  void initState() {
    super.initState();
    
    _currentFilters = widget.initialFilters ?? FilterSettings();
    
    _slideController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ordenar por debe ser lo primero
                    _buildSortByFilter(),
                    const SizedBox(height: 24),
                    _buildCategoryFilter(),
                    const SizedBox(height: 24),
                    _buildLocationFilter(),
                    const SizedBox(height: 24),
                    _buildPriceRangeFilter(),
                    const SizedBox(height: 24),
                    _buildRatingFilter(),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filtros',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Restablecer',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categorías'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.serviceCategories.map((category) {
            final isSelected = _currentFilters.selectedCategories.contains(category['name']);
            return GestureDetector(
              onTap: () => _toggleCategory(category['name']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.getBorderColor(context),
                  ),
                ),
                child: Text(
                  category['name'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ubicación'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Radio de búsqueda: ${_currentFilters.radiusKm.toInt()} km',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _currentFilters.radiusKm,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) {
            setState(() {
              _currentFilters.radiusKm = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rango de precios'),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              _formatCOP(_currentFilters.minPrice),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const Spacer(),
            Text(
              _formatCOP(_currentFilters.maxPrice),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_currentFilters.minPrice, _currentFilters.maxPrice),
          min: 0,
          // Máximo en COP (2'000,000)
          max: 2000000,
          // Pasos de 50k
          divisions: 40,
          activeColor: AppTheme.primaryColor,
          onChanged: (values) {
            setState(() {
              _currentFilters.minPrice = values.start;
              _currentFilters.maxPrice = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Calificación mínima'),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3, 4, 5].map((rating) {
            final isSelected = _currentFilters.minRating >= rating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentFilters.minRating = rating.toDouble();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Symbols.star : Symbols.star_outline,
                  color: isSelected ? Colors.orange : AppTheme.getTextTertiary(context),
                  size: 32,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Se elimina la sección de disponibilidad según requerimiento

  Widget _buildSortByFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ordenar por'),
        const SizedBox(height: 12),
        ...SortOption.values.map((option) {
          final isSelected = _currentFilters.sortBy == option;
          return ListTile(
            onTap: () {
              setState(() {
                _currentFilters.sortBy = option;
              });
            },
            leading: Icon(
              isSelected ? Symbols.radio_button_checked : Symbols.radio_button_unchecked,
              color: AppTheme.primaryColor,
            ),
            title: Text(
              _getSortOptionName(option),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            contentPadding: EdgeInsets.zero,
            selected: isSelected,
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.getTextPrimary(context),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        AppConstants.paddingMedium,
        AppConstants.paddingMedium,
        AppConstants.paddingMedium + bottomPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Aplicar filtros',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_currentFilters.selectedCategories.contains(category)) {
        _currentFilters.selectedCategories.remove(category);
      } else {
        _currentFilters.selectedCategories.add(category);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _currentFilters = FilterSettings();
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_currentFilters);
    Navigator.pop(context);
  }

  String _getSortOptionName(SortOption option) {
    switch (option) {
      case SortOption.priceLowToHigh:
        return 'Precio: menor a mayor';
      case SortOption.priceHighToLow:
        return 'Precio: mayor a menor';
      case SortOption.rating:
        return 'Mejor calificado';
      case SortOption.distance:
        return 'Distancia';
      case SortOption.newest:
        return 'Más recientes';
    }
  }
}

class FilterSettings {
  List<String> selectedCategories;
  double radiusKm;
  double minPrice;
  double maxPrice;
  double minRating;
  SortOption sortBy;

  FilterSettings({
    List<String>? selectedCategories,
    this.radiusKm = 10.0,
    this.minPrice = 0.0,
    this.maxPrice = 2000000.0,
    this.minRating = 0.0,
    this.sortBy = SortOption.newest,
  }) : selectedCategories = List<String>.from(selectedCategories ?? const []);

  bool get hasActiveFilters {
    return selectedCategories.isNotEmpty ||
           radiusKm != 10.0 ||
           minPrice != 0.0 ||
           maxPrice != 2000000.0 ||
           minRating != 0.0 ||
           sortBy != SortOption.newest;
  }
}

enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  rating,
  distance,
  newest,
} 

String _formatCOP(num value) {
  final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
  return formatter.format(value.round());
}