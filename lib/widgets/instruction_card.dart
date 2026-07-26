import 'package:flutter/material.dart';

import '../theme.dart';

/// A white block with a navy border carrying the action for the current step.
/// One per screen, always at the top — the user should never have to hunt for
/// what to do next.
class InstructionCard extends StatelessWidget {
  const InstructionCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.headlineLg.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            body,
            style: text.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
