import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points, this.dark = false});

  final List<double> points;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: CustomPaint(
        painter: _TrendPainter(
          points,
          dark ? Colors.white10 : Theme.of(context).colorScheme.outlineVariant,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.gridColor);

  final List<double> points;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - points[i] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primaryGreen
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final last = Offset(size.width, size.height - points.last * size.height);
    canvas.drawCircle(last, 7, Paint()..color = AppColors.primaryGreen);
    canvas.drawCircle(
      last,
      14,
      Paint()..color = AppColors.primaryGreen.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.gridColor != gridColor;
}
