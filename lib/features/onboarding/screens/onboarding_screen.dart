import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../onboarding_model.dart';
import '../widgets/onboarding_slide.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Reset to page 0 whenever onboarding is entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(int currentIndex) {
    final total = kOnboardingPages.length;
    if (currentIndex < total - 1) {
      ref.read(onboardingProvider.notifier).next(total);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    ref.read(onboardingProvider.notifier).reset();
    context.goNamed('auth');
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(onboardingProvider);
    final isLastPage = currentIndex == kOnboardingPages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar: Skip ─────────────────────────────────────────────
            _TopBar(isLastPage: isLastPage, onSkip: _goToAuth),

            // ── PageView ──────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: kOnboardingPages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  ref.read(onboardingProvider.notifier).goTo(index);
                },
                itemBuilder: (context, index) {
                  return OnboardingSlide(data: kOnboardingPages[index]);
                },
              ),
            ),

            // ── Bottom: Dots + Button ─────────────────────────────────────
            _BottomControls(
              pageController: _pageController,
              isLastPage: isLastPage,
              onNext: () => _onNext(currentIndex),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onSkip;

  const _TopBar({required this.isLastPage, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand mark (top left)
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Evnity',
                style: AppTextStyles.headingM.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Skip button
          AnimatedOpacity(
            opacity: isLastPage ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: isLastPage ? null : onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.divider),
                ),
              ),
              child: Text(
                'Skip',
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final PageController pageController;
  final bool isLastPage;
  final VoidCallback onNext;

  const _BottomControls({
    required this.pageController,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        children: [
          // Page Indicator
          SmoothPageIndicator(
            controller: pageController,
            count: kOnboardingPages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.primaryMuted.withOpacity(0.28),
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3.5,
              spacing: 6,
            ),
          ),
          const SizedBox(height: 32),

          // CTA Button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: PrimaryButton(
              key: ValueKey(isLastPage),
              label: isLastPage ? 'Get Started' : 'Next',
              icon: isLastPage
                  ? Icons.arrow_forward_rounded
                  : Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
