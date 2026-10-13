import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'status_badge.dart';

class BenchmarkChart extends StatelessWidget {
  const BenchmarkChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: CustomPaint(
        painter: _BenchmarkPainter(),
        child: const Align(
          alignment: Alignment(0.52, -0.75),
          child: StatusBadge(label: 'You  Top 18%', color: AppColors.purple),
        ),
      ),
    );
  }
}

class _BenchmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.blue.withValues(alpha: 0.18);
    for (var i = 0; i < 18; i++) {
      final height = 14 + math.sin(i / 18 * math.pi) * 42;
      final x = i * size.width / 18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, size.height - height, size.width / 24, height),
          const Radius.circular(8),
        ),
        paint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .68, 8, 5, size.height - 8),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.primaryGreen,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
