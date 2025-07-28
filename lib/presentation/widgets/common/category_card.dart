import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _getCategoryGradient(category),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCategoryGradient(String category) {
    switch (category) {
      case 'Plomería':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Electricidad':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Limpieza':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Jardinería':
        return const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Carpintería':
        return const LinearGradient(
          colors: [Color(0xFFA16207), Color(0xFF92400E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Pintura':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Mecánica':
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Tecnología':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Tutoría':
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Plomería':
        return Symbols.plumbing;
      case 'Electricidad':
        return Symbols.electrical_services;
      case 'Limpieza':
        return Symbols.cleaning_services;
      case 'Jardinería':
        return Symbols.yard;
      case 'Carpintería':
        return Symbols.construction;
      case 'Pintura':
        return Symbols.format_paint;
      case 'Mecánica':
        return Symbols.build;
      case 'Tecnología':
        return Symbols.computer;
      case 'Tutoría':
        return Symbols.school;
      default:
        return Symbols.handyman;
    }
  }
} 