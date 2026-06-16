import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/category.dart';
import '../viewmodels/category_tree_view_model.dart';

/// Bottom sheet that lets the user assign a category to a note.
///
/// Returns via [Navigator.pop]:
///   - A non-empty [String] (the selected category id)
///   - An empty [String] `""` to unassign (None)
///   - `null` if dismissed with no change
///
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.5
class MNCategoryPickerSheet extends ConsumerStatefulWidget {
  const MNCategoryPickerSheet({
    required this.currentCategoryId,
    super.key,
  });

  final String? currentCategoryId;

  @override
  ConsumerState<MNCategoryPickerSheet> createState() =>
      _MNCategoryPickerSheetState();
}

class _MNCategoryPickerSheetState
    extends ConsumerState<MNCategoryPickerSheet> {
  /// Ids of nodes that are currently expanded in the tree.
  late Set<String> _expandedIds;

  /// The id that is visually selected (mirrors currentCategoryId on open).
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentCategoryId;
    // Pre-expand ancestors so the current selection is visible on open.
    _expandedIds = {};
  }

  /// Initialises [_expandedIds] once the flat category list is available.
  /// Walks up the ancestor chain of [_selectedId] and expands each ancestor.
  void _initExpanded(List<Category> all) {
    if (_selectedId == null) return;
    final byId = {for (final c in all) c.id: c};
    String? current = _selectedId;
    while (current != null) {
      final parent = byId[current]?.parentId;
      if (parent != null) _expandedIds.add(parent);
      current = parent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryTreeViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted = isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final surfaceContainer =
        isDark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer;
    final variantColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 40,
            offset: Offset(0, -20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Grabber ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Move to category',
                        style: AppTypography.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organise this note in your folder tree',
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(null),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: variantColor),
                  ),
                ),
              ],
            ),
          ),

          // ── Tree + none + new ──────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: categoriesAsync.when(
              data: (categories) {
                // One-time expansion init when data first arrives.
                if (_expandedIds.isEmpty && _selectedId != null) {
                  _initExpanded(categories);
                }
                return _buildScrollableTree(
                  context,
                  categories,
                  isDark,
                  onSurface,
                  muted,
                  outlineStrong,
                  surfaceContainer,
                  variantColor,
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Could not load categories',
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: muted,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildScrollableTree(
    BuildContext context,
    List<Category> all,
    bool isDark,
    Color onSurface,
    Color muted,
    Color outlineStrong,
    Color surfaceContainer,
    Color variantColor,
  ) {
    // Group categories by parentId for O(1) children lookup.
    final childrenOf = <String?, List<Category>>{};
    for (final c in all) {
      childrenOf.putIfAbsent(c.parentId, () => []).add(c);
    }
    // Sort siblings by sortOrder then name within each group.
    for (final list in childrenOf.values) {
      list.sort((a, b) {
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0 ? so : a.name.compareTo(b.name);
      });
    }

    final primaryContainer = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;
    final onPrimaryContainer = isDark
        ? AppColors.darkOnPrimaryContainer
        : AppColors.lightOnPrimaryContainer;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    // Build the flat ordered list of visible rows to feed into ListView.
    final rows = <Widget>[];

    // "None" row — unassigns the category.
    rows.add(_buildNoneRow(
      isDark: isDark,
      onSurface: onSurface,
      muted: muted,
      surfaceContainer: surfaceContainer,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      variantColor: variantColor,
    ));

    // Recursively build tree rows starting from roots.
    void addRows(String? parentId, int depth) {
      final siblings = childrenOf[parentId] ?? [];
      for (final cat in siblings) {
        final hasChildren = (childrenOf[cat.id] ?? []).isNotEmpty;
        final isSelected = _selectedId == cat.id;
        final isExpanded = _expandedIds.contains(cat.id);

        rows.add(_buildCategoryRow(
          category: cat,
          depth: depth,
          hasChildren: hasChildren,
          isSelected: isSelected,
          isExpanded: isExpanded,
          isDark: isDark,
          onSurface: onSurface,
          muted: muted,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          primary: primary,
          variantColor: variantColor,
        ));

        if (hasChildren && isExpanded) {
          addRows(cat.id, depth + 1);
        }
      }
    }

    addRows(null, 0);

    // "New category" row.
    rows.add(_buildNewCategoryRow(
      context: context,
      isDark: isDark,
      onSurface: onSurface,
      muted: muted,
      outlineStrong: outlineStrong,
    ));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      shrinkWrap: true,
      children: rows,
    );
  }

  // ── "None" row ─────────────────────────────────────────────────────────────

  Widget _buildNoneRow({
    required bool isDark,
    required Color onSurface,
    required Color muted,
    required Color surfaceContainer,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color variantColor,
  }) {
    final isSelected = _selectedId == null;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = null);
        Navigator.of(context).pop(''); // empty string = unassign
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Row(
          children: [
            // Spacer where chevron would be
            const SizedBox(width: 22),
            const SizedBox(width: 8),
            Icon(
              Icons.folder_off_outlined,
              size: 18,
              color: isSelected ? onPrimaryContainer : variantColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'None',
                style: AppTypography.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.1,
                  color: isSelected ? onPrimaryContainer : onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 18, color: onPrimaryContainer),
          ],
        ),
      ),
    );
  }

  // ── Category tree row ───────────────────────────────────────────────────────

  Widget _buildCategoryRow({
    required Category category,
    required int depth,
    required bool hasChildren,
    required bool isSelected,
    required bool isExpanded,
    required bool isDark,
    required Color onSurface,
    required Color muted,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color primary,
    required Color variantColor,
  }) {
    final leftPad = 10.0 + depth * 20.0;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = category.id);
        Navigator.of(context).pop(category.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: leftPad,
          right: 14,
        ),
        child: Row(
          children: [
            // Expand/collapse chevron or spacer
            if (hasChildren)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(category.id);
                    } else {
                      _expandedIds.add(category.id);
                    }
                  });
                },
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 14,
                  color: isSelected ? onPrimaryContainer : variantColor,
                ),
              )
            else
              const SizedBox(width: 14),
            const SizedBox(width: 8),
            // Folder icon
            Icon(
              isSelected ? Icons.folder : Icons.folder_outlined,
              size: 18,
              color: isSelected ? onPrimaryContainer : primary,
            ),
            const SizedBox(width: 10),
            // Label
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.1,
                  color: isSelected ? onPrimaryContainer : onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Checkmark on selected row
            if (isSelected)
              Icon(Icons.check, size: 18, color: onPrimaryContainer),
          ],
        ),
      ),
    );
  }

  // ── "New category" row ─────────────────────────────────────────────────────

  Widget _buildNewCategoryRow({
    required BuildContext context,
    required bool isDark,
    required Color onSurface,
    required Color muted,
    required Color outlineStrong,
  }) {
    return GestureDetector(
      onTap: () => _showNewCategoryDialog(context, isDark, onSurface, muted),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: outlineStrong,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: AppColors.accentOn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New category',
                style: AppTypography.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ),
            // Context hint: creates under selected category, or at root
            if (_selectedId != null)
              Text(
                'Under · ${_selectedCategoryName()}',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  String _selectedCategoryName() {
    final all =
        ref.read(categoryTreeViewModelProvider).valueOrNull ?? <Category>[];
    final matching = all.where((c) => c.id == _selectedId);
    return matching.isEmpty ? 'root' : matching.first.name;
  }

  void _showNewCategoryDialog(
    BuildContext context,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New category',
          style: AppTypography.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: onSurface,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _selectedId != null
                ? 'Name (under ${_selectedCategoryName()})'
                : 'Name (at root)',
            hintStyle: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
          onSubmitted: (value) {
            Navigator.of(ctx).pop();
            _createCategory(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = ctrl.text;
              Navigator.of(ctx).pop();
              _createCategory(value);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await ref
          .read(categoryTreeViewModelProvider.notifier)
          .insert(name: trimmed, parentId: _selectedId);
    } catch (_) {
      // ValidationException (depth limit) or DatabaseException — sheet stays
      // open; user can try a different parent. No silent swallow needed here
      // because CategoryTreeViewModel already sets AsyncError state.
    }
  }
}
