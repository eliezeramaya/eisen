import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final bool showFabCoachmark;
  const OnboardingState({required this.showFabCoachmark});
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState(showFabCoachmark: false);
  void dismissFabCoachmark() => state = const OnboardingState(showFabCoachmark: false);
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
