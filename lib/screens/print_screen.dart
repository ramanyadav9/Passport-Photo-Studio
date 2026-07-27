import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export/pdf_builder.dart';
import '../services/sheet_export.dart';
import '../state/studio_state.dart';
import '../theme.dart';
import '../widgets/draggable_sheet.dart';
import '../widgets/instruction_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/sheet_preview.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final _export = const SheetExportService();

  /// Which action is running, so the right button shows the spinner.
  _Busy _busy = _Busy.none;

  Future<void> _run(_Busy which, Future<void> Function() action) async {
    if (_busy != _Busy.none) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = which);
    try {
      await action();
    } on PdfExportException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontSize: 18)),
          backgroundColor: AppColors.guide,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  /// PDF or image, asked as two large buttons with the reason for each, since
  /// "PDF" and "PNG" mean nothing to most of the people using this.
  Future<void> _chooseFormat(StudioState state) async {
    final format = await showModalBottomSheet<ExportFormat>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Save as',
                style: Theme.of(sheetContext).textTheme.headlineLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              for (final format in ExportFormat.values) ...[
                _FormatButton(
                  format: format,
                  onTap: () => Navigator.pop(sheetContext, format),
                ),
                const SizedBox(height: AppSpacing.gutter),
              ],
            ],
          ),
        ),
      ),
    );

    if (format == null || !mounted) return;
    await _run(_Busy.sharing, () => _export.share(state, format));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = context.watch<StudioState>();
    final ready = !state.layout.isEmpty && _busy == _Busy.none;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.stackMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InstructionCard(
            title: 'Final Review',
            body: 'Drag any photo to move it. Tap a photo to swap who is in '
                'that slot. Guides appear when photos line up.',
          ),
          const SizedBox(height: AppSpacing.stackMd),

          if (state.layout.isEmpty)
            SheetPlaceholder(
              aspectRatio: state.paper.aspectRatio,
              message: 'Nothing to print yet. Add a photo in Step 1.',
            )
          else
            DraggableSheet(state: state),
          const SizedBox(height: AppSpacing.gutter),

          // Wrap rather than Row: on a narrow phone these two controls do not
          // fit side by side, and dropping to a second line beats clipping.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.gutter,
            children: [
              TextButton.icon(
                onPressed: ready ? state.resetToGrid : null,
                icon: const Icon(Icons.grid_on),
                label: Text('Reset to Grid', style: text.labelBold),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, AppSpacing.touchTargetMin),
                ),
              ),
              Semantics(
                label: 'Draw a cutting line around each photo',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Border', style: text.labelBold),
                    Switch(
                      value: state.photoBorder,
                      activeThumbColor: AppColors.onPrimary,
                      activeTrackColor: AppColors.primary,
                      onChanged: ready ? state.setPhotoBorder : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),

          _PrintButton(
            busy: _busy == _Busy.printing,
            onPressed: ready
                ? () => _run(_Busy.printing, () => _export.print(state))
                : null,
          ),
          const SizedBox(height: AppSpacing.gutter),

          _ShareButton(
            busy: _busy == _Busy.sharing,
            onPressed: ready ? () => _chooseFormat(state) : null,
          ),
          const SizedBox(height: AppSpacing.stackSm),

          Center(
            child: Text(
              'No printer set up? Use Save / Share to keep a PDF or send it '
              'to a print shop.',
              textAlign: TextAlign.center,
              style: text.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Busy { none, printing, sharing }

class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.format, required this.onTap});

  final ExportFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${format.label}, ${format.hint}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.primaryButtonHeight + 8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                format == ExportFormat.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                size: 26,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      format.label,
                      style: text.labelBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      format.hint,
                      style: text.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrintButton extends StatelessWidget {
  const _PrintButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!busy) {
      return PrimaryButton(
        label: 'PRINT',
        icon: Icons.print_outlined,
        trailingIcon: false,
        expand: true,
        onPressed: onPressed,
      );
    }
    return const _BusyBar(label: 'Preparing your sheet...');
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SizedBox(
      height: AppSpacing.primaryButtonHeight,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.share_outlined),
        label: Text(
          busy ? 'Preparing...' : 'Save / Share',
          style: text.buttonText,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
    );
  }
}

/// Rendering thirty photos at print resolution takes a moment; saying so beats
/// a button that looks broken.
class _BusyBar extends StatelessWidget {
  const _BusyBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.primaryButtonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.buttonText.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
