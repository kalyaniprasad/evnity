import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _textFadeAnim;
  late final Animation<double> _textSlideAnim;
  late final Animation<double> _floatingAnim;
  late final Animation<double> _shadowOpacityAnim;

  @override
  void initState() {
    super.initState();

    // Entrance Controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Floating Controller (Repeats)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo Entrance Animations - Start at 1.0 to ensure instant visibility
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutQuint),
    );

    // Shadow animation for the "lift"
    _shadowOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Text Animations (Staggered)
    _textFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
    );

    _textSlideAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    );

    // Floating/Breathing (Starts after entrance)
    _floatingAnim = Tween<double>(begin: 0, end: -12.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entranceController.forward().then((_) {
      _floatController.repeat(reverse: true);
    });

    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) context.goNamed('onboarding');
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Subtle Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  AppColors.white,
                  AppColors.background,
                  AppColors.surfaceAlt.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Elevated Logo Area
                AnimatedBuilder(
                  animation: Listenable.merge([_entranceController, _floatController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        (30 * (1.0 - _slideAnim.value)) + _floatingAnim.value,
                      ),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            // Deep Ambient Shadow
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12 * _shadowOpacityAnim.value),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                              spreadRadius: -5,
                            ),
                            // Direct Elevation Shadow
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08 * _shadowOpacityAnim.value),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            // Subtle Rim Light / Glow
                            BoxShadow(
                              color: AppColors.white.withValues(alpha: 0.8 * _shadowOpacityAnim.value),
                              blurRadius: 2,
                              offset: const Offset(0, -1),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'app_logo',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/icons/logo_padded.jpeg',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Name & Tagline Group
                FadeTransition(
                  opacity: _textFadeAnim,
                  child: AnimatedBuilder(
                    animation: _textSlideAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1.0 - _textSlideAnim.value)),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'Evnity',
                          style: AppTextStyles.brandName.copyWith(
                            letterSpacing: 4 * (1.0 - _textFadeAnim.value),
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your Campus, Connected.',
                          style: AppTextStyles.brandTagline.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Subtle Status Indicator
                FadeTransition(
                  opacity: _textFadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 110),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

