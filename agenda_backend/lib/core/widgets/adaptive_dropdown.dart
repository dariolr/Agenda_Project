import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_backend/core/widgets/desktop_popup_container.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_dividers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dropdown item with a value and display widget.
class AdaptiveDropdownItem<T> {
  const AdaptiveDropdownItem({
    required this.value,
    required this.child,
    this.enabled = true,
  });

  final T value;
  final Widget child;
  final bool enabled;
}

/// Alignment for the desktop popup relative to the trigger.
enum AdaptiveDropdownAlignment { left, right }

/// Vertical position for the popup relative to the trigger.
enum AdaptiveDropdownVerticalPosition { below, above }

/// Adaptive dropdown that shows:
/// - A modal bottom sheet on mobile/tablet
/// - An anchored popup on desktop
class AdaptiveDropdown<T> extends ConsumerStatefulWidget {
  const AdaptiveDropdown({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.selectedValue,
    this.alignment = AdaptiveDropdownAlignment.left,
    this.verticalPosition = AdaptiveDropdownVerticalPosition.below,
    this.modalTitle,
    this.popupWidth,
    this.popupMaxHeight = 300,
    this.popupBorderRadius = 12.0,
    this.onOpened,
    this.onClosed,
    this.useRootNavigator = true,
    this.forcePopup = false,
    this.hideTriggerWhenOpen = false,
  });

  /// The list of items to display in the dropdown.
  final List<AdaptiveDropdownItem<T>> items;

  /// Called when an item is selected.
  final ValueChanged<T> onSelected;

  /// The trigger widget (typically a button or styled container).
  final Widget child;

  /// The currently selected value (for highlighting in the list).
  final T? selectedValue;

  /// Alignment of the popup on desktop (left or right).
  final AdaptiveDropdownAlignment alignment;

  /// Vertical position of the popup (above or below the trigger).
  final AdaptiveDropdownVerticalPosition verticalPosition;

  /// Optional title for the modal sheet on mobile/tablet.
  final String? modalTitle;

  /// Width of the popup on desktop. If null, matches the trigger width.
  final double? popupWidth;

  /// Maximum height of the popup on desktop.
  final double popupMaxHeight;

  /// Border radius of the popup on desktop.
  final double popupBorderRadius;

  /// Called when the dropdown is opened.
  final VoidCallback? onOpened;

  /// Called when the dropdown is closed.
  final VoidCallback? onClosed;

  /// Whether to push the mobile bottom sheet on the root navigator.
  final bool useRootNavigator;

  /// If true, always show popup instead of bottom sheet on mobile/tablet.
  final bool forcePopup;

  /// If true, hides the trigger widget when the popup is open.
  final bool hideTriggerWhenOpen;

  @override
  ConsumerState<AdaptiveDropdown<T>> createState() =>
      _AdaptiveDropdownState<T>();
}

class _AdaptiveDropdownState<T> extends ConsumerState<AdaptiveDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen) {
      _isOpen = false;
      widget.onClosed?.call();
      if (widget.hideTriggerWhenOpen) {
        setState(() {});
      }
    }
  }

  void _handleTap() {
    final formFactor = ref.read(formFactorProvider);

    if (widget.forcePopup || formFactor == AppFormFactor.desktop) {
      _showDesktopPopup();
    } else {
      _showMobileSheet();
    }
  }

  Future<void> _showMobileSheet() async {
    widget.onOpened?.call();
    _isOpen = true;

    final result = await AppBottomSheet.show<T>(
      context: context,
      heightFactor: null,
      builder: (ctx) => _MobileSheetContent<T>(
        items: widget.items,
        selectedValue: widget.selectedValue,
        title: widget.modalTitle,
        onSelected: (value) {
          Navigator.of(ctx).pop(value);
        },
      ),
      useRootNavigator: widget.useRootNavigator,
      padding: EdgeInsets.zero,
    );

    _isOpen = false;
    widget.onClosed?.call();

    if (result != null) {
      widget.onSelected(result);
    }
  }

  void _showDesktopPopup() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    widget.onOpened?.call();
    _isOpen = true;
    if (widget.hideTriggerWhenOpen) {
      setState(() {});
    }

    final renderBox = context.findRenderObject() as RenderBox;
    final triggerSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => DesktopPopupContainer(
        link: _layerLink,
        triggerWidth: triggerSize.width,
        triggerHeight: triggerSize.height,
        popupWidth: widget.popupWidth,
        maxHeight: widget.popupMaxHeight,
        borderRadius: widget.popupBorderRadius,
        alignment: widget.alignment == AdaptiveDropdownAlignment.right
            ? PopupAlignment.right
            : PopupAlignment.left,
        verticalPosition:
            widget.verticalPosition == AdaptiveDropdownVerticalPosition.above
            ? PopupVerticalPosition.above
            : PopupVerticalPosition.below,
        onDismiss: _removeOverlay,
        child: _DesktopDropdownContent<T>(
          items: widget.items,
          selectedValue: widget.selectedValue,
          title: widget.modalTitle,
          onSelected: (value) {
            _removeOverlay();
            widget.onSelected(value);
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Visibility(
          visible: !(widget.hideTriggerWhenOpen && _isOpen),
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Mobile/tablet modal sheet content.
class _MobileSheetContent<T> extends StatelessWidget {
  const _MobileSheetContent({
    required this.items,
    required this.onSelected,
    this.selectedValue,
    this.title,
  });

  final List<AdaptiveDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final T? selectedValue;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const AppBottomSheetDivider(),
        ],
        ...items.map((item) {
          final isSelected = item.value == selectedValue;
          return InkWell(
            onTap: item.enabled ? () => onSelected(item.value) : null,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.08)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: item.enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.38),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: item.child,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, size: 20, color: colorScheme.primary),
                ],
              ),
            ),
          );
        }),
        // Safe area padding for bottom with minimum inset
        SizedBox(
          height: math.max(MediaQuery.of(context).viewPadding.bottom, 15),
        ),
      ],
    );
  }
}

/// Content for the desktop dropdown popup.
class _DesktopDropdownContent<T> extends StatelessWidget {
  const _DesktopDropdownContent({
    required this.items,
    required this.onSelected,
    this.selectedValue,
    this.title,
    this.borderRadius = 12.0,
  });

  final List<AdaptiveDropdownItem<T>> items;
  final T? selectedValue;
  final String? title;
  final ValueChanged<T> onSelected;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              title!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const AppBottomSheetDivider(),
        ],
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: title == null ? 4 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length; i++)
                  _DesktopPopupItem<T>(
                    item: items[i],
                    isSelected: items[i].value == selectedValue,
                    isLast: i == items.length - 1,
                    borderRadius: borderRadius,
                    onTap: () => onSelected(items[i].value),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual item in the desktop popup.
class _DesktopPopupItem<T> extends StatefulWidget {
  const _DesktopPopupItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.isLast = false,
    this.borderRadius = 12.0,
  });

  final AdaptiveDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLast;
  final double borderRadius;

  @override
  State<_DesktopPopupItem<T>> createState() => _DesktopPopupItemState<T>();
}

class _DesktopPopupItemState<T> extends State<_DesktopPopupItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = widget.isSelected
        ? colorScheme.primary.withOpacity(0.08)
        : _isHovered
        ? colorScheme.primary.withOpacity(0.04)
        : Colors.transparent;

    final borderRadius = widget.isLast
        ? BorderRadius.only(
            bottomLeft: Radius.circular(widget.borderRadius),
            bottomRight: Radius.circular(widget.borderRadius),
          )
        : BorderRadius.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.item.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.item.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: widget.item.enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.38),
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  child: widget.item.child,
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
