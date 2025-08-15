import 'package:flutter/material.dart';

/// Wrapper reutilizable que aplica un micro-scale al presionar
/// y mantiene la tinta/forma correctamente con Material+InkWell.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;
  final Color color;
  final double pressedScale;
  final Duration duration;

  const PressScale({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.color = Colors.transparent,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1.0,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: Material(
        color: widget.color,
        borderRadius: widget.borderRadius,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onPressed,
          onHighlightChanged: (value) {
            setState(() => _pressed = value);
          },
          child: widget.child,
        ),
      ),
    );
  }
}


