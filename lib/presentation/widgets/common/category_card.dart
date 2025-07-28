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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plomería':
        return Symbols.plumbing;
      case 'electricidad':
        return Symbols.electrical_services;
      case 'limpieza':
        return Symbols.cleaning_services;
      case 'jardinería':
        return Symbols.yard;
      case 'carpintería':
        return Symbols.construction;
      case 'pintura':
        return Symbols.format_paint;
      case 'mecánica':
        return Symbols.build;
      case 'tecnología':
        return Symbols.computer;
      case 'tutoría':
        return Symbols.school;
      default:
        return Symbols.home_repair_service;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'plomería':
        return const Color(0xFF3B82F6);
      case 'electricidad':
        return const Color(0xFFF59E0B);
      case 'limpieza':
        return const Color(0xFF10B981);
      case 'jardinería':
        return const Color(0xFF059669);
      case 'carpintería':
        return const Color(0xFF92400E);
      case 'pintura':
        return const Color(0xFFDC2626);
      case 'mecánica':
        return const Color(0xFF374151);
      case 'tecnología':
        return const Color(0xFF7C3AED);
      case 'tutoría':
        return const Color(0xFFDB2777);
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 