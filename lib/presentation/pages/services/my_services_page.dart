import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/injection/injection_container.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/service_refresh_notifier.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/usecases/services/get_user_services_usecase.dart';
import '../../../domain/usecases/services/delete_service_usecase.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/service_card.dart';
import '../../widgets/common/profile_completion_dialog.dart';
import '../../../domain/usecases/reviews/get_service_review_stats_usecase.dart';


class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late final GetUserServicesUseCase _getUserServicesUseCase;
  late final DeleteServiceUseCase _deleteServiceUseCase;
  late final ServiceRefreshNotifier _serviceRefreshNotifier;
  late final GetServiceReviewStatsUseCase _getServiceReviewStatsUseCase;
  List<ServiceEntity> _userServices = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasLoadedOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getUserServicesUseCase = sl<GetUserServicesUseCase>();
    _deleteServiceUseCase = sl<DeleteServiceUseCase>();
    _serviceRefreshNotifier = ServiceRefreshNotifier();
    _getServiceReviewStatsUseCase = sl<GetServiceReviewStatsUseCase>();
    
    // Escuchar notificaciones de cambios en servicios
    _serviceRefreshNotifier.addListener(_onServicesChanged);
    
    _loadUserServices();
  }

  @override
  void dispose() {
    _serviceRefreshNotifier.removeListener(_onServicesChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Callback que se ejecuta cuando se notifica un cambio en servicios
  void _onServicesChanged() {
    if (mounted) {
      _forceReload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recargar servicios cuando la app vuelva al primer plano
    if (state == AppLifecycleState.resumed) {
      _forceReload();
    }
  }

  @override
  void didUpdateWidget(MyServicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar servicios cuando la página se actualice
    _forceReload();
  }

  /// Fuerza la recarga de servicios, útil cuando sabemos que hay cambios
  void _forceReload() {
    if (!mounted) return;
    _hasLoadedOnce = false;
    _loadUserServices();
  }

  Future<void> _loadUserServices() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        var services = await _getUserServicesUseCase(authState.user.id);

        // Ajustar rating localmente si el doc aún no refleja agregados
        services = await Future.wait(services.map((s) async {
          final stats = await _getServiceReviewStatsUseCase(s.id);
          final total = (stats['totalReviews'] ?? 0) as int;
          final avg = (stats['averageRating'] ?? 0.0).toDouble();
          if (total == 0) return s;
          if (s.reviewCount == 0 && total > 0) {
            return s.copyWith(rating: avg, reviewCount: total);
          }
          return s;
        }));
        if (mounted) {
          setState(() {
            _userServices = services;
            _isLoading = false;
            _hasLoadedOnce = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Usuario no autenticado';
            _isLoading = false;
            _hasLoadedOnce = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar los servicios: $e';
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Solo recargar si es la primera vez o si específicamente se necesita
    if (!_hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserServices();
          _hasLoadedOnce = true;
        }
      });
    }
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Mis servicios',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: _validateProfileAndCreateService,
            tooltip: 'Crear nuevo servicio',
          ),
        ],
      ),
      body: StretchingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        child: RefreshIndicator(
          onRefresh: _loadUserServices,
          child: _buildBody(),
        ),
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
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
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
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes servicios publicados',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer servicio para empezar a ofrecer tus habilidades',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
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
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                Text(
                  'Gestiona y edita tus ofertas de servicio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
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
          fullWidth: true,
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
    context.push('/services/${service.id}', extra: service);
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
              color: AppTheme.getSurfaceColor(context),
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
        
        // Notificar cambios y recargar la lista de servicios
        ServiceRefreshNotifier().notifyServicesChanged();
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


}