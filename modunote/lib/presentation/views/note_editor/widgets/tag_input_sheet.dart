import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tag.dart';
import '../../../viewmodels/tag_list_view_model.dart';

/// Bottom sheet with a live-autocomplete text field for adding a tag.
/// Pops with the [Tag] to add, or null if cancelled.
/// Finds existing tags via [TagListViewModel.searchByPrefix] and
/// [TagListViewModel.findByName]; creates new tags via [TagListViewModel.insert].
class TagInputSheet extends ConsumerStatefulWidget {
  const TagInputSheet({super.key, required this.noteTagIds});

  /// IDs of tags already on the note — filtered out of suggestions.
  final List<String> noteTagIds;

  @override
  ConsumerState<TagInputSheet> createState() => _TagInputSheetState();
}

class _TagInputSheetState extends ConsumerState<TagInputSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Tag> _suggestions = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final results = await ref
          .read(tagListViewModelProvider.notifier)
          .searchByPrefix(value);
      // Filter tags already on the note.
      final filtered =
          results.where((t) => !widget.noteTagIds.contains(t.id)).toList();
      if (mounted) setState(() => _suggestions = filtered);
    });
  }

  Future<void> _submit() async {
    final name = _ctrl.text.normalised;
    if (name.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final existing =
          await ref.read(tagListViewModelProvider.notifier).findByName(name);
      if (!mounted) return;
      if (existing != null) {
        if (widget.noteTagIds.contains(existing.id)) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Tag already added')));
          setState(() => _isSubmitting = false);
          return;
        }
        Navigator.of(context).pop(existing);
      } else {
        final newTag =
            await ref.read(tagListViewModelProvider.notifier).insert(name);
        if (mounted) Navigator.of(context).pop(newTag);
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _selectSuggestion(Tag tag) {
    Navigator.of(context).pop(tag);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    // Determine if the current input text has an exact match in suggestions.
    final normInput = _ctrl.text.normalised;
    final hasExactMatch =
        _suggestions.any((t) => t.name == normInput);
    final showCreate = normInput.isNotEmpty && !hasExactMatch;

    // All existing tags not already on this note — shown when field is empty.
    final allTags = (ref.watch(tagListViewModelProvider).valueOrNull ?? <Tag>[])
        .where((t) => !widget.noteTagIds.contains(t.id))
        .toList();
    final isSearching = normInput.isNotEmpty;
    final displayList = isSearching ? _suggestions : allTags;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Add tag',
                style: AppTypography.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: onSurface,
                ),
              ),
            ),
            // Input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 18, color: mutedColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.none,
                        style: AppTypography.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: 'e.g. photography',
                          hintStyle: AppTypography.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: mutedColor,
                          ),
                        ),
                        onChanged: _onChanged,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    if (_isSubmitting)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: mutedColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tag list (all when empty, prefix-filtered when typing) + create option
            if (displayList.isNotEmpty || showCreate)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  children: [
                    if (!isSearching && displayList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                        child: Text(
                          'All tags',
                          style: AppTypography.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    for (final tag in displayList)
                      _SuggestionTile(
                        tag: tag,
                        chipBg: chipBg,
                        chipText: chipText,
                        onSurface: onSurface,
                        variantColor: variantColor,
                        onTap: () => _selectSuggestion(tag),
                      ),
                    if (showCreate)
                      _CreateTile(
                        name: normInput,
                        outlineStrong: outlineStrong,
                        onSurface: onSurface,
                        variantColor: variantColor,
                        onTap: _submit,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.tag,
    required this.chipBg,
    required this.chipText,
    required this.onSurface,
    required this.variantColor,
    required this.onTap,
  });

  final Tag tag;
  final Color chipBg;
  final Color chipText;
  final Color onSurface;
  final Color variantColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '#${tag.name}',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chipText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Use existing tag',
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: variantColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({
    required this.name,
    required this.outlineStrong,
    required this.onSurface,
    required this.variantColor,
    required this.onTap,
  });

  final String name;
  final Color outlineStrong;
  final Color onSurface;
  final Color variantColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineStrong, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: variantColor),
            const SizedBox(width: 8),
            Text(
              'Create "#$name"',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
