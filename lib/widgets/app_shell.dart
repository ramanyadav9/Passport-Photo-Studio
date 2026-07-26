import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/add_photos_screen.dart';
import '../screens/crop_screen.dart';
import '../screens/layout_screen.dart';
import '../screens/print_screen.dart';
import '../state/studio_state.dart';
import '../theme.dart';
import 'step_bar.dart';

const _stepIcons = <WorkflowStep, IconData>{
  WorkflowStep.add: Icons.add_a_photo_outlined,
  WorkflowStep.adjust: Icons.crop,
  WorkflowStep.layout: Icons.grid_view,
  WorkflowStep.print: Icons.print_outlined,
};

/// The whole app lives in one Scaffold. Screens are swapped in an IndexedStack
/// rather than pushed on a Navigator, so each screen keeps its state and the
/// user can move backward and forward freely.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final step = context.select<StudioState, WorkflowStep>((s) => s.step);
    final state = context.read<StudioState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passport Photo'),
        leading: step == WorkflowStep.add
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back a step',
                onPressed: () =>
                    state.goToStep(WorkflowStep.values[step.index - 1]),
              ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          StepBar(current: step, onStepTapped: state.goToStep),
          Expanded(
            child: IndexedStack(
              index: step.index,
              children: const [
                AddPhotosScreen(),
                CropScreen(),
                LayoutScreen(),
                PrintScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: step,
        onStepTapped: state.goToStep,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onStepTapped});

  final WorkflowStep current;
  final ValueChanged<WorkflowStep> onStepTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackSm,
            vertical: AppSpacing.stackSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final step in WorkflowStep.values)
                _NavItem(
                  step: step,
                  isActive: step == current,
                  onTap: () => onStepTapped(step),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.step,
    required this.isActive,
    required this.onTap,
  });

  final WorkflowStep step;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: 'Step ${step.number}, ${step.label}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTargetMin + 8,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_stepIcons[step], size: 26, color: color),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMd.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
