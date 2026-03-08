import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));

    if (event == null) {
      return const Scaffold(
        body: Center(child: Text('Event not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Image AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.35),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
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
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.image_outlined,
                          size: 60, color: AppColors.primaryMuted),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Registered
                  Row(
                    children: [
                      _CategoryChip(category: event.category),
                      const SizedBox(width: 8),
                      if (event.isRegistered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF16A34A).withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'You\'re Registered',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(event.title, style: AppTextStyles.displayM),
                  const SizedBox(height: 20),

                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                          child: _InfoTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: event.date,
                          )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _InfoTile(
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: event.time,
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.location_on_rounded,
                    label: 'Venue',
                    value: event.venue,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.groups_rounded,
                    label: 'Organised by',
                    value: event.clubName,
                    fullWidth: true,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.people_rounded,
                    label: 'Registrations',
                    value: '${event.registrationCount} students registered',
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text('About this Event', style: AppTextStyles.headingL),
                  const SizedBox(height: 10),
                  Text(event.description, style: AppTextStyles.bodyL),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _RegisterButton(event: event, ref: ref),
                  const SizedBox(height: 12),
                  _DiscussionButton(eventId: eventId),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelM.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
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

// ── Category Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  Color get _color => switch (category) {
    'Technical' => const Color(0xFF1E40AF),
    'Cultural' => const Color(0xFF7C3AED),
    'Sports' => const Color(0xFF059669),
    'Workshop' => const Color(0xFFD97706),
    'Seminar' => const Color(0xFFDB2777),
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}

// ── Register Button ───────────────────────────────────────────────────────────

class _RegisterButton extends StatelessWidget {
  final dynamic event;
  final WidgetRef ref;
  const _RegisterButton({required this.event, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () =>
            ref.read(studentEventProvider.notifier).toggleRegistration(event.id),
        style: ElevatedButton.styleFrom(
          backgroundColor:
          event.isRegistered ? const Color(0xFF16A34A) : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(
          event.isRegistered
              ? Icons.check_circle_rounded
              : Icons.app_registration_rounded,
          size: 20,
        ),
        label: Text(
          event.isRegistered ? 'Registered ✓' : 'Register for Event',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Discussion Button ─────────────────────────────────────────────────────────

class _DiscussionButton extends StatelessWidget {
  final String eventId;
  const _DiscussionButton({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/event/$eventId/discussion'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.forum_outlined, size: 20),
        label: const Text(
          'Join Discussion',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}