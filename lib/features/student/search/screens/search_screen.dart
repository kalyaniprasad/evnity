import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/mock_data/mock_data.dart';
import '../../../../core/models/club_model.dart';
import '../../../student/home/widgets/event_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.read(searchProvider.notifier);
    final filteredEvents = ref.watch(filteredEventsProvider);
    final filteredClubs = ref.watch(filteredClubsProvider);
    final hasQuery = searchState.query.isNotEmpty;
    final hasFilter = hasQuery || searchState.selectedCategory != 'All';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Discover', style: AppTextStyles.headingL),
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Search Bar ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: searchNotifier.setQuery,
                  style: AppTextStyles.bodyM
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search events, clubs, categories...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 22),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              searchNotifier.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Category Filter Chips ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categories', style: AppTextStyles.headingM),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCategories.map((cat) {
                      final isSelected =
                          cat == searchState.selectedCategory;
                      return GestureDetector(
                        onTap: () => searchNotifier.setCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcon(cat),
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Popular Clubs (browse state — no query, no category filter) ──
          if (!hasFilter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Popular Clubs', style: AppTextStyles.headingM),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kMockClubs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) => _ClubCard(
                          club: kMockClubs[i],
                          onTap: () =>
                              context.push('/student/club/${kMockClubs[i].id}'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Clubs Result Section (when a filter or query is active) ───
          if (hasFilter && filteredClubs.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ResultHeader(
                    label: 'Clubs',
                    count: filteredClubs.length,
                    iconColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  ...filteredClubs.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ClubSearchCard(
                          club: c,
                          onTap: () =>
                              context.push('/student/club/${c.id}'),
                        ),
                      )),
                ]),
              ),
            ),

          // ── Events Result Section ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ResultHeader(
                  label: 'Events',
                  count: filteredEvents.length,
                  iconColor: AppColors.success,
                ),
                const SizedBox(height: 12),
                if (filteredEvents.isEmpty)
                  _EmptyState(query: searchState.query)
                else
                  ...filteredEvents.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: EventCard(event: e, compact: true),
                      )),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) => switch (cat) {
        'Technical' => Icons.code_rounded,
        'Cultural' => Icons.palette_rounded,
        'Sports' => Icons.sports_basketball_rounded,
        'Workshop' => Icons.build_rounded,
        'Seminar' => Icons.mic_rounded,
        _ => Icons.grid_view_rounded,
      };
}

// ── Result Header (count badge) ───────────────────────────────────────────────

class _ResultHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color iconColor;
  const _ResultHeader(
      {required this.label, required this.count, required this.iconColor});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: AppTextStyles.headingM),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelS.copyWith(color: iconColor),
            ),
          ),
        ],
      );
}

// ── Club Search Card (appears in search results) ──────────────────────────────

class _ClubSearchCard extends StatelessWidget {
  final ClubModel club;
  final VoidCallback onTap;
  const _ClubSearchCard({required this.club, required this.onTap});

  Color get _catColor => switch (club.category) {
        'Technical' => const Color(0xFF1E40AF),
        'Cultural' => const Color(0xFF7C3AED),
        'Sports' => const Color(0xFF059669),
        'Workshop' => const Color(0xFFD97706),
        'Seminar' => const Color(0xFFDB2777),
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _catColor, width: 4)),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Initials logo
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  club.initials,
                  style: TextStyle(
                    color: _catColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name,
                      style: AppTextStyles.labelM,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          club.category,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _catColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.groups_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${club.memberCount} members',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Club Card (horizontal browse) ─────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final ClubModel club;
  final VoidCallback onTap;
  const _ClubCard({required this.club, required this.onTap});

  Color get _catColor => switch (club.category) {
        'Technical' => const Color(0xFF1E40AF),
        'Cultural' => const Color(0xFF7C3AED),
        'Sports' => const Color(0xFF059669),
        'Workshop' => const Color(0xFFD97706),
        'Seminar' => const Color(0xFFDB2777),
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      club.initials,
                      style: TextStyle(
                          color: _catColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    club.category,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _catColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              club.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelM.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${club.eventCount} events',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 40, color: AppColors.primaryMuted),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No events in this category'
                  : 'No events for "$query"',
              style: AppTextStyles.headingM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or category.',
              style: AppTextStyles.bodyS,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}