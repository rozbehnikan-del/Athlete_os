import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_theme.dart';

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.dark = false,
    this.padding,
    this.maxWidth,
  });

  final Widget child;
  final bool dark;
  /// Optional screen-specific spacing; other pages keep their existing padding.
  final EdgeInsetsGeometry? padding;
  /// Optional narrower layout for Figma mobile-first surfaces on desktop.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = windowClassOf(context);
    final theme = dark ? AppTheme.dark : Theme.of(context);
    return Theme(
      data: theme,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth ?? maxContentWidth(size)),
              child: SingleChildScrollView(
                padding: padding ?? EdgeInsets.all(
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
