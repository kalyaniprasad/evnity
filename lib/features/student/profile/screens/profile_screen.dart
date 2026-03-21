import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/event_model.dart';

// ── Student Profile Screen ─────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final allEventsAsync = ref.watch(studentEventProvider);

    return allEventsAsync.when(
      loading: () => const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (allEvents) {
        final registeredEvents = allEvents.where((e) => user.registeredEventIds.contains(e.id)).toList();

    // Derive initials safely
    final initials = user.aliasName.isNotEmpty
        ? user.aliasName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header (expandable) ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHeader(
                initials: initials,
                aliasName: user.aliasName,
                email: user.email,
                role: user.role,
              ),
            ),
            // Action button always visible when collapsed
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/student/profile/edit'),
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
                  _SectionLabel('Overview'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.event_available_rounded,
                          value: '${registeredEvents.length}',
                          label: 'Registered',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '${registeredEvents.length}',
                          label: 'Attended',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star_outline_rounded,
                          value: user.role[0].toUpperCase() +
                              user.role.substring(1),
                          label: 'Role',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Account Details ─────────────────────────────────────
                  _SectionLabel('Account Details'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Alias Name',
                      value: user.aliasName,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Full Name',
                      value: user.aliasName,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email.isNotEmpty
                          ? user.email
                          : 'Not available',
                      valueColor: AppColors.textMuted,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.school_outlined,
                      label: 'Branch',
                      value: user.branch ?? 'Computer Science',
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Academic Year',
                      value: user.year ?? 'First Year',
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Bio',
                      value: (user.bio == null || user.bio!.isEmpty)
                          ? 'Passionate about technology and innovation.'
                          : user.bio!,
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Registered Events ───────────────────────────────────
                  Row(
                    children: [
                      _SectionLabel('Registered Events'),
                      const Spacer(),
                      if (registeredEvents.isNotEmpty)
                        _CountBadge('${registeredEvents.length}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (registeredEvents.isEmpty)
                    _EmptyCard(
                      icon: Icons.event_busy_outlined,
                      message: 'No events registered yet.',
                      subMessage: 'Browse upcoming events and register!',
                    )
                  else
                    ...registeredEvents
                        .map((e) => _RegisteredEventCard(event: e)),

                  const SizedBox(height: 28),

                  // ── Actions ─────────────────────────────────────────────
                  _SectionLabel('Actions'),
                  const SizedBox(height: 10),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () => context.push('/student/profile/edit'),
                  ),
                  const SizedBox(height: 10),
                  _LogoutButton(ref: ref),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    });
  }
}

// ── Profile Header Widget ─────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String aliasName;
  final String email;
  final String role;

  const _ProfileHeader({
    required this.initials,
    required this.aliasName,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3697), Color(0xFF3B60D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Avatar circle
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 2.5),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              aliasName.isNotEmpty ? aliasName : 'Student',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            // Email pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                email.isNotEmpty ? email : 'student@evnity.app',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Role chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_rounded,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Logout Button (with Firebase signOut) ─────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  final WidgetRef ref;
  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, widgetRef),
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

// ── Shared Sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.headingM.copyWith(fontSize: 16));
}

class _CountBadge extends StatelessWidget {
  final String count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(count,
            style: AppTextStyles.labelS.copyWith(color: AppColors.primary)),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelM
                    .copyWith(color: color, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center),
          ],
        ),
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
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))
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
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

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
                  Text(
                    value,
                    style: AppTextStyles.labelM.copyWith(
                      fontSize: 14,
                      color: valueColor,
                    ),
                  ),
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

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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

// ── Registered Event Card ─────────────────────────────────────────────────────

class _RegisteredEventCard extends StatelessWidget {
  final EventModel event;
  const _RegisteredEventCard({required this.event});

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
            // Image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                event.posterUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.primaryMuted),
                ),
              ),
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
                  Text(event.clubName,
                      style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _CategoryChip(event.category),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(event.date, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            // Going badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: AppColors.success),
                  SizedBox(width: 3),
                  Text('Going',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip(this.category);

  Color get chipColor {
    switch (category) {
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

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: chipColor,
          ),
        ),
      );
}

// ── Empty Card ────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.subMessage,
  });

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
