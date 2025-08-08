import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';

enum ReviewRestrictionType {
  ownService,
  alreadyReviewed,
}

class ReviewRestrictionDialog extends StatelessWidget {
  final ReviewRestrictionType restrictionType;
  final String serviceName;
  final String? existingReviewComment;
  final double? existingReviewRating;

  const ReviewRestrictionDialog({
    super.key,
    required this.restrictionType,
    required this.serviceName,
    this.existingReviewComment,
    this.existingReviewRating,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildMessage(),
            if (restrictionType == ReviewRestrictionType.alreadyReviewed) ...[
              const SizedBox(height: 16),
              _buildExistingReview(),
            ],
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (restrictionType) {
      case ReviewRestrictionType.ownService:
        iconData = Symbols.block;
        iconColor = Colors.orange;
        break;
      case ReviewRestrictionType.alreadyReviewed:
        iconData = Symbols.check_circle;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 48,
        color: iconColor,
      ),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (restrictionType) {
      case ReviewRestrictionType.ownService:
        title = 'No puedes reseñar tu propio servicio';
        break;
      case ReviewRestrictionType.alreadyReviewed:
        title = 'Ya has reseñado este servicio';
        break;
    }

    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    String message;
    switch (restrictionType) {
      case ReviewRestrictionType.ownService:
        message = 'Para mantener la integridad del sistema de reseñas, '
                 'no puedes escribir reseñas sobre los servicios que tú ofreces. '
                 'Solo otros usuarios pueden evaluar tu trabajo.';
        break;
      case ReviewRestrictionType.alreadyReviewed:
        message = 'Ya has escrito una reseña para "$serviceName". '
                 'Solo se permite una reseña por usuario por servicio para '
                 'mantener la autenticidad de las valoraciones.';
        break;
    }

    return Text(
      message,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildExistingReview() {
    if (existingReviewComment == null || existingReviewRating == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu reseña actual:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  Symbols.star,
                  size: 16,
                  color: index < existingReviewRating!.round()
                      ? Colors.amber.shade600
                      : Colors.grey.shade300,
                  fill: index < existingReviewRating!.round() ? 1 : 0,
                );
              }),
              const SizedBox(width: 8),
              Text(
                existingReviewRating!.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            existingReviewComment!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Entendido',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
