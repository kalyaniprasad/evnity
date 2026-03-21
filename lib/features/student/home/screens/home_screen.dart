import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/mock_data/mock_data.dart';
import '../widgets/event_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(studentEventProvider);
    final user = ref.watch(currentUserProvider);

    return eventsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error loading events: $e'))),
      data: (events) {
        final featured = events.take(2).toList();
        final upcoming = events.skip(2).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StudentHeader(
              aliasName: user.aliasName,
              onSearchTap: () => context.goNamed('studentSearch'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Category Chips ──────────────────────────────────────
                _CategoryRow(),
                const SizedBox(height: 24),

                // ── Featured ────────────────────────────────────────────
                _SectionHeader(title: 'Featured Events', onSeeAll: () {}),
                const SizedBox(height: 14),
                ...featured.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EventCard(event: e),
                    )),

                // ── Upcoming ─────────────────────────────────────────────
                _SectionHeader(title: 'Upcoming Events', onSeeAll: () {}),
                const SizedBox(height: 14),
                ...upcoming.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EventCard(event: e, compact: true),
                    )),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      );
      },
    );
  }
}

// ── Student Header ────────────────────────────────────────────────────────────

class _StudentHeader extends StatelessWidget {
  final String aliasName;
  final VoidCallback onSearchTap;

  const _StudentHeader({
    required this.aliasName,
    required this.onSearchTap,
  });

  String get _initials {
    final words = aliasName.trim().split(' ');
    if (words.length == 1) {
      return aliasName.isNotEmpty
          ? aliasName.substring(0, aliasName.length.clamp(0, 2)).toUpperCase()
          : 'S';
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              // ── Initials Avatar ────────────────────────────────────
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: AppTextStyles.headingL
                        .copyWith(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Greeting + Name + Badge ────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            aliasName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingL
                                .copyWith(color: AppColors.white),
                          ),
                        ),
                        const SizedBox(width: 8),

                      ],
                    ),
                  ],
                ),
              ),

              // ── Action Icons ───────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.white,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Row ──────────────────────────────────────────────────────────────

class _CategoryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(searchProvider).selectedCategory;
    final notifier = ref.read(searchProvider.notifier);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = kCategories[i];
          final isActive = cat == selected;
          return GestureDetector(
            onTap: () => notifier.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headingL),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'See all',
            style: AppTextStyles.labelS.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
