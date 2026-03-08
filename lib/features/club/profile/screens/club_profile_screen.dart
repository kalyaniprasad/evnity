import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/auth_service.dart';
import '../../providers/club_providers.dart';
import '../../models/models.dart';

// ── Club Profile Screen ────────────────────────────────────────────────────────

class ClubProfileScreen extends ConsumerWidget {
  const ClubProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clubProfileProvider);
    final stats = ref.watch(clubStatsProvider);
    final events = ref.watch(clubEventsProvider);

    // Up to 3 most recent events for the overview
    final recentEvents = events.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ClubHeader(profile: profile),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/club/profile/edit'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats Row ──────────────────────────────────────────
                  _SectionLabel('Club Overview'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.event_rounded,
                          value: '${stats.totalEvents}',
                          label: 'Events Created',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_alt_rounded,
                          value: '${stats.totalRegistrations}',
                          label: 'Registrations',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bolt_rounded,
                          value: '${stats.activeEvents}',
                          label: 'Active Now',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── About ──────────────────────────────────────────────
                  _SectionLabel('About'),
                  const SizedBox(height: 10),
                  _AboutCard(description: profile.description),
                  const SizedBox(height: 28),

                  // ── Club Details ───────────────────────────────────────
                  _SectionLabel('Club Details'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Contact Email',
                      value: profile.email,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: profile.category,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Faculty Mentor',
                      value: profile.facultyMentor,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Founded',
                      value: profile.founded,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: profile.location,
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Recent Events ──────────────────────────────────────
                  _SectionLabel('Recent Events'),
                  const SizedBox(height: 10),
                  if (recentEvents.isEmpty)
                    _EmptyCard(
                      icon: Icons.event_note_outlined,
                      message: 'No events yet.',
                      subMessage: 'Create your first event to get started!',
                    )
                  else
                    ...recentEvents
                        .map((e) => _ClubEventCard(event: e)),
                  const SizedBox(height: 28),

                  // ── Actions ────────────────────────────────────────────
                  _SectionLabel('Actions'),
                  const SizedBox(height: 10),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Club Profile',
                    onTap: () => context.push('/club/profile/edit'),
                  ),
                  const SizedBox(height: 10),
                  // FIX: Club logout now calls Firebase signOut
                  _ClubLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Club Header ───────────────────────────────────────────────────────────────

class _ClubHeader extends StatelessWidget {
  final ClubProfileModel profile;
  const _ClubHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3697), Color(0xFF2D55C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Club logo (rounded square with initials)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 2.5),
              ),
              child: Center(
                child: Text(
                  profile.initials,
                  style: AppTextStyles.headingXL
                      .copyWith(color: Colors.white, fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Club name + verified badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 10, color: Colors.white),
                      SizedBox(width: 3),
                      Text('Verified',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Tagline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                profile.tagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            // Category chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                profile.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Club Logout Button (FIXED) ────────────────────────────────────────────────

class _ClubLogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Log Out',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: AppTextStyles.headingM),
        content: Text('Are you sure you want to log out?',
            style: AppTextStyles.bodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // FIX: Actually sign out from Firebase + Google.
                // RouterNotifier detects the auth change and redirects to /auth.
                await ref.read(authServiceProvider).signOut();
                ref.invalidate(authFormProvider);
              } catch (e) {
                if (context.mounted) {
                  showAppSnackbar(context, 'Sign-out failed: $e',
                      type: SnackbarType.error);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ── Club Event Card ───────────────────────────────────────────────────────────

class _ClubEventCard extends StatelessWidget {
  final ClubEvent event;
  const _ClubEventCard({required this.event});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Icon colored by category
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _catColor(event.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_rounded,
                  color: _catColor(event.category), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelM),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(event.date, style: AppTextStyles.caption),
                      const SizedBox(width: 10),
                      const Icon(Icons.people_alt_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text('${event.registrationCount}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: event.status == EventStatus.published
                    ? AppColors.successSurface
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                event.status == EventStatus.published ? 'Live' : 'Draft',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: event.status == EventStatus.published
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );

  Color _catColor(String cat) {
    switch (cat) {
      case 'Technical':
        return AppColors.primary;
      case 'Cultural':
        return AppColors.categoryCultural;
      case 'Sports':
        return AppColors.success;
      case 'Workshop':
        return AppColors.warning;
      default:
        return AppColors.categorySeminar;
    }
  }
}

// ── Shared Sub-Widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.headingM.copyWith(fontSize: 16));
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(value,
                style:
                    AppTextStyles.labelM.copyWith(color: color, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _AboutCard extends StatelessWidget {
  final String description;
  const _AboutCard({required this.description});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Text(description,
            style: AppTextStyles.bodyM.copyWith(height: 1.7)),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.borderLight,
        indent: 56,
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.labelM.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;
  const _EmptyCard(
      {required this.icon,
      required this.message,
      required this.subMessage});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.primaryMuted),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.labelM),
            const SizedBox(height: 4),
            Text(subMessage,
                style: AppTextStyles.bodyS, textAlign: TextAlign.center),
          ],
        ),
      );
}
