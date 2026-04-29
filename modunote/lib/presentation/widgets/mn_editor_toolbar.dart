import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';

/// Formatting toolbar pinned above the keyboard in the Note Editor.
/// Owns a listener on [controller] so active-state badges update on selection change.
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.4
class MNEditorToolbar extends StatefulWidget {
  const MNEditorToolbar({super.key, required this.controller});

  final QuillController controller;

  @override
  State<MNEditorToolbar> createState() => _MNEditorToolbarState();
}

class _MNEditorToolbarState extends State<MNEditorToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(MNEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() => setState(() {});

  Map<String, Attribute> get _attrs =>
      widget.controller.getSelectionStyle().attributes;

  bool _isBoldActive() => _attrs[Attribute.bold.key]?.value == true;
  bool _isItalicActive() => _attrs[Attribute.italic.key]?.value == true;
  bool _isUnderlineActive() => _attrs[Attribute.underline.key]?.value == true;
  bool _isH1Active() => _attrs[Attribute.header.key]?.value == 1;
  bool _isH2Active() => _attrs[Attribute.header.key]?.value == 2;
  bool _isBulletActive() => _attrs[Attribute.list.key]?.value == 'bullet';
  bool _isOrderedActive() => _attrs[Attribute.list.key]?.value == 'ordered';
  bool _isChecklistActive() {
    final v = _attrs[Attribute.list.key]?.value;
    return v == 'unchecked' || v == 'checked';
  }
  bool _isBlockquoteActive() => _attrs[Attribute.blockQuote.key] != null;

  void _toggle(Attribute attr, bool isActive) {
    if (isActive) {
      widget.controller.formatSelection(Attribute.clone(attr, null));
    } else {
      widget.controller.formatSelection(attr);
    }
  }

  void _toggleChecklist(bool isActive) {
    if (isActive) {
      widget.controller
          .formatSelection(Attribute.clone(Attribute.unchecked, null));
    } else {
      widget.controller.formatSelection(Attribute.unchecked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final outlineColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final inactiveIconColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(color: outlineColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ToolButton(
            isActive: _isBoldActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.bold, _isBoldActive()),
            child: const Icon(Icons.format_bold, size: 18),
          ),
          _ToolButton(
            isActive: _isItalicActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.italic, _isItalicActive()),
            child: const Icon(Icons.format_italic, size: 18),
          ),
          _ToolButton(
            isActive: _isUnderlineActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.underline, _isUnderlineActive()),
            child: const Icon(Icons.format_underlined, size: 18),
          ),
          _ToolButton(
            isActive: _isH1Active(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.h1, _isH1Active()),
            child: const _HeaderLabel('H1'),
          ),
          _ToolButton(
            isActive: _isH2Active(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.h2, _isH2Active()),
            child: const _HeaderLabel('H2'),
          ),
          _ToolButton(
            isActive: _isBulletActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.ul, _isBulletActive()),
            child: const Icon(Icons.format_list_bulleted, size: 18),
          ),
          _ToolButton(
            isActive: _isOrderedActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.ol, _isOrderedActive()),
            child: const Icon(Icons.format_list_numbered, size: 18),
          ),
          _ToolButton(
            isActive: _isChecklistActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggleChecklist(_isChecklistActive()),
            child: const Icon(Icons.checklist, size: 18),
          ),
          _ToolButton(
            isActive: _isBlockquoteActive(),
            activeColor: cs.onPrimaryContainer,
            activeBg: cs.primaryContainer,
            inactiveColor: inactiveIconColor,
            onTap: () => _toggle(Attribute.blockQuote, _isBlockquoteActive()),
            child: const Icon(Icons.format_quote, size: 18),
          ),
        ],
      ),
    );
  }
}

/// 34×34 rounded slot that shows active/inactive state.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.inactiveColor,
    required this.onTap,
    required this.child,
  });

  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final Color inactiveColor;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconTheme(
          data: IconThemeData(color: isActive ? activeColor : inactiveColor),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: isActive ? activeColor : inactiveColor),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Text label used for H1/H2 slots (no Material icon exists).
class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
