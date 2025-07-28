import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    _buildCategoryFilter(),
                    const SizedBox(height: 24),
                    _buildLocationFilter(),
                    const SizedBox(height: 24),
                    _buildPriceRangeFilter(),
                    const SizedBox(height: 24),
                    _buildRatingFilter(),
                    const SizedBox(height: 24),
                    _buildAvailabilityFilter(),
                    const SizedBox(height: 24),
                    _buildSortByFilter(),
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
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filtros',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
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
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  category['name'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
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
                  color: AppTheme.textSecondary,
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
              '\$${_currentFilters.minPrice.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '\$${_currentFilters.maxPrice.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_currentFilters.minPrice, _currentFilters.maxPrice),
          min: 0,
          max: 1000,
          divisions: 50,
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
                  color: isSelected ? Colors.orange : Colors.grey.shade400,
                  size: 32,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Disponibilidad'),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: Text(
            'Solo servicios disponibles ahora',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          value: _currentFilters.availableNow,
          onChanged: (value) {
            setState(() {
              _currentFilters.availableNow = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryColor,
        ),
        CheckboxListTile(
          title: Text(
            'Incluir servicios con cita previa',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          value: _currentFilters.includeScheduled,
          onChanged: (value) {
            setState(() {
              _currentFilters.includeScheduled = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildSortByFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ordenar por'),
        const SizedBox(height: 12),
        ...SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(
              _getSortOptionName(option),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            value: option,
            groupValue: _currentFilters.sortBy,
            onChanged: (value) {
              setState(() {
                _currentFilters.sortBy = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryColor,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
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
      case SortOption.relevance:
        return 'Relevancia';
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
  bool availableNow;
  bool includeScheduled;
  SortOption sortBy;

  FilterSettings({
    this.selectedCategories = const [],
    this.radiusKm = 10.0,
    this.minPrice = 0.0,
    this.maxPrice = 500.0,
    this.minRating = 0.0,
    this.availableNow = false,
    this.includeScheduled = true,
    this.sortBy = SortOption.relevance,
  });

  bool get hasActiveFilters {
    return selectedCategories.isNotEmpty ||
           radiusKm != 10.0 ||
           minPrice != 0.0 ||
           maxPrice != 500.0 ||
           minRating != 0.0 ||
           availableNow ||
           !includeScheduled ||
           sortBy != SortOption.relevance;
  }
}

enum SortOption {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  rating,
  distance,
  newest,
} 