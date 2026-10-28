import 'package:flutter/material.dart';

import '../../../core/theme/figma_v1_tokens.dart';

/// Figma CrossFit V1 AMRAP counter, node 2:94.
/// This edits an existing scored-reps field, not an invented movement counter.
class FigmaScoreCounter extends StatelessWidget {
  const FigmaScoreCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = value < 0 ? 0 : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FigmaV1Tokens.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _CounterButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Decrease $label',
                  enabled: safeValue > 0,
                  onPressed: () => onChanged(safeValue - 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FigmaV1Tokens.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$safeValue',
                    key: const Key('figma-score-counter-value'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _CounterButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Increase $label',
                  enabled: safeValue < 99999,
                  onPressed: () => onChanged(safeValue + 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF1F3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: Center(
            child: Icon(
              icon,
              color: enabled
                  ? FigmaV1Tokens.primary
                  : FigmaV1Tokens.muted,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
