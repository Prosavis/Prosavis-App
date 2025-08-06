import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/service_entity.dart';
import 'optimized_image.dart';

class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool isHorizontal;
  final VoidCallback? onTap;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final bool showDeleteButton;
  final VoidCallback? onDeletePressed;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ServiceCard({
    super.key,
    required this.service,
    this.isHorizontal = false,
    this.onTap,
    this.showEditButton = false,
    this.onEditPressed,
    this.showDeleteButton = false,
    this.onDeletePressed,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

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
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildContentSection(),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildImageSection(isHorizontal: true),
            Expanded(child: _buildContentSection(isHorizontal: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({bool isHorizontal = false}) {
    return Container(
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
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Symbols.image,
                      size: 40,
                      color: Colors.grey,
                    ),
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
                    color: Colors.white.withValues(alpha: 0.9),
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
          // Botones de acción (editar/eliminar)
          if (showEditButton || showDeleteButton)
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  if (showEditButton)
                    GestureDetector(
                      onTap: onEditPressed,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Symbols.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (showEditButton && showDeleteButton)
                    const SizedBox(width: 8),
                  if (showDeleteButton)
                    GestureDetector(
                      onTap: onDeletePressed,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Symbols.delete,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection({bool isHorizontal = false}) {
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
              color: AppTheme.textPrimary,
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
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (!isHorizontal) const SizedBox(height: 8),
          if (isHorizontal) const Spacer(),
          
          // Rating y precio
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
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              
              // Precio
              Text(
                _formatPrice(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
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