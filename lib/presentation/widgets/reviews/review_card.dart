import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/review_entity.dart';
import '../../../core/themes/app_theme.dart';
import '../rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final bool isCompact;

  const ReviewCard({
    super.key,
    required this.review,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (!isCompact) ...[
            const SizedBox(height: 12),
            _buildRating(),
            const SizedBox(height: 8),
            _buildComment(),
            const SizedBox(height: 8),
            _buildTimestamp(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: isCompact ? 16 : 20,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          backgroundImage: review.userPhotoUrl != null 
              ? NetworkImage(review.userPhotoUrl!)
              : null,
          child: review.userPhotoUrl == null
              ? Icon(
                  Symbols.person,
                  size: isCompact ? 16 : 20,
                  color: AppTheme.primaryColor,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName,
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (isCompact) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingStars(
                      rating: review.rating,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM yyyy').format(review.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    review.comment,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        RatingStars(
          rating: review.rating,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '(${review.rating.toStringAsFixed(1)})',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildComment() {
    if (review.comment.isEmpty) return const SizedBox.shrink();
    
    return Text(
      review.comment,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      DateFormat('d MMMM yyyy', 'es').format(review.createdAt),
      style: GoogleFonts.inter(
        fontSize: 12,
        color: AppTheme.textSecondary,
      ),
    );
  }
}