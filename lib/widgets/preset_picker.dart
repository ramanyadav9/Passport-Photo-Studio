import 'package:flutter/material.dart';

import '../models/document_preset.dart';
import '../theme.dart';

/// A searchable list of document photo requirements.
///
/// Opened full-screen rather than as a dropdown: the list is long, the rows are
/// large, and someone hunting for "Schengen" should not be doing it through a
/// letterbox.
Future<DocumentPreset?> showPresetPicker(
  BuildContext context, {
  DocumentPreset? current,
}) {
  return showModalBottomSheet<DocumentPreset>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (_) => _PresetPicker(current: current),
  );
}

class _PresetPicker extends StatefulWidget {
  const _PresetPicker({this.current});

  final DocumentPreset? current;

  @override
  State<_PresetPicker> createState() => _PresetPickerState();
}

class _PresetPickerState extends State<_PresetPicker> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final matches = documentPresets.where((p) => p.matches(_query)).toList();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.gutter),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageMargin,
                AppSpacing.gutter,
                AppSpacing.pageMargin,
                AppSpacing.stackSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Choose a document', style: text.headlineLg),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  TextField(
                    controller: _controller,
                    onChanged: (v) => setState(() => _query = v),
                    autofocus: false,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      hintText: 'Search country or document',
                      hintStyle: const TextStyle(fontSize: 18),
                      prefixIcon: const Icon(Icons.search),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? _NoMatches(query: _query, text: text)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageMargin,
                      ),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.stackSm),
                      itemBuilder: (context, i) => _PresetRow(
                        preset: matches[i],
                        isSelected: matches[i] == widget.current,
                        onTap: () => Navigator.pop(context, matches[i]),
                      ),
                    ),
            ),
            // Said plainly, because getting this wrong costs the user a
            // rejected application, not just a wasted sheet of paper.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(
                'Sizes are a guide. Check your embassy or authority if you '
                'are unsure.',
                textAlign: TextAlign.center,
                style: text.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final DocumentPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${preset.label}, ${preset.sizeLabel}, '
          '${preset.backgroundName} background',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              _BackgroundSwatch(colour: preset.backgroundColour),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: text.labelBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${preset.sizeLabel}  -  '
                      '${preset.backgroundName} background',
                      style: text.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check, color: AppColors.primary, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the required background colour, so the user can compare it against
/// the wall they are about to stand in front of.
class _BackgroundSwatch extends StatelessWidget {
  const _BackgroundSwatch({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query, required this.text});

  final String query;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing found for "$query".',
              textAlign: TextAlign.center,
              style: text.labelBold,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'You can still set the exact size yourself with Custom.',
              textAlign: TextAlign.center,
              style: text.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
