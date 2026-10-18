import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

BoxDecoration lightBoxDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surface,
  borderRadius: BorderRadius.circular(AppRadii.xl),
  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
);

BoxDecoration darkBoxDecoration() => BoxDecoration(
  color: AppColors.darkSurface,
  borderRadius: BorderRadius.circular(AppRadii.lg),
  border: Border.all(color: Colors.white10),
);
