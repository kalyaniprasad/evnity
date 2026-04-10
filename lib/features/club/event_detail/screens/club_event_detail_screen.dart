import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../providers/club_providers.dart';
import '../../models/club_event.dart';
import '../../../../core/repositories/event_repository.dart';
import '../../dashboard/widgets/event_status_badge.dart';
import 'event_registrations_screen.dart';

class ClubEventDetailScreen extends ConsumerWidget {
  final String eventId;
  const ClubEventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(clubEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];
    final event = events.where((e) => e.id == eventId).firstOrNull;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Event'),
        ),
        body: Center(
          child: Text('Event not found.', style: AppTextStyles.bodyL),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: AppColors.primaryDark.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: AppColors.primarySurface),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primaryDark.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      EventStatusBadge(status: event.status),
                      const SizedBox(width: 8),
                      _CategoryChip(category: event.category),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(event.title, style: AppTextStyles.displayM),
                  const SizedBox(height: 20),

                  // Info tiles grid
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: event.date,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: event.time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.location_on_rounded,
                    label: 'Venue',
                    value: event.venue,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.people_rounded,
                          label: 'Registered',
                          value: '${event.registrationCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.forum_rounded,
                          label: 'Messages',
                          value: '${event.messageCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('Description', style: AppTextStyles.headingM),
                  const SizedBox(height: 8),
                  Text(event.description, style: AppTextStyles.bodyL),
                  const SizedBox(height: 28),

                  // ── Actions ───────────────────────────────────────────
                  Text('Actions', style: AppTextStyles.headingM),
                  const SizedBox(height: 14),

                  _ActionTile(
                    icon: event.status == EventStatus.published
                        ? Icons.unpublished_outlined
                        : Icons.publish_rounded,
                    title: event.status == EventStatus.published
                        ? 'Move to Draft'
                        : 'Publish Event',
                    subtitle: event.status == EventStatus.published
                        ? 'Hide from students'
                        : 'Make visible to all students',
                    iconColor: event.status == EventStatus.published
                        ? AppColors.warning
                        : AppColors.success,
                    iconBg: event.status == EventStatus.published
                        ? AppColors.warningSurface
                        : AppColors.successSurface,
                    onTap: () {
                      // Status toggling requires updateEvent in EventRepository.
                      // Leaving unimplemented as UI mock.
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.people_outline_rounded,
                    title: 'View Registrations',
                    subtitle: '${event.registrationCount} students registered',
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primarySurface,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventRegistrationsScreen(eventId: event.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.campaign_outlined,
                    title: 'Notify Registered Users',
                    subtitle: 'Send a quick update to participants',
                    iconColor: AppColors.success,
                    iconBg: AppColors.successSurface,
                    onTap: () =>
                        context.push('/club/event/${event.id}/announcement'),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.forum_outlined,
                    title: 'Open Discussion',
                    subtitle:
                        '${event.messageCount} messages from participants',
                    iconColor: AppColors.categoryCultural,
                    iconBg: AppColors.categoryCulturalBg,
                    onTap: () =>
                        context.push('/club/event/${event.id}/discussion'),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Event',
                    subtitle: 'This action cannot be undone',
                    iconColor: AppColors.error,
                    iconBg: AppColors.errorSurface,
                    onTap: () => _confirmDelete(context, ref, event.id),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Event', style: AppTextStyles.headingM),
        content: Text(
          'This action cannot be undone.',
          style: AppTextStyles.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(eventRepositoryProvider).deleteEvent(id);
              Navigator.pop(context);
              context.go('/club/manage');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.labelM.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelM.copyWith(color: iconColor),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: iconColor.withOpacity(0.45),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  Color get _color => switch (category) {
    'Technical' => AppColors.primary,
    'Cultural' => AppColors.categoryCultural,
    'Sports' => AppColors.success,
    'Workshop' => AppColors.warning,
    'Seminar' => AppColors.categorySeminar,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Text(
      category,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _color,
      ),
    ),
  );
}
