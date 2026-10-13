import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TabSelector extends StatelessWidget {
  const TabSelector({
    super.key,
    required this.labels,
    this.selected = 0,
    this.dark = false,
  });

  final List<String> labels;
  final int selected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: i == selected
                ? (dark ? Colors.white : AppColors.brandBlack)
                : (dark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: dark ? Colors.white12 : AppColors.line),
          ),
          child: Text(
            labels[i],
            style: TextStyle(
              color: i == selected
                  ? (dark ? AppColors.brandBlack : Colors.white)
                  : (dark ? Colors.white70 : AppColors.textMuted),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
