import 'package:flutter/material.dart';

/// A reusable chip widget to display a piece of information with an icon,
/// a label, and a value.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
    final onChipColor = theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: onChipColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(color: onChipColor),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: onChipColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}