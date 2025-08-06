import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/injection/injection_container.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/usecases/services/get_user_services_usecase.dart';
import '../../../domain/usecases/services/delete_service_usecase.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/service_card.dart';
import '../../widgets/common/profile_completion_dialog.dart';
import 'category_services_page.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late final GetUserServicesUseCase _getUserServicesUseCase;
  late final DeleteServiceUseCase _deleteServiceUseCase;
  List<ServiceEntity> _userServices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getUserServicesUseCase = sl<GetUserServicesUseCase>();
    _deleteServiceUseCase = sl<DeleteServiceUseCase>();
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

  /// Valida si el perfil está completo antes de crear un servicio
  void _validateProfileAndCreateService() {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      if (authState.user.isProfileComplete) {
        // El perfil está completo, permitir crear servicio
        context.push('/services/create');
      } else {
        // El perfil no está completo, mostrar diálogo
        ProfileCompletionDialog.show(context);
      }
    } else {
      // Usuario no autenticado (esto no debería ocurrir aquí)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debes estar autenticado para crear servicios',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, color: Colors.black87),
            onPressed: _validateProfileAndCreateService,
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
              onPressed: _validateProfileAndCreateService,
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
            onPressed: _validateProfileAndCreateService,
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
          service: service,
          onTap: () => _viewServiceDetails(service),
          showEditButton: true,
          onEditPressed: () => _editService(service),
          showDeleteButton: true,
          onDeletePressed: () => _deleteService(service),
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

  Future<void> _deleteService(ServiceEntity service) async {
    // Verificar que el usuario esté autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debes estar autenticado para eliminar servicios',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que el usuario sea el propietario del servicio
    if (authState.user.id != service.providerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solo puedes eliminar tus propios servicios',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar servicio',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${service.title}"? Esta acción no se puede deshacer.',
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
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Eliminando servicio...',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        // Eliminar el servicio
        await _deleteServiceUseCase(service.id);
        
        // Cerrar el diálogo de carga
        if (mounted) Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Servicio eliminado exitosamente',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Recargar la lista de servicios
        await _loadUserServices();
        
      } catch (e) {
        // Cerrar el diálogo de carga
        if (mounted) Navigator.of(context).pop();
        
        // Mostrar mensaje de error específico
        String errorMessage = 'Error desconocido';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'No tienes permisos para eliminar este servicio. Verifica que seas el propietario y que estés autenticado correctamente.';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'El servicio no existe o ya fue eliminado.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
        } else {
          errorMessage = 'Error al eliminar el servicio: ${e.toString()}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
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