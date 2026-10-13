import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setMobileViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
