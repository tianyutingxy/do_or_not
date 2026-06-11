import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 选中确认时的抖动效果
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.shake,
    required this.child,
  });

  final bool shake;
  final Widget child;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.shake) _controller.forward();
  }

  @override
  void didUpdateWidget(ShakeWidget old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final decay = 1 - t;
        final offset = math.sin(t * math.pi * 7) * 10 * decay;
        final scale = 1 + math.sin(t * math.pi) * 0.04;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}
