import 'package:flutter/material.dart';

import '../theme.dart';

/// The forward action on each screen. Navy, at least 56px tall, bold white
/// text, optional trailing icon.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon = true,
    this.expand = false,
    super.key,
  });

  final String label;

  /// Null disables the button — used for empty states, e.g. no photo added yet.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool trailingIcon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final iconWidget = icon == null
        ? null
        : Icon(icon, size: 24, color: AppColors.onPrimary);

    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppSpacing.primaryButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.outlineVariant,
          disabledForegroundColor: AppColors.surfaceLowest,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: text.buttonText,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null && !trailingIcon) ...[
              iconWidget,
              const SizedBox(width: AppSpacing.stackSm + 4),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (iconWidget != null && trailingIcon) ...[
              const SizedBox(width: AppSpacing.stackSm + 4),
              iconWidget,
            ],
          ],
        ),
      ),
    );
  }
}
