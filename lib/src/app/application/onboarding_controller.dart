import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() {
    state = true;
  }
}
