import 'package:flutter/material.dart';
import '../../core/utils/haptic_engine.dart';

/// A premium button wrapper that provides physics-based scale down on tap
/// and integrated haptic feedback, achieving a top-tier App Store feel.
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final bool hapticEnabled;
  final bool opaque;

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96, // Slightly subtler, high-end feel
    this.duration = const Duration(milliseconds: 120),
    this.hapticEnabled = true,
    this.opaque = true,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack), // Snappier
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.hapticEnabled) HapticEngine.selection();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap!();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.opaque ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
