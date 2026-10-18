import 'package:flutter/material.dart';

class TabSelector extends StatelessWidget {
  const TabSelector({
    super.key,
    required this.labels,
    this.selected = 0,
    this.dark = false,
    this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final bool dark;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: onSelected == null ? null : () => onSelected!(i),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: i == selected
                  ? (dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary)
                  : (dark
                        ? Colors.white10
                        : Theme.of(context).colorScheme.surface),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: dark
                    ? Colors.white12
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                color: i == selected
                    ? (dark
                          ? const Color(0xFF141719)
                          : Theme.of(context).colorScheme.onPrimary)
                    : (dark
                          ? Colors.white70
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
