import 'package:flutter/material.dart';

import '../theme.dart';

/// A large, obvious choice control. Selected fills pale blue with a navy
/// border; unselected is outlined. Sized well past the 48px touch minimum.
class SelectorChip extends StatelessWidget {
  const SelectorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.touchTargetMin + 8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackSm + 4,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          // A chip in an Expanded row gets whatever width is left over, which
          // on a narrow phone can be less than its label wants. Flexible plus
          // ellipsis keeps it inside its box instead of overflowing the row.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelBold.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
