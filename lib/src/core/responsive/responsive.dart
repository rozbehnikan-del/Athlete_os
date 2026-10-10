import 'package:flutter/material.dart';

enum WindowClass { compact, medium, expanded }

WindowClass windowClassOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return WindowClass.compact;
  if (width < 1024) return WindowClass.medium;
  return WindowClass.expanded;
}

double maxContentWidth(WindowClass size) {
  switch (size) {
    case WindowClass.compact:
      return 430;
    case WindowClass.medium:
      return 920;
    case WindowClass.expanded:
      return 1180;
  }
}
