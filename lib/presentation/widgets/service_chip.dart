import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const ServiceChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final bgColor = backgroundColor ?? 
        (isSelected 
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey[100]);
    
    final txtColor = textColor ?? 
        (isSelected 
            ? theme.primaryColor
            : Colors.grey[700]);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelected 
                ? Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize ?? 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: txtColor,
            ),
          ),
        ),
      ),
    );
  }
} 