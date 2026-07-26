import 'package:flutter/material.dart';

import '../state/studio_state.dart';
import '../theme.dart';

/// The numbered 1-2-3-4 progress bar anchored below the app bar.
///
/// Completed steps show a checkmark, the active step is filled navy, upcoming
/// steps are outlined. Tapping a step jumps to it — the workflow is sequential
/// but never locks the user in.
class StepBar extends StatelessWidget {
  const StepBar({required this.current, required this.onStepTapped, super.key});

  final WorkflowStep current;
  final ValueChanged<WorkflowStep> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final steps = WorkflowStep.values;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageMargin,
        vertical: AppSpacing.gutter,
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const Expanded(child: _Connector()),
            _StepBox(
              step: steps[i],
              state: switch (steps[i].index.compareTo(current.index)) {
                < 0 => _StepState.complete,
                0 => _StepState.active,
                _ => _StepState.upcoming,
              },
              onTap: () => onStepTapped(steps[i]),
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { complete, active, upcoming }

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1.5, color: AppColors.outlineVariant);
}

class _StepBox extends StatelessWidget {
  const _StepBox({
    required this.step,
    required this.state,
    required this.onTap,
  });

  final WorkflowStep step;
  final _StepState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = state == _StepState.active;
    final isComplete = state == _StepState.complete;

    return Semantics(
      button: true,
      selected: isActive,
      label: 'Step ${step.number}, ${step.label}'
          '${isComplete ? ', completed' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: AppSpacing.touchTargetMin,
          height: AppSpacing.touchTargetMin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: isComplete
              ? const Icon(Icons.check, size: 24, color: AppColors.primary)
              : Text(
                  '${step.number}',
                  style: Theme.of(context).textTheme.labelBold.copyWith(
                    fontSize: 20,
                    color: isActive
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}
