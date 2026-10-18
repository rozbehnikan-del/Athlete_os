import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_theme.dart';

class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final size = windowClassOf(context);
    final theme = dark ? AppTheme.dark : Theme.of(context);
    return Theme(
      data: theme,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth(size)),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  size == WindowClass.compact ? AppSpacing.x4 : AppSpacing.x8,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
