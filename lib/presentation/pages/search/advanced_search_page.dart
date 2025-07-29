import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/provider.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/service_chip.dart';
import '../../widgets/verification_badge.dart';

class AdvancedSearchPage extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const AdvancedSearchPage({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  State<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  // Filter states
  final List<String> _selectedCategories = [];
  RangeValues _priceRange = const RangeValues(10, 100);
  double _selectedRating = 0;
  int _selectedDistance = 20; // km
  bool _instantBookingOnly = false;
  bool _verifiedOnly = false;
  final List<String> _selectedAvailability = [];
  String _sortBy = 'relevance';

  // Mock data
  final List<String> _categories = [
    'Plomería', 'Electricidad', 'Carpintería', 'Limpieza', 'Jardinería',
    'Pintura', 'Refrigeración', 'Cerrajería', 'Mecánica', 'Tecnología'
  ];

  final List<String> _availabilityOptions = [
    'Ahora', 'Hoy', 'Mañana', 'Esta semana', 'Fin de semana'
  ];

  final List<String> _sortOptions = [
    'Relevancia', 'Mejor calificados', 'Menor precio', 'Mayor precio',
    'Más cercanos', 'Más experiencia'
  ];

  List<Provider> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.text = widget.initialQuery ?? '';
    if (widget.initialCategory != null) {
      _selectedCategories.add(widget.initialCategory!);
    }
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResultsTab(),
                _buildFiltersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Symbols.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Buscar servicios',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      actions: [
        if (_hasActiveFilters())
          IconButton(
            icon: const Icon(Symbols.filter_list_off, color: Colors.red),
            onPressed: _clearAllFilters,
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                  prefixIcon: Icon(Symbols.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14),
                onSubmitted: (value) => _performSearch(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Symbols.search, color: Colors.white),
              onPressed: _performSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.list, size: 18),
                const SizedBox(width: 8),
                Text('Resultados (${_searchResults.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.tune, size: 18),
                const SizedBox(width: 8),
                const Text('Filtros'),
                if (_hasActiveFilters()) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return Column(
      children: [
        _buildSortBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildProviderCard(_searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Symbols.sort, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Ordenar por:',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: [
                  'relevance', 'rating', 'price_low', 'price_high',
                  'distance', 'experience'
                ].asMap().entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(
                      _sortOptions[entry.key],
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _performSearch();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No se encontraron resultados',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos o\najusta los filtros',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearAllFilters,
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Provider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to provider profile
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(provider.profileImage),
                      ),
                      if (provider.isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (provider.isVerified)
                              const VerificationBadge(size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingStars(
                              rating: provider.rating.overall,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${provider.rating.overall} (${provider.rating.totalReviews})',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${provider.hourlyRate.toInt()}/h',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                provider.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.services.take(3).map((service) {
                  return ServiceChip(
                    label: service,
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Responde en ${provider.responseTime}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Symbols.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.location.serviceRadius.toInt()} km',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (provider.availability.instantBooking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reserva instantánea',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoriesFilter(),
          const SizedBox(height: 24),
          _buildPriceRangeFilter(),
          const SizedBox(height: 24),
          _buildRatingFilter(),
          const SizedBox(height: 24),
          _buildDistanceFilter(),
          const SizedBox(height: 24),
          _buildAvailabilityFilter(),
          const SizedBox(height: 24),
          _buildQuickFilters(),
          const SizedBox(height: 32),
          _buildApplyFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    return _buildFilterSection(
      title: 'Categorías',
      icon: Symbols.category,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((category) {
          final isSelected = _selectedCategories.contains(category);
          return ServiceChip(
            label: category,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCategories.remove(category);
                } else {
                  _selectedCategories.add(category);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return _buildFilterSection(
      title: 'Rango de precios (por hora)',
      icon: Symbols.payments,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_priceRange.start.round()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                '\$${_priceRange.end.round()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 10,
            max: 200,
            divisions: 19,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return _buildFilterSection(
      title: 'Calificación mínima',
      icon: Symbols.star,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cualquiera'),
              Text(
                _selectedRating > 0 ? '${_selectedRating.toInt()}+ estrellas' : '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Slider(
            value: _selectedRating,
            min: 0,
            max: 5,
            divisions: 5,
            label: _selectedRating > 0 ? '${_selectedRating.toInt()}+ estrellas' : 'Cualquiera',
            onChanged: (value) {
              setState(() {
                _selectedRating = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return _buildFilterSection(
      title: 'Distancia máxima',
      icon: Symbols.location_on,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cerca'),
              Text(
                '$_selectedDistance km',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Slider(
            value: _selectedDistance.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: '$_selectedDistance km',
            onChanged: (value) {
              setState(() {
                _selectedDistance = value.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityFilter() {
    return _buildFilterSection(
      title: 'Disponibilidad',
      icon: Symbols.schedule,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availabilityOptions.map((option) {
          final isSelected = _selectedAvailability.contains(option);
          return ServiceChip(
            label: option,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedAvailability.remove(option);
                } else {
                  _selectedAvailability.add(option);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return _buildFilterSection(
      title: 'Filtros rápidos',
      icon: Symbols.flash_on,
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _instantBookingOnly,
                onChanged: (value) {
                  setState(() {
                    _instantBookingOnly = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Solo reserva instantánea',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _verifiedOnly,
                onChanged: (value) {
                  setState(() {
                    _verifiedOnly = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Solo proveedores verificados',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildApplyFiltersButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _performSearch();
          _tabController.animateTo(0);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Aplicar filtros',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategories.isNotEmpty ||
        _priceRange.start > 10 ||
        _priceRange.end < 200 ||
        _selectedRating > 0 ||
        _selectedDistance < 50 ||
        _selectedAvailability.isNotEmpty ||
        _instantBookingOnly ||
        _verifiedOnly;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _priceRange = const RangeValues(10, 200);
      _selectedRating = 0;
      _selectedDistance = 50;
      _selectedAvailability.clear();
      _instantBookingOnly = false;
      _verifiedOnly = false;
      _sortBy = 'relevance';
    });
    _performSearch();
  }

  void _performSearch() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _searchResults = _generateMockResults();
      });
    });
  }

  List<Provider> _generateMockResults() {
    // Mock search results based on filters
    return List.generate(8, (index) {
      return Provider(
        id: 'provider_$index',
        name: _getMockName(index),
        email: 'provider$index@example.com',
        phone: '+57 30$index 123 45$index$index',
        profileImage: 'https://images.unsplash.com/photo-150700321${index + 1}169-0a1dd7228f2d?w=150',
        description: _getMockDescription(index),
        services: _getMockServices(index),
        coverPhotos: const [],
        workSamples: const [],
        verification: ProviderVerification(
          identityVerified: true,
          phoneVerified: true,
          emailVerified: true,
          backgroundCheckVerified: index % 2 == 0,
          documents: const [],
          verificationLevel: index % 3 == 0 ? 'premium' : 'standard',
          verifiedAt: DateTime.now(),
        ),
        rating: ProviderRating(
          overall: 4.0 + (index % 6) * 0.2,
          totalReviews: 50 + index * 10,
          starDistribution: const {},
          quality: 4.5,
          punctuality: 4.3,
          communication: 4.7,
          value: 4.4,
          recentReviews: const [],
        ),
        availability: ProviderAvailability(
          weeklySchedule: const {},
          unavailableDates: const [],
          instantBooking: index % 3 == 0,
          advanceBookingDays: 1 + (index % 3),
        ),
        location: Location(
          latitude: 4.7110,
          longitude: -74.0721,
          address: 'Bogotá, Colombia',
          city: 'Bogotá',
          state: 'Cundinamarca',
          zipCode: '110111',
          serviceRadius: 15.0 + (index % 10),
        ),
        certifications: const [],
        experienceYears: 3 + (index % 8),
        hourlyRate: 25.0 + (index * 5),
        isOnline: index % 2 == 0,
        isVerified: index % 4 != 3,
        joinedAt: DateTime.now().subtract(Duration(days: index * 30)),
        completedJobs: 20 + index * 15,
        responseTime: index % 2 == 0 ? '< 5 min' : '< 15 min',
      );
    });
  }

  String _getMockName(int index) {
    final names = [
      'Carlos Rodríguez', 'Ana García', 'Miguel Torres', 'Laura Martínez',
      'José López', 'María Fernández', 'David Ruiz', 'Carmen Jiménez'
    ];
    return names[index % names.length];
  }

  String _getMockDescription(int index) {
    final descriptions = [
      'Especialista en plomería con 10 años de experiencia',
      'Técnico en electricidad certificado y confiable',
      'Carpintero experto en muebles a medida',
      'Servicio de limpieza profesional para hogares',
      'Jardinero especializado en espacios urbanos',
      'Pintor con técnicas modernas y materiales de calidad',
      'Técnico en refrigeración y aires acondicionados',
      'Cerrajero 24/7 con servicio de emergencia'
    ];
    return descriptions[index % descriptions.length];
  }

  List<String> _getMockServices(int index) {
    final serviceGroups = [
      ['Plomería', 'Reparaciones'],
      ['Electricidad', 'Instalaciones'],
      ['Carpintería', 'Muebles'],
      ['Limpieza', 'Organización'],
      ['Jardinería', 'Mantenimiento'],
      ['Pintura', 'Decoración'],
      ['Refrigeración', 'Clima'],
      ['Cerrajería', 'Seguridad']
    ];
    return serviceGroups[index % serviceGroups.length];
  }
} 