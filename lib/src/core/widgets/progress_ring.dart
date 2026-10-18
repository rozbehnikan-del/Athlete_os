import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 78,
    this.dark = false,
  });

  final double value;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value,
          dark ? Colors.white12 : Theme.of(context).colorScheme.outlineVariant,
        ),
        child: Center(
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: dark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.trackColor);

  final double value;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryGreen;
    canvas.drawArc(rect.deflate(5), -math.pi / 2, math.pi * 2, false, base);
    canvas.drawArc(
      rect.deflate(5),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.trackColor != trackColor;
}
