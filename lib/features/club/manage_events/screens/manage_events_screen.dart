import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../providers/club_providers.dart';
import '../../models/club_event.dart';
import '../../dashboard/widgets/club_event_card.dart';

class ManageEventsScreen extends ConsumerStatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  ConsumerState<ManageEventsScreen> createState() =>
      _ManageEventsScreenState();
}

class _ManageEventsScreenState extends ConsumerState<ManageEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(clubEventsProvider);
    final published =
        all.where((e) => e.status == EventStatus.published).toList();
    final drafts =
        all.where((e) => e.status == EventStatus.draft).toList();
    final notifier = ref.read(clubEventsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Manage Events', style: AppTextStyles.headingL),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.go('/club/create'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: AppColors.white, size: 16),
                    SizedBox(width: 4),
                    Text('New',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.labelM.copyWith(fontSize: 13),
              unselectedLabelStyle:
                  AppTextStyles.labelM.copyWith(fontSize: 13),
              tabs: [
                Tab(text: 'All (${all.length})'),
                Tab(text: 'Live (${published.length})'),
                Tab(text: 'Drafts (${drafts.length})'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EventList(
              events: all,
              onDelete: notifier.deleteEvent),
          _EventList(
              events: published,
              onDelete: notifier.deleteEvent),
          _EventList(
              events: drafts,
              onDelete: notifier.deleteEvent),
        ],
      ),
    );
  }
}

// ── Event List Tab ────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<ClubEvent> events;
  final ValueChanged<String> onDelete;

  const _EventList({required this.events, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.event_busy_outlined,
                  size: 36, color: AppColors.primaryMuted),
            ),
            const SizedBox(height: 16),
            Text('Nothing here yet', style: AppTextStyles.headingM),
            const SizedBox(height: 6),
            Text('Create a new event to see it here.',
                style: AppTextStyles.bodyS),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) => ClubEventCard(
        event: events[i],
        onDelete: () => onDelete(events[i].id),
      ),
    );
  }
}
