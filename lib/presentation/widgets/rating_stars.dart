import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final bool showRating;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
    this.unratedColor,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Colors.amber;
    final inactiveColor = unratedColor ?? Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            // Full star - estrella llena
            return Icon(
              Symbols.star,
              size: size,
              color: activeColor,
              fill: 1.0, // Completamente llena
            );
          } else if (index < rating && rating - index >= 0.5) {
            // Half star - media estrella
            return Stack(
              children: [
                Icon(
                  Symbols.star_outline,
                  size: size,
                  color: inactiveColor,
                  fill: 0.0, // Vacía por dentro
                ),
                ClipRect(
                  clipper: HalfStarClipper(),
                  child: Icon(
                    Symbols.star,
                    size: size,
                    color: activeColor,
                    fill: 1.0, // Mitad llena
                  ),
                ),
              ],
            );
          } else {
            // Empty star - estrella vacía
            return Icon(
              Symbols.star_outline,
              size: size,
              color: inactiveColor,
              fill: 0.0, // Completamente vacía
            );
          }
        }),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class HalfStarClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
} 