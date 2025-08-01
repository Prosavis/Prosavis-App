import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    
    _tabController = TabController(length: 2, vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFavoritesTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.getContainerColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.getTextSecondary(context),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Symbols.favorite, size: 20),
            text: 'Servicios',
          ),
          Tab(
            icon: Icon(Symbols.history, size: 20),
            text: 'Historial',
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    // Mock data de servicios favoritos
    final List<Map<String, dynamic>> favoriteServices = [
      // Lista vacía para mostrar estado vacío inicialmente
    ];

    if (favoriteServices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
              'Aún no tienes servicios favoritos',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Marca como favoritos los servicios que te interesen para encontrarlos fácilmente después.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a inicio para explorar servicios
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Symbols.search),
              label: Text(
                'Explorar Servicios',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: favoriteServices.length,
      itemBuilder: (context, index) {
        final service = favoriteServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                Symbols.home_repair_service,
                color: Colors.white,
              ),
            ),
            title: Text(
              service['title'] ?? 'Servicio',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              service['provider'] ?? 'Proveedor',
              style: GoogleFonts.inter(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                // Remover de favoritos
              },
              icon: const Icon(
                Symbols.favorite,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    // Mock data de historial de servicios contactados
    final List<Map<String, dynamic>> serviceHistory = [
      {
        'title': 'Limpieza de hogar',
        'provider': 'María García',
        'date': '15 Dic 2024',
        'status': 'Completado'
      },
      {
        'title': 'Reparación plomería',
        'provider': 'Carlos López',
        'date': '10 Dic 2024',
        'status': 'En progreso'
      },
      {
        'title': 'Corte de cabello',
        'provider': 'Salón Bella',
        'date': '5 Dic 2024',
        'status': 'Completado'
      },
    ];

    if (serviceHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.history,
              size: 80,
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes historial de servicios',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Aquí aparecerán los servicios que hayas contactado.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: serviceHistory.length,
      itemBuilder: (context, index) {
        final service = serviceHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(service['status']),
              child: Icon(
                _getStatusIcon(service['status']),
                color: Colors.white,
              ),
            ),
            title: Text(
              service['title'] ?? 'Servicio',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['provider'] ?? 'Proveedor',
                  style: GoogleFonts.inter(
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      service['date'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.getTextTertiary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(service['status']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service['status'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(service['status']),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () {
              // Mostrar detalles del servicio contactado
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'en progreso':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return Symbols.check_circle;
      case 'en progreso':
        return Symbols.schedule;
      case 'cancelado':
        return Symbols.cancel;
      default:
        return Symbols.circle;
    }
  }
}