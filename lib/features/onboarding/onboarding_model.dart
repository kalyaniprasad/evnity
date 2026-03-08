import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Data model for a single onboarding page
class OnboardingPageData {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  const OnboardingPageData({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

/// All 3 onboarding pages
const List<OnboardingPageData> kOnboardingPages = [
  OnboardingPageData(
    icon: Icons.explore_rounded,
    iconBackground: AppColors.page1IconBg,
    iconColor: AppColors.page1Icon,
    title: 'Discover Campus Events',
    subtitle:
        'All your college events in one place. Browse fests, workshops, seminars, and sports — never miss out again.',
  ),
  OnboardingPageData(
    icon: Icons.groups_rounded,
    iconBackground: AppColors.page2IconBg,
    iconColor: AppColors.page2Icon,
    title: 'Connect & Participate',
    subtitle:
        'Register with one tap, join event discussions, and interact with organizers — all using your secure alias identity.',
  ),
  OnboardingPageData(
    icon: Icons.notifications_active_rounded,
    iconBackground: AppColors.page3IconBg,
    iconColor: AppColors.page3Icon,
    title: 'Stay in the Loop',
    subtitle:
        'Get real-time updates, reminders, and replies instantly. Your campus life, always up to date.',
  ),
];
