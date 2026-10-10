import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.brandBlack,
        minimumSize: const Size(0, 58),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.dark = false});
  final String label;
  final VoidCallback? onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? Colors.white : AppColors.textDark,
        side: BorderSide(color: dark ? Colors.white24 : AppColors.line),
        minimumSize: const Size(0, 50),
        textStyle: Theme.of(context).textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
      child: Text(label),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AthleteAvatar extends StatelessWidget {
  const AthleteAvatar({super.key, this.label = 'A', this.size = 48, this.imagePath, this.showBorder = true});
  final String label;
  final double size;
  final String? imagePath;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        border: showBorder ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath == null
          ? ColoredBox(
              color: AppColors.darkSurface,
              child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            )
          : Image.asset(imagePath!, fit: BoxFit.cover),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color = AppColors.primaryGreen, this.dark = false, this.icon});
  final String label;
  final Color color;
  final bool dark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 14), const SizedBox(width: 5)],
          Text(label, style: TextStyle(color: dark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.title, required this.value, this.delta, this.icon, this.dark = false});
  final String title;
  final String value;
  final String? delta;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: dark ? Colors.white10 : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) Icon(icon, size: 17, color: dark ? AppColors.primaryGreen : AppColors.textMuted),
            if (icon != null) const SizedBox(width: 7),
            Expanded(child: Text(title, style: TextStyle(color: dark ? Colors.white70 : AppColors.textMuted, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: dark ? Colors.white : null)),
          if (delta != null) Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(delta!, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 78, this.dark = false});
  final double value;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value, dark),
        child: Center(
          child: Text('${(value * 100).round()}%', style: TextStyle(color: dark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.dark);
  final double value;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = dark ? Colors.white12 : AppColors.line;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryGreen;
    canvas.drawArc(rect.deflate(5), -math.pi / 2, math.pi * 2, false, base);
    canvas.drawArc(rect.deflate(5), -math.pi / 2, math.pi * 2 * value, false, active);
  }
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.value != value;
}

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points, this.dark = false});
  final List<double> points;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 170, child: CustomPaint(painter: _TrendPainter(points, dark), size: Size.infinite));
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.dark);
  final List<double> points;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = dark ? Colors.white10 : AppColors.line
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
    canvas.drawCircle(last, 14, Paint()..color = AppColors.primaryGreen.withValues(alpha: 0.16));
  }
  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.points != points;
}

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
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 2, size.height - height, size.width / 24, height), const Radius.circular(8)), paint);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .68, 8, 5, size.height - 8), const Radius.circular(8)), Paint()..color = AppColors.primaryGreen);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
