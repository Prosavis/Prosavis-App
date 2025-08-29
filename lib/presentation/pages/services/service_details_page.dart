import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/favorites/favorites_event.dart';
import '../../blocs/favorites/favorites_state.dart';
import '../../widgets/common/service_card.dart' hide LoginRequiredWidget;
import '../../widgets/common/optimized_image.dart';
import '../../widgets/reviews/write_review_dialog.dart';
import '../../widgets/reviews/review_restriction_dialog.dart';
import '../../widgets/reviews/edit_review_dialog.dart';
import '../../widgets/reviews/delete_review_dialog.dart';
import '../../widgets/reviews/profile_completion_dialog.dart';
import '../../widgets/common/coming_soon_widget.dart' show LoginRequiredWidget;
// import '../../widgets/rating_stars.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/usecases/reviews/get_service_reviews_usecase.dart';
import '../../../domain/usecases/reviews/check_user_review_usecase.dart';
import '../../../domain/usecases/services/get_service_by_id_usecase.dart';
import '../../../domain/usecases/services/search_services_usecase.dart';
import '../../../core/injection/injection_container.dart';
import '../../widgets/reviews/review_card.dart';
import '../../blocs/review/review_bloc.dart';

import '../../../core/services/haptics_service.dart';

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

  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _scrollController = ScrollController();
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

  // Claves para hacer scroll a la sección de reseñas y al botón
  final GlobalKey _reviewsSectionKey = GlobalKey();
  final GlobalKey _addReviewButtonKey = GlobalKey();


  Future<void> _openInMaps() async {
    if (_currentService == null) return;
    Uri? uri;
    // Si hay coordenadas, priorizar lat/lng
    final loc = _currentService!.location;
    final double? lat = ((loc?['latitude'] ?? loc?['lat']) as num?)?.toDouble();
    final double? lng = ((loc?['longitude'] ?? loc?['lng'] ?? loc?['lon']) as num?)?.toDouble();
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (_currentService!.address != null && _currentService!.address!.isNotEmpty) {
      final q = Uri.encodeComponent(_currentService!.address!);
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _scrollToReviews({
    bool focusOnAddButton = true,
    bool openWriteDialog = false,
  }) async {
    final targetContext = (focusOnAddButton
            ? _addReviewButtonKey.currentContext
            : _reviewsSectionKey.currentContext) ??
        _reviewsSectionKey.currentContext;

    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    } else if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }

    if (!mounted) return;
    if (openWriteDialog) {
      // Breve retraso para asegurar que el scroll ha finalizado visualmente
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await _showAddReviewDialog();
    }
  }

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
      // Ejecutar operación de reseñas primero (prioritaria)
      final fetchedReviews = await _getServiceReviewsUseCase(GetServiceReviewsParams(
        serviceId: _currentService!.id,
        limit: 20,
      ));
      
      // Intentar recargar servicio actualizado (opcional, no crítico)
      ServiceEntity? fetchedService;
      try {
        fetchedService = await _getServiceByIdUseCase(_currentService!.id);
      } catch (serviceError) {
        // Error al recargar servicio (no crítico)
        fetchedService = null;
      }
      
      // TEMPORAL: Omitir enriquecimiento para evitar errores de permisos
      
      /*
      final reviewsNeedingPhoto = fetchedReviews
          .where((r) => r.userPhotoUrl == null || r.userPhotoUrl!.isEmpty)
          .toList();
      if (reviewsNeedingPhoto.isNotEmpty) {
        try {
          final firestoreService = FirestoreService();
          final uniqueUserIds = reviewsNeedingPhoto.map((r) => r.userId).toSet().toList();
          final users = await Future.wait(uniqueUserIds.map((id) => firestoreService.getUserById(id)));
          final userIdToPhoto = <String, String?>{};
          for (var i = 0; i < uniqueUserIds.length; i++) {
            userIdToPhoto[uniqueUserIds[i]] = users[i]?.photoUrl;
          }
          fetchedReviews = fetchedReviews
              .map((r) => (r.userPhotoUrl == null || r.userPhotoUrl!.isEmpty)
                  ? r.copyWith(userPhotoUrl: userIdToPhoto[r.userId])
                  : r)
              .toList();
        } catch (e) {
          // Error al enriquecer fotos, continuando sin fotos
          // Continuar con las reseñas sin fotos
        }
      }
      */

      if (mounted) {
        setState(() {
          _reviews = fetchedReviews;

          // Servicio retornado desde base de datos (puede no reflejar aún los agregados de CF)
          if (fetchedService != null) {
            _currentService = fetchedService;
          }

          // Fallback inmediato: calcular promedio y conteo local para reflejarlo en UI
          final localCount = _reviews.length;
          final localAvg = localCount == 0
              ? 0.0
              : _reviews
                  .map((r) => r.rating)
                  .fold<double>(0.0, (a, b) => a + b) /
                  localCount;

          final needsFallback = _currentService != null && (
            _currentService!.reviewCount != localCount ||
            (_currentService!.rating - localAvg).abs() > 0.01
          );

          if (needsFallback) {
            _currentService = _currentService!.copyWith(
              rating: localAvg,
              reviewCount: localCount,
            );

            // Programar relectura para cuando Cloud Function haya actualizado los agregados reales
            Future.delayed(const Duration(seconds: 2), () async {
              final refreshed = await _getServiceByIdUseCase(_currentService!.id);
              if (!mounted) return;
              if (refreshed != null) {
                // Evitar degradar la UI a 0.0/0 si el documento aún no refleja agregados
                final localCount2 = _reviews.length;
                final localAvg2 = localCount2 == 0
                    ? 0.0
                    : _reviews
                        .map((r) => r.rating)
                        .fold<double>(0.0, (a, b) => a + b) /
                        localCount2;

                final seemsStale = refreshed.reviewCount < localCount2 ||
                    (localCount2 > 0 && refreshed.reviewCount == 0) ||
                    (localCount2 > 0 && refreshed.rating == 0.0) ||
                    ((refreshed.rating - localAvg2).abs() > 0.01);

                setState(() {
                  _currentService = seemsStale
                      ? _currentService!.copyWith(
                          rating: localAvg2,
                          reviewCount: localCount2,
                        )
                      : refreshed;
                });
              }
            });
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
        
        // Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reseñas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Mostrar error si no se pudo cargar el servicio
    if (_currentService == null) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.getBackgroundColor(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Symbols.arrow_back, color: AppTheme.getTextPrimary(context)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
                'Servicio no encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El servicio que buscas no existe o ha sido eliminado',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: StretchingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
        ),
        bottomNavigationBar: _buildActionButtons(),
      );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.getSurfaceColor(context),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.arrow_back, color: AppTheme.getTextPrimary(context)),
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
                        color: AppTheme.getSurfaceColor(context).withValues(alpha: 0.9),
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
                              color: isFavorite ? Colors.red : AppTheme.getTextPrimary(context),
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
                    color: AppTheme.getSurfaceColor(context).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Symbols.favorite_border,
                    color: AppTheme.getTextPrimary(context),
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
              color: AppTheme.getSurfaceColor(context).withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.share, color: AppTheme.getTextPrimary(context)),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
        background: _currentService!.mainImage != null
            ? GestureDetector(
                onTap: () => _showMainImageFullScreen(),
                child: Hero(
                  tag: 'service-image-${_currentService!.id}',
                  child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                    // Mostrar imagen real si es una URL, o ícono si es simulada
                    _currentService!.mainImage!.startsWith('https://')
                        ? OptimizedImage(
                            imageUrl: _currentService!.mainImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            cacheWidth: 1080,
                            cacheHeight: 720,
                            placeholder: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            errorWidget: Center(
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
                                       color: AppTheme.getTextSecondary(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                    color: AppTheme.getTextSecondary(context),
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
        color: AppTheme.getSurfaceColor(context),
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
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Symbols.person,
                  size: 20,
                  color: AppTheme.getTextSecondary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentService!.providerName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (_currentService!.address != null || _calculatedDistance != null)
              Row(
                children: [
                  GestureDetector(
                    onTap: _openInMaps,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Symbols.location_on,
                      size: 20,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentService!.address != null)
                          GestureDetector(
                            onTap: _openInMaps,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              _currentService!.address!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.getTextSecondary(context),
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (_calculatedDistance != null)
                          Text(
                            '$_calculatedDistance de distancia',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.getTextTertiary(context),
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
                    // Estrellas + promedio: sigue abriendo el diálogo para agregar reseña
                    GestureDetector(
                      onTap: () => _scrollToReviews(openWriteDialog: true),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
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
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Separación más amplia del conteo de reseñas
                    const SizedBox(width: 12),
                    // Conteo de reseñas: abre el listado de todas las reseñas
                    GestureDetector(
                      onTap: _onReviewsCountTap,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        '(${_currentService!.reviewCount} reseñas)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.getTextSecondary(context),
                        ),
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
          color: AppTheme.getSurfaceColor(context),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Galería de trabajos',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
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
                      Icon(
                        Symbols.photo_library,
                        size: 32,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay fotos de trabajos disponibles',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.getTextTertiary(context),
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
        color: AppTheme.getSurfaceColor(context),
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
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
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
                  final bool isCurrent = _currentImageIndex == index;
                  return GestureDetector(
                    onTap: () => _showImageFullScreen(imageUrl, index),
                    child: AnimatedScale(
                      duration: AppConstants.mediumAnimation,
                      curve: Curves.easeOutCubic,
                      scale: isCurrent ? 1.0 : 0.94,
                      child: AnimatedOpacity(
                        duration: AppConstants.mediumAnimation,
                        opacity: isCurrent ? 1.0 : 0.7,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.getContainerColor(context),
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
                            child: Hero(
                              tag: 'gallery-image-${_currentService!.id}-$index',
                              child: imageUrl.startsWith('https://')
                                  ? OptimizedImage(
                                      imageUrl: imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      cacheWidth: 800,
                                      cacheHeight: 600,
                                      placeholder: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      errorWidget: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Symbols.broken_image,
                                              size: 32,
                                              color: AppTheme.getTextTertiary(context),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Error al cargar',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.getTextTertiary(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Symbols.image,
                                            size: 48,
                                            color: AppTheme.getTextTertiary(context),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Trabajo ${index + 1}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.getTextTertiary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
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
                  final bool isActive = _currentImageIndex == entry.key;
                  return AnimatedContainer(
                    duration: AppConstants.shortAnimation,
                    curve: Curves.easeOut,
                    width: isActive ? 10 : 8,
                    height: isActive ? 10 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
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
        color: AppTheme.getSurfaceColor(context),
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
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentService!.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
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
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getContainerColor(context, alpha: 1.0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.info,
                  size: 16,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'No se especificaron características adicionales',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.getTextTertiary(context),
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
            color: AppTheme.getTextPrimary(context),
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
                    color: AppTheme.getTextSecondary(context),
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
        color: AppTheme.getSurfaceColor(context),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.schedule,
                  size: 20,
                  color: AppTheme.getTextSecondary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Disponibilidad',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mostrar días disponibles como chips minimalistas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableDayNames.map((dayName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    dayName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
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
        color: AppTheme.getSurfaceColor(context),
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
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Hero(
                  tag: 'provider-avatar-${_currentService!.providerId}',
                  child: CircleAvatar(
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
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Miembro desde ${_currentService!.createdAt.year}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _scrollToReviews(openWriteDialog: true),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
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
                      ),
                      const SizedBox(height: 8),
                      _buildContactIconsRow(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactIconsRow() {
    final List<Widget> icons = [];

    void addIcon({required Widget child, required VoidCallback onTap}) {
      icons.add(GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getContainerColor(context, alpha: 1.0),
            border: Border.all(color: AppTheme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ));
    }

    if ((_currentService!.callPhones).isNotEmpty) {
      for (final phone in _currentService!.callPhones.take(2)) {
        addIcon(
          child: const Icon(Symbols.call, size: 18, color: AppTheme.primaryColor),
          onTap: () => _callPhone(phone),
        );
      }
    }

    if ((_currentService!.instagram ?? '').isNotEmpty) {
      addIcon(
        child: Image.asset(
          'assets/icons/social/instagram.webp',
          width: 18,
          height: 18,
          errorBuilder: (_, __, ___) => const Icon(Symbols.camera_alt, size: 18, color: AppTheme.primaryColor),
        ),
        onTap: _openInstagram,
      );
    }
    if ((_currentService!.xProfile ?? '').isNotEmpty) {
      addIcon(
        child: Image.asset(
          'assets/icons/social/x.png',
          width: 18,
          height: 18,
          errorBuilder: (_, __, ___) => const Icon(Symbols.alternate_email, size: 18, color: AppTheme.primaryColor),
        ),
        onTap: _openX,
      );
    }
    if ((_currentService!.tiktok ?? '').isNotEmpty) {
      addIcon(
        child: Image.asset(
          'assets/icons/social/tiktok.png',
          width: 18,
          height: 18,
          errorBuilder: (_, __, ___) => const Icon(Symbols.music_note, size: 18, color: AppTheme.primaryColor),
        ),
        onTap: _openTikTok,
      );
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Wrap(children: icons);
  }

  Widget _buildReviews() {
    return SliverToBoxAdapter(
      child: Container(
        key: _reviewsSectionKey,
        color: AppTheme.getSurfaceColor(context),
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
                color: AppTheme.getTextPrimary(context),
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
                  Icon(
                      Symbols.reviews,
                      size: 48,
                    color: AppTheme.getTextTertiary(context),
                    ),
                    const SizedBox(height: 12),
                  Text(
                      '¡Sé el primero en dejar una reseña!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                  Text(
                      'Tu opinión ayuda a otros usuarios',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                      color: AppTheme.getTextTertiary(context),
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
                key: _addReviewButtonKey,
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
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ReviewCard(
        review: review,
        isCompact: false, // Cambiar a false para mostrar botones de editar/eliminar
        currentUserId: currentUserId,
        onEdit: () => _showEditReviewDialog(review),
        onDelete: () => _showDeleteReviewDialog(review),
      ),
    );
  }

  Widget _buildSimilarServices() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.getSurfaceColor(context),
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
                color: AppTheme.getTextPrimary(context),
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
              Icon(
                Symbols.search_off,
                size: 32,
                color: AppTheme.getTextTertiary(context),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay servicios similares disponibles',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.getTextTertiary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Categoría: ${_currentService!.category}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.getTextTertiary(context),
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
      // Altura alineada con el tamaño real del ServiceCard vertical y adaptada
      // al factor de escala de texto para evitar overflows en algunos dispositivos
      height: ServiceCard.preferredVerticalListHeight(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _similarServices.length,
        itemBuilder: (context, index) {
          final service = _similarServices[index];
          return Container(
            // Ancho alineado con el ancho interno del ServiceCard
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: OpenContainer(
              transitionDuration: AppConstants.mediumAnimation,
              transitionType: ContainerTransitionType.fadeThrough,
              closedElevation: 0,
              closedColor: Colors.transparent,
              openBuilder: (context, _) => ServiceDetailsPage(service: service),
              closedBuilder: (context, openContainer) => ServiceCard(
                service: service,
                onTap: openContainer,
                enableHero: false,
              ),
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
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onWhatsAppPressed,
          icon: Image.asset(
            'assets/icons/social/whatsapp.webp',
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

  // String _formatDate(DateTime date) {
  //   final now = DateTime.now();
  //   final difference = now.difference(date);
  //   if (difference.inDays < 7) {
  //     return 'Hace \\${difference.inDays} días';
  //   } else if (difference.inDays < 30) {
  //     return 'Hace \\${(difference.inDays / 7).floor()} semanas';
  //   } else {
  //     return '\\${date.day}/\\${date.month}/\\${date.year}';
  //   }
  // }

  void _shareService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir próximamente')),
    );
  }

  void _onWhatsAppPressed() {
    HapticsService.onPrimaryAction();
    _contactProvider();
  }

  void _contactProvider() async {
    // Tomar número desde el servicio
    final String phoneNumber = _currentService!.whatsappNumber ?? '';
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este servicio no tiene número de WhatsApp configurado.'),
          ),
        );
      }
      return;
    }
    
    // Formatear para WhatsApp (57 + número sin +)
    final formattedNumber = Validators.formatForWhatsApp(phoneNumber);
    
    final message = Uri.encodeComponent(
      'Hola! Estoy interesado en tu servicio: ${_currentService!.title}. ¿Podrías darme más información?'
    );
    
    final whatsappUrl = 'https://wa.me/$formattedNumber?text=$message';
    final uri = Uri.parse(whatsappUrl);
    
    try {
      // Intentar abrir WhatsApp con múltiples métodos
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        final success = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        
        if (!success && mounted) {
          _showWhatsAppError('No se pudo abrir WhatsApp. Intenta instalarlo desde Google Play Store.');
        }
      } else {
        // Intentar con esquema alternativo para WhatsApp
        final whatsappUri = Uri.parse('whatsapp://send?phone=$formattedNumber&text=$message');
        final canLaunchWhatsapp = await canLaunchUrl(whatsappUri);
        
        if (canLaunchWhatsapp) {
          final success = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          if (!success && mounted) {
            _showWhatsAppError('No se pudo abrir WhatsApp. Verifica que esté instalado.');
          }
        } else {
          if (mounted) {
            _showWhatsAppError(
              'WhatsApp no está disponible. Por favor:\n'
              '1. Verifica que WhatsApp esté instalado\n'
              '2. Reinicia la aplicación\n'
              '3. Si el problema persiste, reinstala WhatsApp'
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showWhatsAppError('Error al intentar abrir WhatsApp: ${e.toString()}');
      }
    }
  }
  
  void _showWhatsAppError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: _contactProvider,
        ),
      ),
    );
  }

  void _callPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$digits');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al intentar llamar.')),
      );
    }
  }

  String _normalizeHandle(String raw) {
    var handle = raw.trim();
    if (handle.startsWith('http')) return handle;
    
    // Remover todos los símbolos @ (al principio, al final, o en medio)
    handle = handle.replaceAll('@', '');
    
    // Remover espacios extras después de limpiar
    handle = handle.trim();
    
    return handle;
  }

  Future<void> _openInstagram() async {
    final raw = _currentService!.instagram!;
    final handle = _normalizeHandle(raw);
    final webUrl = handle.startsWith('http') ? handle : 'https://instagram.com/$handle';
    
    try {
      // Intentar con aplicación nativa de Instagram primero
      final nativeUri = Uri.parse('instagram://user?username=$handle');
      final canLaunchNative = await canLaunchUrl(nativeUri);
      
      if (canLaunchNative) {
        final success = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (!success && mounted) {
          _showSocialMediaError('Instagram', 'No se pudo abrir la aplicación de Instagram.');
        }
      } else {
        // Fallback a versión web
        final webUri = Uri.parse(webUrl);
        final canLaunchWeb = await canLaunchUrl(webUri);
        
        if (canLaunchWeb) {
          final success = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          if (!success && mounted) {
            _showSocialMediaError('Instagram', 'No se pudo abrir Instagram en el navegador.');
          }
        } else {
          if (mounted) {
            _showSocialMediaError(
              'Instagram', 
              'Instagram no está disponible. Por favor verifica que esté instalado o intenta desde el navegador.'
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSocialMediaError('Instagram', 'Error al intentar abrir Instagram: ${e.toString()}');
      }
    }
  }

  Future<void> _openX() async {
    final raw = _currentService!.xProfile!;
    final handle = _normalizeHandle(raw);
    final webUrl = handle.startsWith('http') ? handle : 'https://x.com/$handle';
    
    try {
      // Intentar con aplicación nativa de X/Twitter primero
      final nativeUri = Uri.parse('twitter://user?screen_name=$handle');
      final canLaunchNative = await canLaunchUrl(nativeUri);
      
      if (canLaunchNative) {
        final success = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (!success && mounted) {
          _showSocialMediaError('X', 'No se pudo abrir la aplicación de X.');
        }
      } else {
        // Fallback a versión web
        final webUri = Uri.parse(webUrl);
        final canLaunchWeb = await canLaunchUrl(webUri);
        
        if (canLaunchWeb) {
          final success = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          if (!success && mounted) {
            _showSocialMediaError('X', 'No se pudo abrir X en el navegador.');
          }
        } else {
          if (mounted) {
            _showSocialMediaError(
              'X', 
              'X no está disponible. Por favor verifica que esté instalado o intenta desde el navegador.'
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSocialMediaError('X', 'Error al intentar abrir X: ${e.toString()}');
      }
    }
  }

  Future<void> _openTikTok() async {
    final raw = _currentService!.tiktok!;
    final handle = _normalizeHandle(raw);
    final webUrl = handle.startsWith('http') ? handle : 'https://www.tiktok.com/@$handle';
    
    try {
      // Intentar con aplicación nativa de TikTok primero
      final nativeUri = Uri.parse('tiktok://user?username=$handle');
      final canLaunchNative = await canLaunchUrl(nativeUri);
      
      if (canLaunchNative) {
        final success = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (!success && mounted) {
          _showSocialMediaError('TikTok', 'No se pudo abrir la aplicación de TikTok.');
        }
      } else {
        // Fallback a versión web
        final webUri = Uri.parse(webUrl);
        final canLaunchWeb = await canLaunchUrl(webUri);
        
        if (canLaunchWeb) {
          final success = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          if (!success && mounted) {
            _showSocialMediaError('TikTok', 'No se pudo abrir TikTok en el navegador.');
          }
        } else {
          if (mounted) {
            _showSocialMediaError(
              'TikTok', 
              'TikTok no está disponible. Por favor verifica que esté instalado o intenta desde el navegador.'
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSocialMediaError('TikTok', 'Error al intentar abrir TikTok: ${e.toString()}');
      }
    }
  }
  
  void _showSocialMediaError(String platform, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$platform: $message'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: () {
            switch (platform) {
              case 'Instagram':
                _openInstagram();
                break;
              case 'X':
                _openX();
                break;
              case 'TikTok':
                _openTikTok();
                break;
            }
          },
        ),
      ),
    );
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
                  Icon(
                          Symbols.reviews,
                          size: 48,
                    color: AppTheme.getTextTertiary(context),
                        ),
                        const SizedBox(height: 16),
                  Text(
                          'Aún no hay reseñas',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                      color: AppTheme.getTextSecondary(context),
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

  /// Valida si el perfil del usuario está completo para escribir reseñas
  /// Retorna una lista de campos faltantes
  List<String> _validateUserProfileForReview(UserEntity user) {
    final missingFields = <String>[];
    
    // Validar nombre (no puede estar vacío o ser solo espacios)
    if (user.name.trim().isEmpty) {
      missingFields.add('name');
    }
    
    // Validar email (no puede estar vacío)
    if (user.email.trim().isEmpty) {
      missingFields.add('email');
    }
    
    // Validar teléfono (debe estar presente)
    if (user.phoneNumber == null || user.phoneNumber!.trim().isEmpty) {
      missingFields.add('phoneNumber');
    }
    
    return missingFields;
  }

  /// Muestra el diálogo de perfil incompleto
  void _showProfileCompletionDialog(List<String> missingFields) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProfileCompletionDialog(
          missingFields: missingFields,
          onEditProfile: () {
            // Navegar a la página de edición de perfil
            context.push('/profile/edit');
          },
        );
      },
    );
  }

  Future<void> _onReviewsCountTap() async {
    // Desplaza a la sección de reseñas y abre el listado completo
    await _scrollToReviews(focusOnAddButton: false, openWriteDialog: false);
    if (!mounted) return;
    // Pequeño retraso para que el scroll termine visualmente
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _viewAllReviews();
  }

  Future<void> _showAddReviewDialog() async {
    // Verificar si el usuario está autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    final currentUser = authState.user;

    // Verificar si el perfil está completo
    final missingFields = _validateUserProfileForReview(currentUser);
    if (missingFields.isNotEmpty) {
      _showProfileCompletionDialog(missingFields);
      return;
    }

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
          return BlocProvider.value(
            value: context.read<ReviewBloc>(),
            child: WriteReviewDialog(
              serviceId: _currentService!.id,
              serviceName: _currentService!.title,
              onReviewCreated: _loadReviews, // Recargar reseñas cuando se cree una nueva
            ),
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
                style: GoogleFonts.inter(color: AppTheme.getTextSecondary(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                  // Navegar inmediatamente a la pantalla de login
                  context.push('/login');
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

  Future<void> _showEditReviewDialog(ReviewEntity review) async {
    if (_currentService == null) return;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: context.read<ReviewBloc>(),
          child: EditReviewDialog(
            review: review,
            serviceName: _currentService!.title,
            onReviewUpdated: _loadReviews, // Recargar reseñas cuando se actualice
          ),
        );
      },
    );
  }

  Future<void> _showDeleteReviewDialog(ReviewEntity review) async {
    if (_currentService == null) return;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: context.read<ReviewBloc>(),
          child: DeleteReviewDialog(
            review: review,
            serviceName: _currentService!.title,
            onReviewDeleted: _loadReviews, // Recargar reseñas cuando se elimine
          ),
        );
      },
    );
  }



  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
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
                child: OptimizedImage(
                  imageUrl: mainImageUrl,
                  fit: BoxFit.contain,
                  cacheWidth: 1200,
                  cacheHeight: 900,
                  errorWidget: Center(
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
                  ),
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
                child: Hero(
                  tag: 'gallery-image-${_currentService!.id}-$initialIndex',
                  child: OptimizedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    cacheWidth: 1200,
                    cacheHeight: 900,
                    placeholder: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: Center(
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
                    ),
                  ),
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

 