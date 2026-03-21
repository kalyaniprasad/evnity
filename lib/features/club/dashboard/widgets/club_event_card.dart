import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../models/club_event.dart';
import 'event_status_badge.dart';

class ClubEventCard extends StatelessWidget {
  final ClubEvent event;
  final VoidCallback? onDelete;

  const ClubEventCard({
    super.key,
    required this.event,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Poster ───────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  event.posterUrl,
                  height: 158,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 158,
                    color: AppColors.primarySurface,
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          size: 40, color: AppColors.primaryMuted),
                    ),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 158,
                          color: AppColors.surfaceAlt,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CategoryBadge(category: event.category),
                        if (event.currentTimingStatus == EventTimingStatus.live) ...[
                          const SizedBox(width: 8),
                          const LiveBadge(),
                        ]
                      ],
                    )),
                Positioned(
                    top: 12,
                    right: 12,
                    child: EventStatusBadge(status: event.status)),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingM),
                const SizedBox(height: 8),
                _MetaRow(
                    icon: Icons.calendar_today_rounded,
                    text: '${event.date}  ·  ${event.time}'),
                const SizedBox(height: 4),
                _MetaRow(
                    icon: Icons.location_on_rounded, text: event.venue),
                const SizedBox(height: 12),

                // Stats pills
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.people_outline_rounded,
                      label: '${event.registrationCount} registered',
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      icon: Icons.forum_outlined,
                      label: '${event.messageCount} msgs',
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(
                    color: AppColors.divider, thickness: 1, height: 1),
                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    Expanded(
                      child: _CardAction(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: AppColors.primary,
                        bg: AppColors.primarySurface,
                        onTap: () => context
                            .push('/club/event/${event.id}/edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CardAction(
                        icon: Icons.forum_outlined,
                        label: 'Discussion',
                        color: AppColors.textSecondary,
                        bg: AppColors.surfaceAlt,
                        onTap: () => context
                            .push('/club/event/${event.id}/discussion'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyS),
          ),
        ],
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      );
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
      );
}
