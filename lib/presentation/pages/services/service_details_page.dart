import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/location_utils.dart';
import '../../../domain/entities/service_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/favorites/favorites_event.dart';
import '../../blocs/favorites/favorites_state.dart';
import '../../widgets/common/service_card.dart';
import '../../widgets/reviews/write_review_dialog.dart';
import '../../widgets/reviews/review_restriction_dialog.dart';
import '../../widgets/rating_stars.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/usecases/reviews/get_service_reviews_usecase.dart';
import '../../../domain/usecases/reviews/check_user_review_usecase.dart';
import '../../../domain/usecases/services/get_service_by_id_usecase.dart';
import '../../../domain/usecases/services/search_services_usecase.dart';
import '../../../core/injection/injection_container.dart';

class ServiceDetailsPage extends StatefulWidget {
  final ServiceEntity? service;
  final String? serviceId;

  const ServiceDetailsPage({
    super.key,
    this.service,
    this.serviceId,
  }) : assert(service != null || serviceId != null, 'Either service or serviceId must be provided');

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  String? _calculatedDistance;



  List<ReviewEntity> _reviews = []; // Las reseñas se cargarán dinámicamente
  List<ServiceEntity> _similarServices = []; // Servicios similares
  late final GetServiceReviewsUseCase _getServiceReviewsUseCase;
  late final GetServiceByIdUseCase _getServiceByIdUseCase;
  late final CheckUserReviewUseCase _checkUserReviewUseCase;
  late final SearchServicesUseCase _searchServicesUseCase;
  
  ServiceEntity? _currentService;
  bool _isLoadingService = false;
  bool _isUpdatingRating = false;
  bool _isLoadingSimilarServices = false;

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

    // Inicializar casos de uso
    _getServiceReviewsUseCase = sl<GetServiceReviewsUseCase>();
    _getServiceByIdUseCase = sl<GetServiceByIdUseCase>();
    _checkUserReviewUseCase = sl<CheckUserReviewUseCase>();
    _searchServicesUseCase = sl<SearchServicesUseCase>();

    // Inicializar servicio
    _initializeService();
    _fadeController.forward();
  }

  Future<void> _initializeService() async {
    if (widget.service != null) {
      // Si ya tenemos el servicio, usarlo directamente
      _currentService = widget.service;
      // Ejecutar operaciones en paralelo para mejor rendimiento
      await Future.wait([
        _calculateDistance(),
        _loadReviews(),
        _loadSimilarServices(),
      ]);
    } else if (widget.serviceId != null) {
      // Cargar servicio por ID
      setState(() {
        _isLoadingService = true;
      });
      
      try {
        final service = await _getServiceByIdUseCase(widget.serviceId!);
        if (mounted) {
          setState(() {
            _currentService = service;
            _isLoadingService = false;
          });
          
          if (service != null) {
            // Ejecutar operaciones en paralelo para mejor rendimiento
            await Future.wait([
              _calculateDistance(),
              _loadReviews(),
              _loadSimilarServices(),
            ]);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingService = false;
          });
        }
      }
    }
  }

  Future<void> _loadReviews() async {
    if (_currentService == null) return;
    
    setState(() {
      _isUpdatingRating = true;
    });
    
    try {
      // Ejecutar ambas operaciones en paralelo para mejor rendimiento
      final results = await Future.wait([
        _getServiceReviewsUseCase(GetServiceReviewsParams(
          serviceId: _currentService!.id,
          limit: 20,
        )),
        _getServiceByIdUseCase(_currentService!.id), // Recargar servicio actualizado
      ]);
      
      if (mounted) {
        setState(() {
          _reviews = results[0] as List<ReviewEntity>;
          // Actualizar servicio con rating y reviewCount actualizados
          if (results[1] != null) {
            _currentService = results[1] as ServiceEntity;
          }
          _isUpdatingRating = false;
        });
      }
    } catch (e) {
      // En caso de error, mantener lista vacía
      if (mounted) {
        setState(() {
          _reviews = [];
          _isUpdatingRating = false;
        });
      }
    }
  }

  Future<void> _calculateDistance() async {
    if (_currentService == null) return;
    
    final distance = await LocationUtils.calculateDistanceToService(
      serviceLocation: _currentService!.location,
    );
    
    if (mounted) {
      setState(() {
        _calculatedDistance = distance;
      });
    }
  }

  Future<void> _loadSimilarServices() async {
    if (_currentService == null) return;

    setState(() {
      _isLoadingSimilarServices = true;
    });

    try {
      // Debug: Buscando servicios similares de categoría
      
      final services = await _searchServicesUseCase(
        SearchServicesParams(
          category: _currentService!.category,
          limit: 10, // Cargar máximo 10 servicios similares
        ),
      );

      // Filtrar el servicio actual de los resultados
      final filteredServices = services
          .where((service) => service.id != _currentService!.id)
          .take(6) // Mostrar máximo 6 servicios similares
          .toList();

      if (mounted) {
        setState(() {
          _similarServices = filteredServices;
          _isLoadingSimilarServices = false;
        });
        // Debug: Servicios similares cargados: ${filteredServices.length}
      }
    } catch (e) {
      // Error al cargar servicios similares: $e
      if (mounted) {
        setState(() {
          _similarServices = [];
          _isLoadingSimilarServices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cargar estado inicial de favorito si el usuario está autenticado y el servicio está cargado
    if (_currentService != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<FavoritesBloc>().add(CheckFavoriteStatus(
            userId: authState.user.id,
            serviceId: _currentService!.id,
          ));
        }
      });
    }

    // Mostrar loading si se está cargando el servicio
    if (_isLoadingService) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Mostrar error si no se pudo cargar el servicio
    if (_currentService == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.error_outline,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              SizedBox(height: 16),
              Text(
                'Servicio no encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'El servicio que buscas no existe o ha sido eliminado',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildServiceInfo(),
              _buildImageGallery(),
              _buildDescription(),
              _buildAvailability(),
              _buildProviderInfo(),
              _buildReviews(),
              _buildSimilarServices(),
            ],
          ),
        ),
        bottomNavigationBar: _buildActionButtons(),
      );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
        ),
      ),
      actions: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              return BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, favoritesState) {
                  bool isFavorite = false;
                  bool isLoading = false;
                  
                  if (favoritesState is FavoritesLoaded) {
                    isFavorite = favoritesState.isFavorite(_currentService!.id);
                  } else if (favoritesState is FavoriteToggling && 
                            favoritesState.serviceId == _currentService!.id) {
                    isLoading = true;
                    isFavorite = favoritesState.favoriteStatus[_currentService!.id] ?? false;
                  }
                  
                  return IconButton(
                    onPressed: isLoading ? null : () {
                      context.read<FavoritesBloc>().add(
                        ToggleFavorite(
                          userId: authState.user.id,
                          serviceId: _currentService!.id,
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : Icon(
                              isFavorite ? Symbols.favorite : Symbols.favorite_border,
                              color: isFavorite ? Colors.red : AppTheme.textPrimary,
                            ),
                    ),
                  );
                },
              );
            } else {
              return IconButton(
                onPressed: () {
                  _showLoginRequiredDialog();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.favorite_border,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            }
          },
        ),
        IconButton(
          onPressed: _shareService,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.share, color: AppTheme.textPrimary),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _currentService!.mainImage != null
            ? GestureDetector(
                onTap: () => _showMainImageFullScreen(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                    // Mostrar imagen real si es una URL, o ícono si es simulada
                    _currentService!.mainImage!.startsWith('https://')
                        ? Image.network(
                            _currentService!.mainImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppTheme.primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Symbols.broken_image,
                                      size: 48,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error al cargar imagen',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Symbols.camera_alt,
                                  size: 48,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Imagen principal (simulación)',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    // Overlay para mejorar legibilidad de los botones
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Symbols.work,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentService!.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentService!.isActive ? 'Disponible' : 'No disponible',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentService!.category,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _currentService!.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(
                  Symbols.person,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentService!.providerName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (_currentService!.address != null || _calculatedDistance != null)
              Row(
                children: [
                  const Icon(
                    Symbols.location_on,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentService!.address != null)
                          Text(
                            _currentService!.address!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_calculatedDistance != null)
                          Text(
                            '$_calculatedDistance de distancia',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Symbols.star,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentService!.rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_currentService!.reviewCount} reseñas)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (_isUpdatingRating) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                Text(
                  '\$${_currentService!.price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final galleryImages = _currentService!.images;
    
    if (galleryImages.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Galería de trabajos',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Symbols.photo_library,
                        size: 32,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay fotos de trabajos disponibles',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              child: Text(
                'Galería de trabajos',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemCount: galleryImages.length,
                itemBuilder: (context, index) {
                  final imageUrl = galleryImages[index];
                  return GestureDetector(
                    onTap: () => _showImageFullScreen(imageUrl, index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.startsWith('https://')
                            ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppTheme.primaryColor,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Symbols.broken_image,
                                        size: 32,
                                        color: AppTheme.textTertiary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error al cargar',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Symbols.image,
                                    size: 48,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Trabajo ${index + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (galleryImages.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: galleryImages.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción del servicio',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentService!.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceFeatures() {
    final features = _currentService!.features;

    if (features.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incluye:',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Symbols.info,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'No se especificaron características adicionales',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incluye:',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: const Icon(
                  Symbols.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildAvailability() {
    // Debug: Información de disponibilidad
    // Días disponibles cargados: ${_currentService!.availableDays}
    
    if (_currentService!.availableDays.isEmpty) {
      // No hay días disponibles configurados para este servicio
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Mapeo de días completos en español
    const Map<String, String> dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
      // También manejar días que ya estén en español (compatibilidad)
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miércoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sábado': 'Sábado',
      'domingo': 'Domingo',
    };

    // Convertir días disponibles a nombres completos
    final availableDayNames = _currentService!.availableDays
        .map((day) => dayNames[day.toLowerCase()] ?? day)
        .toList();

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Symbols.schedule,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Disponibilidad',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mostrar días disponibles en lista
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: availableDayNames.map((dayName) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dayName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sobre el proveedor',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  backgroundImage: _currentService!.providerPhotoUrl != null 
                      ? NetworkImage(_currentService!.providerPhotoUrl!)
                      : null,
                  child: _currentService!.providerPhotoUrl == null
                      ? Text(
                          _currentService!.providerName[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentService!.providerName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Miembro desde ${_currentService!.createdAt.year}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Symbols.star,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentService!.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _contactProvider,
                  child: Text(
                    'Contactar',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviews() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Reseñas',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_reviews.isNotEmpty)
                  TextButton(
                    onPressed: _viewAllReviews,
                    child: Text(
                      'Ver todas',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Symbols.reviews,
                      size: 48,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡Sé el primero en dejar una reseña!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu opinión ayuda a otros usuarios',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._reviews.take(2).map((review) => _buildReviewItem(review)),
            
            const SizedBox(height: 16),
            
            // Botón para agregar reseña
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Symbols.rate_review, size: 18),
                label: Text(
                  'Agregar reseña',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(ReviewEntity review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        RatingStars(
                          rating: review.rating,
                          size: 14,
                          color: Colors.amber.shade600,
                          unratedColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarServices() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servicios similares',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mostrar servicios similares o estado de carga
            _buildSimilarServicesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarServicesContent() {
    if (_isLoadingSimilarServices) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }
    
    if (_similarServices.isEmpty) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.search_off,
                size: 32,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 8),
              Text(
                'No hay servicios similares disponibles',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Categoría: ${_currentService!.category}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Mostrar lista horizontal de servicios similares
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _similarServices.length,
        itemBuilder: (context, index) {
          final service = _similarServices[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: ServiceCard(
              service: service,
              onTap: () {
                // Navegar al detalle del servicio similar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsPage(
                      service: service,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _contactProvider,
          icon: Image.asset(
            'assets/icons/WhatsApp.svg.webp',
            height: 20,
            width: 20,
            errorBuilder: (_, __, ___) => const Icon(Symbols.chat, color: Colors.white),
          ),
          label: Text(
            'Contactar por WhatsApp',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // WhatsApp green
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      return 'Hace ${(difference.inDays / 7).floor()} semanas';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _shareService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir próximamente')),
    );
  }

  void _contactProvider() async {
    // Número de teléfono del proveedor (simulado por ahora)
    const phoneNumber = '+573001234567'; // Número colombiano simulado
    final message = Uri.encodeComponent(
      'Hola! Estoy interesado en tu servicio: ${_currentService!.title}. ¿Podrías darme más información?'
    );
    
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$message';
    final uri = Uri.parse(whatsappUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp. Asegúrate de tenerlo instalado.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al intentar abrir WhatsApp.'),
          ),
        );
      }
    }
  }



  void _viewAllReviews() {
    // Implementar navegación a página de todas las reseñas
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Todas las reseñas',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _reviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Symbols.reviews,
                          size: 48,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay reseñas',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      return _buildReviewItem(_reviews[index]);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddReviewDialog() async {
    // Verificar si el usuario está autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    final currentUser = authState.user;

    // Verificar si es su propio servicio
    if (_currentService!.providerId == currentUser.id) {
      _showReviewRestrictionDialog(
        ReviewRestrictionType.ownService,
        _currentService!.title,
      );
      return;
    }

    // Verificar si ya tiene una reseña
    try {
      final existingReview = await _checkUserReviewUseCase(
        CheckUserReviewParams(
          serviceId: _currentService!.id,
          userId: currentUser.id,
        ),
      );

      if (!mounted) return; // Verificar si el widget sigue montado

      if (existingReview != null) {
        _showReviewRestrictionDialog(
          ReviewRestrictionType.alreadyReviewed,
          _currentService!.title,
          existingReviewComment: existingReview.comment,
          existingReviewRating: existingReview.rating,
        );
        return;
      }

      // Si pasa todas las validaciones, mostrar el diálogo de escribir reseña
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WriteReviewDialog(
            serviceId: _currentService!.id,
            serviceName: _currentService!.title,
            onReviewCreated: _loadReviews, // Recargar reseñas cuando se cree una nueva
          );
        },
      );
    } catch (e) {
      // En caso de error, mostrar mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar permisos de reseña: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReviewRestrictionDialog(
    ReviewRestrictionType restrictionType,
    String serviceName, {
    String? existingReviewComment,
    double? existingReviewRating,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReviewRestrictionDialog(
          restrictionType: restrictionType,
          serviceName: serviceName,
          existingReviewComment: existingReviewComment,
          existingReviewRating: existingReviewRating,
        );
      },
    );
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Inicio de sesión requerido',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Para agregar una reseña necesitas iniciar sesión o crear una cuenta.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                  // Navegar a página de login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegación a login próximamente')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Iniciar sesión',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }



  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const LoginRequiredWidget(
          title: 'Inicia sesión para guardar favoritos',
          subtitle: 'Necesitas tener una cuenta para guardar servicios como favoritos.',
        ),
      ),
    );
  }

  /// Muestra la imagen principal en pantalla completa
  void _showMainImageFullScreen() {
    if (_currentService?.mainImage == null) return;
    
    final mainImageUrl = _currentService!.mainImage!;
    
    if (!mainImageUrl.startsWith('https://')) {
      // Si no es una URL válida, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta imagen principal no está disponible para visualizar',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Imagen en pantalla completa
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  mainImageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Symbols.broken_image,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar la imagen',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Botón cerrar
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Indicador de imagen principal
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Imagen principal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra una imagen en pantalla completa con navegación entre imágenes
  void _showImageFullScreen(String imageUrl, int initialIndex) {
    if (!imageUrl.startsWith('https://')) {
      // Si no es una URL válida, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta imagen no está disponible para visualizar',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Imagen en pantalla completa
            Center(
              child: InteractiveViewer(
                maxScale: 3.0,
                minScale: 0.5,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Symbols.broken_image,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar imagen',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Botón de cerrar
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Indicador de imagen actual si hay múltiples imágenes
            if (_currentService!.images.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${initialIndex + 1} de ${_currentService!.images.length}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

 