import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AthleteAvatar extends StatelessWidget {
  const AthleteAvatar({
    super.key,
    this.label = 'A',
    this.size = 48,
    this.imagePath,
    this.showBorder = true,
  });

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
        border: showBorder
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath == null
          ? ColoredBox(
              color: AppColors.darkSurface,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Image.asset(imagePath!, fit: BoxFit.cover),
    );
  }
}
