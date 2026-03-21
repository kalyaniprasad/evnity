import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../providers/club_providers.dart';
import '../../models/club_event.dart';
import '../../../../core/providers/student_providers.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/club_event_card.dart';

class ClubDashboardScreen extends ConsumerWidget {
  const ClubDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(clubEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];
    final stats = ref.watch(clubStatsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final published =
        events.where((e) => e.status == EventStatus.published).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: DashboardHeader(
              clubName: ref.watch(clubProfileProvider).name.isNotEmpty 
                ? ref.watch(clubProfileProvider).name 
                : (currentUser.aliasName.isNotEmpty ? currentUser.aliasName : 'Your Club'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Quick Actions ──────────────────────────────────────────
                Text('Quick Actions', style: AppTextStyles.headingM),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _QuickActionBtn(
                      label: 'Announcement',
                      icon: Icons.campaign_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push('/club/announcement'),
                    ),
                    const SizedBox(width: 12),
                    _QuickActionBtn(
                      label: 'Create Event',
                      icon: Icons.add_circle_outline_rounded,
                      color: AppColors.success,
                      onTap: () => context.go('/club/create'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Stats Row ────────────────────────────────────────────
                Text('Overview', style: AppTextStyles.headingM),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: '${stats.activeEvents}',
                        label: 'Active Events',
                        icon: Icons.event_available_rounded,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.primarySurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        value: '${stats.totalRegistrations}',
                        label: 'Registrations',
                        icon: Icons.people_rounded,
                        iconColor: AppColors.success,
                        iconBg: AppColors.successSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        value: '${stats.unreadMessages}',
                        label: 'Messages',
                        icon: Icons.forum_rounded,
                        iconColor: AppColors.warning,
                        iconBg: AppColors.warningSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Upcoming Events ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming Events', style: AppTextStyles.headingM),
                    TextButton(
                      onPressed: () => context.go('/club/manage'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('See all',
                          style: AppTextStyles.labelS
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (published.isEmpty)
                  _EmptyState(onTap: () => context.go('/club/create'))
                else
                  ...published.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClubEventCard(
                          event: e,
                          onDelete: () => ref
                              .read(eventRepositoryProvider)
                              .deleteEvent(e.id),
                        ),
                      )),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.event_note_rounded,
                size: 36, color: AppColors.primaryMuted),
          ),
          const SizedBox(height: 16),
          Text('No events yet', style: AppTextStyles.headingM),
          const SizedBox(height: 6),
          Text(
            'Create your first event to get started.',
            style: AppTextStyles.bodyS,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 170,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Event',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.labelS),
            ],
          ),
        ),
      ),
    );
  }
}
