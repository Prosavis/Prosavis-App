import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/service_entity.dart';
import 'optimized_image.dart';
import '../../../core/utils/location_utils.dart';


/// Widget constante para el placeholder de imagen por defecto
class _DefaultImagePlaceholder extends StatelessWidget {
  const _DefaultImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Symbols.image,
      size: 40,
      color: Colors.grey,
    );
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool isHorizontal;
  final VoidCallback? onTap;
  final bool enableHero;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final bool showDeleteButton;
  final VoidCallback? onDeletePressed;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  // Controla si la tarjeta vertical ocupa todo el ancho disponible
  // (útil para la pantalla de Mis servicios)
  final bool fullWidth;

  const ServiceCard({
    super.key,
    required this.service,
    this.isHorizontal = false,
    this.onTap,
    this.enableHero = true,
    this.showEditButton = false,
    this.onEditPressed,
    this.showDeleteButton = false,
    this.onDeletePressed,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.fullWidth = false,
  });

  /// Altura recomendada para listas horizontales de tarjetas verticales.
  ///
  /// Ajusta dinámicamente la altura base (220) considerando el `textScaleFactor`
  /// del dispositivo para evitar overflows en pantallas con fuentes grandes.
  static double preferredVerticalListHeight(BuildContext context) {
    const double baseHeight = 220.0;
    // Calcular factor real a partir del nuevo TextScaler
    final double textScale = MediaQuery.of(context).textScaler.scale(16.0) / 16.0;
    // Aumento suave en función del escalado de texto, limitado para no ocupar
    // espacio excesivo. Cubre casos de accesibilidad comunes (1.2–1.5).
    final double extra = (textScale - 1.0) * 56.0;
    final double safeExtra = extra <= 0
        ? 0.0
        : (extra > 80.0)
            ? 80.0
            : extra;
    return baseHeight + safeExtra;
  }

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildVerticalCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/services/${service.id}'),
      child: Container(
        width: fullWidth ? double.infinity : 180,
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            _buildContentSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/services/${service.id}'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildImageSection(context, isHorizontal: true),
            Expanded(child: _buildContentSection(context, isHorizontal: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, {bool isHorizontal = false}) {
    final Widget imageContent = Container(
      width: isHorizontal ? 120 : double.infinity,
      height: isHorizontal ? double.infinity : 120,
      decoration: BoxDecoration(
        borderRadius: isHorizontal
            ? const BorderRadius.horizontal(left: Radius.circular(16))
            : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: isHorizontal
                ? const BorderRadius.horizontal(left: Radius.circular(16))
                : const BorderRadius.vertical(top: Radius.circular(16)),
            child: service.mainImage != null
                ? OptimizedImage(
                    imageUrl: service.mainImage!,
                    width: isHorizontal ? 120 : double.infinity,
                    height: isHorizontal ? 120 : double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppTheme.getContainerColor(context),
                    child: const _DefaultImagePlaceholder(),
                  ),
          ),
          // Botón de favorito
          if (showFavoriteButton)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavoriteToggle,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorite ? Symbols.favorite : Symbols.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey[600],
                    size: 18,
                  ),
                ),
              ),
            ),
          // Botones de acción (eliminar izquierda, editar derecha)
          if (showDeleteButton)
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: onDeletePressed,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.delete,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          if (showEditButton)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onEditPressed,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!enableHero) return imageContent;
    return Hero(
      tag: 'service-image-${service.id}',
      child: Material(
        type: MaterialType.transparency,
        child: imageContent,
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, {bool isHorizontal = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isHorizontal 
            ? MainAxisAlignment.spaceBetween 
            : MainAxisAlignment.start,
        children: [
          // Título
          Text(
            service.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimary(context),
            ),
            maxLines: isHorizontal ? 2 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Proveedor
          Text(
            service.providerName,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.getTextSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (!isHorizontal) const SizedBox(height: 8),
          if (isHorizontal) const Spacer(),
          
          // Rating, distancia (si aplica) y precio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rating
              Row(
                children: [
                  const Icon(
                    Symbols.star,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    service.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  // Distancia (si se puede calcular)
                  _DistanceBadge(service: service),
                ],
              ),
              
              // Precio
              Text(
                _formatPrice(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice() {
    if (service.priceType == 'negotiable') {
      return 'Negociable';
    }
    
    final formattedPrice = service.price == service.price.roundToDouble()
        ? '\$${service.price.toInt()}'
        : '\$${service.price.toStringAsFixed(2)}';
    
    switch (service.priceType) {
      case 'hourly':
        return '$formattedPrice/h';
      case 'daily':
        return '$formattedPrice/día';
      case 'weekly':
        return '$formattedPrice/sem';
      case 'monthly':
        return '$formattedPrice/mes';
      default:
        return formattedPrice;
    }
  }
}

// Widget para mostrar cuando se requiere autenticación
class LoginRequiredWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginRequiredWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.login,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Symbols.login),
              label: const Text('Iniciar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final ServiceEntity service;

  const _DistanceBadge({required this.service});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? loc = service.location;
    if (loc == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String?>(
      future: LocationUtils.calculateDistanceToService(serviceLocation: loc),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final String? distanceText = snapshot.data;
        if (distanceText == null || distanceText.isEmpty) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '·',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.getTextTertiary(context),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              distanceText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}