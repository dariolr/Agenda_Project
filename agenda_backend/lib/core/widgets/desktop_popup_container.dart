import 'package:flutter/material.dart';

/// Alignment for the desktop popup relative to the trigger.
enum PopupAlignment { left, right }

/// Vertical position for the popup relative to the trigger.
enum PopupVerticalPosition { below, above }

/// A reusable container for desktop anchored popups with consistent styling.
/// Provides: dismiss layer, animation, border, positioning.
class DesktopPopupContainer extends StatefulWidget {
  const DesktopPopupContainer({
    super.key,
    required this.link,
    required this.triggerWidth,
    required this.triggerHeight,
    required this.onDismiss,
    required this.child,
    this.popupWidth,
    this.maxHeight = 300,
    this.borderRadius = 12.0,
    this.alignment = PopupAlignment.left,
    this.verticalPosition = PopupVerticalPosition.below,
  });

  /// The layer link to anchor the popup to the trigger.
  final LayerLink link;

  /// The width of the trigger widget.
  final double triggerWidth;

  /// The height of the trigger widget.
  final double triggerHeight;

  /// Called when the popup should be dismissed.
  final VoidCallback onDismiss;

  /// The content of the popup.
  final Widget child;

  /// Width of the popup. If null, matches the trigger width.
  final double? popupWidth;

  /// Maximum height of the popup.
  final double maxHeight;

  /// Border radius of the popup.
  final double borderRadius;

  /// Alignment of the popup relative to the trigger.
  final PopupAlignment alignment;

  /// Vertical position of the popup (above or below the trigger).
  final PopupVerticalPosition verticalPosition;

  @override
  State<DesktopPopupContainer> createState() => _DesktopPopupContainerState();
}

class _DesktopPopupContainerState extends State<DesktopPopupContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveWidth = widget.popupWidth ?? widget.triggerWidth;
    final isAbove = widget.verticalPosition == PopupVerticalPosition.above;

    // Horizontal offset based on alignment
    final horizontalOffset = widget.alignment == PopupAlignment.right
        ? widget.triggerWidth - effectiveWidth
        : 0.0;

    // Vertical offset and anchors based on position
    final Alignment targetAnchor;
    final Alignment followerAnchor;
    final EdgeInsets padding;

    if (isAbove) {
      // Popup appears above the trigger, growing downward
      targetAnchor = Alignment.topLeft;
      followerAnchor = Alignment.topLeft;
      padding = const EdgeInsets.only(bottom: 4);
    } else {
      targetAnchor = Alignment.bottomLeft;
      followerAnchor = Alignment.topLeft;
      padding = const EdgeInsets.only(top: 4);
    }

    final offset = Offset(horizontalOffset, 0);

    // Scale alignment for animation
    final scaleAlignment = isAbove
        ? (widget.alignment == PopupAlignment.right
              ? Alignment.bottomRight
              : Alignment.bottomLeft)
        : (widget.alignment == PopupAlignment.right
              ? Alignment.topRight
              : Alignment.topLeft);

    return Stack(
      children: [
        // Dismiss layer
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        // Popup
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          offset: offset,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: scaleAlignment,
              child: Padding(
                padding: padding,
                child: Material(
                  elevation: 8,
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: effectiveWidth,
                    constraints: BoxConstraints(maxHeight: widget.maxHeight),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: Colors.grey.withOpacity(0.35)),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
