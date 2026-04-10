import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/models/club_model.dart';

// ── Student Club Detail Screen ─────────────────────────────────────────────────
// Read-only view of a club's profile, accessible from the student search.

class StudentClubDetailScreen extends ConsumerWidget {
  final String clubId;
  const StudentClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubByIdProvider(clubId));

    if (club == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Club')),
        body: const Center(child: Text('Club not found')),
      );
    }

    // Events organised by this club
    final allEvents = ref.watch(studentEventProvider).valueOrNull ?? [];
    final clubEvents = allEvents.where((e) => e.hostClubId == club.id).toList();

    final catColor = _categoryColor(club.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            elevation: 0,
            backgroundColor: catColor,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ClubHeader(club: club, catColor: catColor),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats ──────────────────────────────────────────────
                  _SectionLabel('Club Stats'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.event_rounded,
                          value: '${club.eventCount}',
                          label: 'Events',
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_alt_rounded,
                          value: _formatCount(club.totalRegistrations),
                          label: 'Registrations',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.groups_rounded,
                          value: _formatCount(club.memberCount),
                          label: 'Members',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── About ──────────────────────────────────────────────
                  _SectionLabel('About'),
                  const SizedBox(height: 10),
                  _AboutCard(description: club.description),
                  const SizedBox(height: 28),

                  // ── Club Details ───────────────────────────────────────
                  _SectionLabel('Club Details'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: club.category,
                        catColor: catColor,
                      ),
                      _Divider(),
                      if (club.facultyMentor.isNotEmpty) ...[
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Faculty Mentor',
                          value: club.facultyMentor,
                          catColor: catColor,
                        ),
                        _Divider(),
                      ],
                      _InfoRow(
                        icon: Icons.groups_rounded,
                        label: 'Members',
                        value: '${club.memberCount} students',
                        catColor: catColor,
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.event_note_rounded,
                        label: 'Events Organised',
                        value: '${club.eventCount} total',
                        catColor: catColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Events by Club ─────────────────────────────────────
                  _SectionLabel('Events by ${club.name}'),
                  const SizedBox(height: 10),
                  if (clubEvents.isEmpty)
                    _EmptyCard(
                      icon: Icons.event_note_outlined,
                      message: 'No events yet',
                      sub: 'This club hasn\'t posted any events.',
                    )
                  else
                    ...clubEvents.map(
                      (e) => _EventRow(
                        title: e.title,
                        date: e.date,
                        category: e.category,
                        catColor: catColor,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  static Color _categoryColor(String cat) => switch (cat) {
    'Technical' => const Color(0xFF1E40AF),
    'Cultural' => const Color(0xFF7C3AED),
    'Sports' => const Color(0xFF059669),
    'Workshop' => const Color(0xFFD97706),
    'Seminar' => const Color(0xFFDB2777),
    _ => AppColors.primary,
  };
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ClubHeader extends StatelessWidget {
  final ClubModel club;
  final Color catColor;
  const _ClubHeader({required this.club, required this.catColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [catColor.withValues(alpha: 0.9), catColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Logo square
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  club.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Name + verified badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    club.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                club.category,
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

// ── Event Row ─────────────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final String title;
  final String date;
  final String category;
  final Color catColor;
  const _EventRow({
    required this.title,
    required this.date,
    required this.category,
    required this.catColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border(left: BorderSide(color: catColor, width: 4)),
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelM.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(date, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: catColor,
            ),
          ),
        ),
      ],
    ),
  );
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
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
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
        Text(
          value,
          style: AppTextStyles.labelM.copyWith(color: color, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
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
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Text(description, style: AppTextStyles.bodyM.copyWith(height: 1.7)),
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
          offset: Offset(0, 2),
        ),
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
  final Color catColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.catColor,
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
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: catColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.labelM.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.sub,
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
        Icon(icon, size: 36, color: AppColors.primaryMuted),
        const SizedBox(height: 10),
        Text(message, style: AppTextStyles.labelM),
        const SizedBox(height: 4),
        Text(sub, style: AppTextStyles.bodyS, textAlign: TextAlign.center),
      ],
    ),
  );
}
