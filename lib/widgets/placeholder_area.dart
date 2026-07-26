import 'package:flutter/material.dart';

import '../theme.dart';

/// Marks a region that a later build phase fills in. Nothing here ships.
class PlaceholderArea extends StatelessWidget {
  const PlaceholderArea({required this.label, this.phase, super.key});

  final String label;
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: text.labelBold.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (phase != null) ...[
                const SizedBox(height: 4),
                Text(
                  phase!,
                  textAlign: TextAlign.center,
                  style: text.labelMd.copyWith(color: AppColors.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
