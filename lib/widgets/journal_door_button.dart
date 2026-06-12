import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 决策档案入口：简约矩形门，无数据仅边框着色，有数据整门填充。
class JournalDoorButton extends StatelessWidget {
  const JournalDoorButton({
    super.key,
    required this.isOpen,
    this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  final bool isOpen;
  final VoidCallback? onTap;
  final bool enabled;
  final String? tooltip;

  static const _width = 44.0;
  static const _height = 52.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      enabled: enabled,
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && onTap != null
                ? () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: _width,
              height: _height,
              child: CustomPaint(
                painter: _SimpleDoorPainter(isOpen: isOpen, enabled: enabled),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleDoorPainter extends CustomPainter {
  _SimpleDoorPainter({required this.isOpen, required this.enabled});

  final bool isOpen;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.08,
        size.width * 0.72,
        size.height * 0.84,
      ),
      const Radius.circular(3),
    );

    final borderColor = isOpen
        ? AppColors.gold.withValues(alpha: 0.88)
        : AppColors.gold.withValues(alpha: enabled ? 0.78 : 0.38);

    if (isOpen) {
      final glowCenter = Offset(frame.center.dx, frame.bottom - frame.height * 0.18);
      canvas.drawOval(
        Rect.fromCenter(
          center: glowCenter,
          width: frame.width * 1.35,
          height: frame.height * 0.62,
        ),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: glowCenter,
          width: frame.width * 0.95,
          height: frame.height * 0.42,
        ),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawRRect(
        frame,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gold.withValues(alpha: 0.46),
              AppColors.gold.withValues(alpha: 0.28),
            ],
          ).createShader(frame.outerRect),
      );
    }

    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isOpen ? 2.0 : 1.8
        ..color = borderColor,
    );

    _drawKnob(canvas, Offset(frame.right - 9, frame.center.dy), lit: isOpen);
  }

  void _drawKnob(Canvas canvas, Offset knobCenter, {required bool lit}) {
    if (lit) {
      canvas.drawCircle(
        knobCenter,
        6,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.drawCircle(
      knobCenter,
      2.6,
      Paint()..color = lit ? const Color(0xFFFFF2CC) : AppColors.gold,
    );
    canvas.drawCircle(
      knobCenter,
      2.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.gold.withValues(alpha: lit ? 0.9 : 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleDoorPainter oldDelegate) {
    return oldDelegate.isOpen != isOpen || oldDelegate.enabled != enabled;
  }
}

