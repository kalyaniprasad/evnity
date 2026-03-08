import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../onboarding_model.dart';

/// A single page in the onboarding PageView.
/// Stateless and fully driven by [OnboardingPageData].
class OnboardingSlide extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // ── Illustration ─────────────────────────────────────────────────
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: size.width * 0.50,
              height: size.width * 0.50,
              constraints: const BoxConstraints(
                maxWidth: 210,
                maxHeight: 210,
              ),
              decoration: BoxDecoration(
                color: data.iconBackground,
                borderRadius: BorderRadius.circular(52),
                boxShadow: [
                  BoxShadow(
                    color: data.iconColor.withOpacity(0.14),
                    blurRadius: 48,
                    offset: const Offset(0, 20),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  size: size.width * 0.22,
                  color: data.iconColor,
                ),
              ),
            ),
          ),

          const Spacer(flex: 2),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayM,
          ),
          const SizedBox(height: 16),

          // ── Subtitle ──────────────────────────────────────────────────────
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyM,
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
