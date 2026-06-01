import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NeoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final bool isCircle;

  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppColors.primaryContainer,
    this.borderColor = AppColors.neoBlack,
    this.shadowColor = AppColors.neoBlack,
    this.borderWidth = 2.0,
    this.borderRadius = 8.0,
    this.shadowOffset = const Offset(4, 4),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.isCircle = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = false;
      });
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final currentOffset = _isPressed ? const Offset(0, 0) : widget.shadowOffset;
    final currentBgColor = isDisabled ? AppColors.surfaceVariant : widget.backgroundColor;

    return GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset.dx : 0,
          _isPressed ? widget.shadowOffset.dy : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: currentBgColor,
          borderRadius: widget.isCircle ? BorderRadius.circular(999) : BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDisabled ? AppColors.textDisabled : widget.borderColor,
            width: widget.borderWidth,
          ),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: currentOffset,
                  ),
                ],
        ),
        padding: widget.padding,
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
