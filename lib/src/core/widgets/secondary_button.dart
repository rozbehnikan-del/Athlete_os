import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.dark = false,
  });

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      child: Text(label),
    );
  }
}
