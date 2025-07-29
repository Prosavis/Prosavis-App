import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationBadge extends StatelessWidget {
  final String? level;
  final double size;
  final bool showLabel;

  const VerificationBadge({
    super.key,
    this.level,
    this.size = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(level);
    
    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.verified,
              size: size * 0.8,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Verificado',
              style: GoogleFonts.inter(
                fontSize: size * 0.6,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Symbols.check,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }

  Color _getBadgeColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'premium':
        return Colors.purple;
      case 'standard':
        return Colors.blue;
      case 'basic':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
} 