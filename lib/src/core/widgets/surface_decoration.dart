import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

BoxDecoration lightBoxDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(AppRadii.xl),
  border: Border.all(color: AppColors.line),
);

BoxDecoration darkBoxDecoration() => BoxDecoration(
  color: AppColors.darkSurface,
  borderRadius: BorderRadius.circular(AppRadii.lg),
  border: Border.all(color: Colors.white10),
);
