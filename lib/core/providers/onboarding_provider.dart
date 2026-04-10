import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the current onboarding page index.
/// Exposed as a [NotifierProvider] for testability and reactivity.
class OnboardingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Advance to next page if not already at the last.
  void next(int totalPages) {
    if (state < totalPages - 1) state++;
  }

  /// Jump to a specific page (used when syncing with PageController).
  void goTo(int index) => state = index;

  /// Reset to first page (called when re-entering onboarding).
  void reset() => state = 0;
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, int>(
  OnboardingNotifier.new,
);
