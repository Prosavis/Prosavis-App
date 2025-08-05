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

class ServiceDetailsPage extends StatefulWidget {
  final ServiceEntity service;

  const ServiceDetailsPage({
    super.key,
    required this.service,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isFavorite = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  String? _calculatedDistance;



  List<Review> _reviews = []; // Las reseñas se cargarán dinámicamente

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

    _calculateDistance();
    _loadReviews();
    _fadeController.forward();
  }

  Future<void> _loadReviews() async {
    // Implementar carga real de reseñas desde Firestore
    // Por ahora mantenemos la lista vacía para mostrar estado coherente
    setState(() {
      _reviews = [];
    });
  }

  Future<void> _calculateDistance() async {
    final distance = await LocationUtils.calculateDistanceToService(
      serviceLocation: widget.service.location,
    );
    
    if (mounted) {
      setState(() {
        _calculatedDistance = distance;
      });
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
                      decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.arrow_back, color: AppTheme.textPrimary),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Symbols.favorite : Symbols.favorite_border,
              color: _isFavorite ? Colors.red : AppTheme.textPrimary,
            ),
          ),
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
        background: widget.service.mainImage != null
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Mostrar imagen real si es una URL, o ícono si es simulada
                    widget.service.mainImage!.startsWith('https://')
                        ? Image.network(
                            widget.service.mainImage!,
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
                    color: widget.service.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.service.isActive ? 'Disponible' : 'No disponible',
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
                    widget.service.category,
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
              widget.service.title,
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
                  widget.service.providerName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (widget.service.address != null || _calculatedDistance != null)
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
                        if (widget.service.address != null)
                          Text(
                            widget.service.address!,
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
                      widget.service.rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${widget.service.reviewCount} reseñas)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '\$${widget.service.price.toStringAsFixed(0)}',
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
    final galleryImages = widget.service.images;
    
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
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: Center(
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
              widget.service.description,
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
    final features = widget.service.features;

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
                  backgroundImage: widget.service.providerPhotoUrl != null 
                      ? NetworkImage(widget.service.providerPhotoUrl!)
                      : null,
                  child: widget.service.providerPhotoUrl == null
                      ? Text(
                          widget.service.providerName[0].toUpperCase(),
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
                        widget.service.providerName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Miembro desde ${widget.service.createdAt.year}',
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
                            widget.service.rating.toStringAsFixed(1),
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

  Widget _buildReviewItem(Review review) {
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
                  review.name[0].toUpperCase(),
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
                      review.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating.floor()
                                ? Symbols.star
                                : Symbols.star_outline,
                            size: 14,
                            color: Colors.orange,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.date),
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
            
            // Implementar carga real de servicios similares desde Firestore
            Container(
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
                      'Categoría: ${widget.service.category}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                        fontStyle: FontStyle.italic,
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
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '💬',
                style: GoogleFonts.inter(fontSize: 18),
              ),
              const SizedBox(width: 4),
            ],
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
      'Hola! Estoy interesado en tu servicio: ${widget.service.title}. ¿Podrías darme más información?'
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

  void _showAddReviewDialog() {
    // Verificar si el usuario está autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Agregar reseña',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Califica tu experiencia con este servicio',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de estrellas
                  Text(
                    'Calificación',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = (index + 1).toDouble();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            index < rating ? Symbols.star : Symbols.star_outline,
                            size: 32,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo de comentario
                  TextFormField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (opcional)',
                      hintText: 'Comparte tu experiencia...',
                      prefixIcon: Icon(Symbols.comment),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                ],
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
                    _submitReview(rating, commentController.text.trim());
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Publicar reseña',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
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
                Navigator.of(context).pop();
                // Navegar a página de login
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navegación a login próximamente')),
                );
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

  void _submitReview(double rating, String comment) {
    // Implementar envío real de reseña a Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reseña de ${rating.toInt()} estrella${rating > 1 ? 's' : ''} enviada'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class Review {
  final String name;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
  });
} 