import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../services/category_services_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCategories = [];

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

    _filteredCategories = AppConstants.serviceCategories;
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Symbols.arrow_back, color: AppTheme.getTextPrimary(context)),
        ),
        title: Text(
          'Todas las Categorías',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildCategoriesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.getSurfaceColor(context),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: TextField(
        controller: _searchController,
        onChanged: _filterCategories,
        decoration: InputDecoration(
          hintText: 'Buscar categorías...',
          prefixIcon: Icon(Symbols.search, color: AppTheme.getTextSecondary(context)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterCategories('');
                  },
                  icon: Icon(Symbols.clear, color: AppTheme.getTextSecondary(context)),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (_filteredCategories.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _filteredCategories.length,
        // Optimizaciones para mejor rendimiento
        cacheExtent: 1000,
        physics: const BouncingScrollPhysics(),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: _buildCategoryCard(_filteredCategories[index]),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _navigateToCategoryServices(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category['icon'] as IconData,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              category['name'] as String,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            Text(
              '${_getServiceCount(category)} servicios',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textTertiary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(category['name'] as String).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCategoryLabel(category['name'] as String),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getCategoryColor(category['name'] as String),
                ),
              ),
            ),
          ],
        ),
      ),
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
            'No se encontraron categorías',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otra búsqueda',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = AppConstants.serviceCategories;
      } else {
        _filteredCategories = AppConstants.serviceCategories
            .where((category) => category['name']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToCategoryServices(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryServicesPage(
          category: category,
        ),
      ),
    );
  }

  int _getServiceCount(Map<String, dynamic> category) {
    // Mock data - in real app, this would come from your data source
    final Map<String, int> serviceCounts = {
      'Limpieza': 45,
      'Plomería': 32,
      'Electricidad': 28,
      'Carpintería': 19,
      'Pintura': 23,
      'Jardinería': 15,
      'Tecnología': 41,
      'Mecánica': 17,
      'Cocina': 12,
      'Tutorías': 38,
      'Belleza': 26,
      'Mudanzas': 11,
    };
    
    return serviceCounts[category['name']] ?? 0;
  }

  Color _getCategoryColor(String categoryName) {
    final Map<String, Color> categoryColors = {
      'Limpieza': Colors.blue,
      'Plomería': Colors.cyan,
      'Electricidad': Colors.amber,
      'Carpintería': Colors.brown,
      'Pintura': Colors.purple,
      'Jardinería': Colors.green,
      'Tecnología': Colors.indigo,
      'Mecánica': Colors.grey,
      'Cocina': Colors.orange,
      'Tutorías': Colors.teal,
      'Belleza': Colors.pink,
      'Mudanzas': Colors.red,
    };
    
    return categoryColors[categoryName] ?? AppTheme.primaryColor;
  }

  String _getCategoryLabel(String categoryName) {
    final Map<String, String> categoryLabels = {
      'Limpieza': 'Popular',
      'Plomería': 'Urgente',
      'Electricidad': 'Especializada',
      'Carpintería': 'Artesanal',
      'Pintura': 'Creativa',
      'Jardinería': 'Exterior',
      'Tecnología': 'Moderna',
      'Mecánica': 'Técnica',
      'Cocina': 'Gourmet',
      'Tutorías': 'Educativa',
      'Belleza': 'Personal',
      'Mudanzas': 'Logística',
    };
    
    return categoryLabels[categoryName] ?? 'Servicio';
  }
} 