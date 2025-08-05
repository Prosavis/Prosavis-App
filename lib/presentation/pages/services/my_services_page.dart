import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/injection/injection_container.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/usecases/services/get_user_services_usecase.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/service_card.dart';
import 'category_services_page.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late final GetUserServicesUseCase _getUserServicesUseCase;
  List<ServiceEntity> _userServices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getUserServicesUseCase = sl<GetUserServicesUseCase>();
    _loadUserServices();
  }

  Future<void> _loadUserServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final services = await _getUserServicesUseCase(authState.user.id);
        setState(() {
          _userServices = services;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Usuario no autenticado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los servicios: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Mis servicios',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: Colors.black87),
            onPressed: () => context.push('/services/create'),
            tooltip: 'Crear nuevo servicio',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserServices,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserServices,
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        ),
      );
    }

    if (_userServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes servicios publicados',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer servicio para empezar a ofrecer tus habilidades',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/services/create'),
              icon: const Icon(Symbols.add),
              label: Text(
                'Crear mi primer servicio',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildServicesList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Symbols.work,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_userServices.length} servicio${_userServices.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Gestiona y edita tus ofertas de servicio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/services/create'),
            icon: const Icon(Symbols.add_circle_outline),
            tooltip: 'Agregar servicio',
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: _userServices.map((service) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ServiceCard(
          title: service.title,
          provider: service.providerName,
          price: service.price,
          rating: service.rating,
          imageUrl: service.images.isNotEmpty ? service.images.first : null,
          onTap: () => _viewServiceDetails(service),
          showEditButton: true,
          onEditPressed: () => _editService(service),
        ),
      )).toList(),
    );
  }

  void _editService(ServiceEntity service) {
    context.push('/services/edit/${service.id}');
  }

  void _viewServiceDetails(ServiceEntity service) {
    final serviceItem = _convertToServiceItem(service);
    context.push('/services/${service.id}', extra: serviceItem);
  }

  ServiceItem _convertToServiceItem(ServiceEntity service) {
    return ServiceItem(
      id: service.id,
      title: service.title,
      provider: service.providerName,
      price: service.price,
      rating: service.rating,
      imageUrl: service.images.isNotEmpty ? service.images.first : null,
      category: service.category,
      description: service.description,
      isAvailable: service.isActive,
      distance: 0.0, // Por defecto, se podría calcular si es necesario
    );
  }
}