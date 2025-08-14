import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddressChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const AddressChip({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.location_on, size: 16, color: AppTheme.accentColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


