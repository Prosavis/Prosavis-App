import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Widget interactivo de calificación por estrellas con feedback visual mejorado
class InteractiveRatingStars extends StatefulWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool enabled;
  final int starCount;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 32,
    this.activeColor = Colors.amber,
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.enabled = true,
    this.starCount = 5,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InteractiveRatingStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      setState(() {
        _currentRating = widget.rating;
      });
    }
  }

  void _onStarTapped(int starIndex) {
    if (!widget.enabled) return;

    final newRating = (starIndex + 1).toDouble();
    setState(() {
      _currentRating = newRating;
    });

    // Animación de feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onRatingChanged?.call(newRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        final isSelected = index < _currentRating;
        
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final scale = isSelected && index == (_currentRating - 1).floor()
                ? 1.0 + (_animationController.value * 0.2)
                : 1.0;

            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () => _onStarTapped(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      isSelected ? Symbols.star : Symbols.star_outline,
                      size: widget.size,
                      color: isSelected ? widget.activeColor : widget.inactiveColor,
                      fill: isSelected ? 1.0 : 0.0,
                      shadows: isSelected
                          ? [
                              Shadow(
                                color: widget.activeColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}