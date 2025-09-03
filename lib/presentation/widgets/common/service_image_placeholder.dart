import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Widget reutilizable para mostrar un placeholder elegante cuando no hay imagen de servicio
class ServiceImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final String text;
  final double iconSize;

  const ServiceImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.showText = true,
    this.text = 'Sin imagen',
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2C2C2E),
                  const Color(0xFF1C1C1E),
                ]
              : [
                  const Color(0xFF4A4A4A),
                  const Color(0xFF2C2C2C),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Efecto de patrón sutil
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(
                color: (isDark ? Colors.white : Colors.white).withValues(alpha: 0.05),
              ),
            ),
          ),
          // Ícono central
          Center(
            child: showText
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.image,
                        size: iconSize,
                        color: (isDark ? Colors.white : Colors.white).withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: TextStyle(
                          color: (isDark ? Colors.white : Colors.white).withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    Symbols.image,
                    size: iconSize,
                    color: (isDark ? Colors.white : Colors.white).withValues(alpha: 0.6),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para crear un patrón sutil de fondo
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    
    // Líneas diagonales sutiles
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
