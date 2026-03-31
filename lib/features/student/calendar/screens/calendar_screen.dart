import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/providers/student_providers.dart';
import '../widgets/calendar_event_card.dart';
import '../providers/calendar_provider.dart';

// ── Date Helpers ──────────────────────────────────────────────────────────────
const _monthMap = {
  'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,  'May': 5,  'Jun': 6,
  'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
};

DateTime? _parseMockDate(String date) {
  try {
    final clean = date.contains(',') ? date.split(', ').last.trim() : date.trim();
    final parts  = clean.split(' ');
    return DateTime(int.parse(parts[2]), _monthMap[parts[1]] ?? 1, int.parse(parts[0]));
  } catch (_) {
    return null;
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _months = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _catOrder = ['Technical', 'Cultural', 'Sports', 'Workshop', 'Seminar'];

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _listCtrl;
  late Animation<double>   _listFade;
  late Animation<Offset>   _listSlide;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _listFade  = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);
    _listSlide = Tween<Offset>(
        begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _listCtrl, curve: Curves.easeOutCubic));
    _listCtrl.forward();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  List<EventModel> _eventsForDay(DateTime day, List<EventModel> all) =>
      all.where((e) {
        final d = _parseMockDate(e.date);
        return d != null && _isSameDay(d, day);
      }).toList();

  void _selectDay(DateTime day) {
    ref.read(calendarSelectedDateProvider.notifier).state = day;
    ref.read(calendarFocusedDateProvider.notifier).state  = day;
    _listCtrl..reset()..forward();
  }

  @override
  Widget build(BuildContext context) {
    final selected  = ref.watch(calendarSelectedDateProvider);
    final focused   = ref.watch(calendarFocusedDateProvider);
    final all       = ref.watch(studentEventProvider).valueOrNull ?? [];
    final dayEvents = _eventsForDay(selected, all);

    final busyDays = all
        .map((e) => _parseMockDate(e.date))
        .whereType<DateTime>()
        .where((d) => d.month == focused.month && d.year == focused.year)
        .map((d) => d.day)
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.cardShadow,
            title: Row(
              children: [
                Text('Campus Calendar', style: AppTextStyles.headingL),
              ],
            ),
          ),

          // ── Calendar Card ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Custom month header ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 4),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_months[focused.month]} ${focused.year}',
                              style: AppTextStyles.headingL,
                            ),
                            Text(
                              '$busyDays days with events',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Today button
                        GestureDetector(
                          onTap: () => _selectDay(DateTime.now()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.primaryBorder),
                            ),
                            child: Text(
                              'Today',
                              style: AppTextStyles.labelS.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _NavBtn(
                          icon: Icons.chevron_left_rounded,
                          onTap: () {
                            ref.read(calendarFocusedDateProvider.notifier).state =
                                DateTime(focused.year, focused.month - 1);
                          },
                        ),
                        const SizedBox(width: 4),
                        _NavBtn(
                          icon: Icons.chevron_right_rounded,
                          onTap: () {
                            ref.read(calendarFocusedDateProvider.notifier).state =
                                DateTime(focused.year, focused.month + 1);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── TableCalendar ─────────────────────────────────────────
                  TableCalendar<EventModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay:  DateTime.utc(2030, 12, 31),
                    focusedDay:  focused,
                    selectedDayPredicate: (d) => _isSameDay(d, selected),
                    calendarFormat: CalendarFormat.month,
                    eventLoader:   (d) => _eventsForDay(d, all),
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    headerVisible: false,

                    daysOfWeekStyle: DaysOfWeekStyle(
                      dowTextFormatter: (date, _) {
                        const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                        return labels[date.weekday % 7];
                      },
                      weekdayStyle: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      weekendStyle: AppTextStyles.caption.copyWith(
                        color: AppColors.primary.withOpacity(0.5),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),

                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: BoxDecoration(color: Colors.transparent),
                      todayDecoration:    BoxDecoration(color: Colors.transparent),
                      markerDecoration:   BoxDecoration(color: Colors.transparent),
                      defaultTextStyle:   TextStyle(color: Colors.transparent),
                      weekendTextStyle:   TextStyle(color: Colors.transparent),
                      outsideTextStyle:   TextStyle(color: Colors.transparent),
                    ),

                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (_, __, ___) => const SizedBox.shrink(),
                      defaultBuilder: (ctx, day, _) => _DayCell(
                        day: day,
                        events: _eventsForDay(day, all),
                        isToday: false,
                        isSelected: _isSameDay(day, selected),
                        isWeekend: day.weekday == DateTime.saturday ||
                            day.weekday == DateTime.sunday,
                      ),
                      todayBuilder: (ctx, day, _) {
                        final isSel = _isSameDay(day, selected);
                        return _DayCell(
                          day: day,
                          events: _eventsForDay(day, all),
                          isToday: !isSel,
                          isSelected: isSel,
                          isWeekend: false,
                        );
                      },
                      selectedBuilder: (ctx, day, _) => _DayCell(
                        day: day,
                        events: _eventsForDay(day, all),
                        isToday: false,
                        isSelected: true,
                        isWeekend: false,
                      ),
                      outsideBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),

                    onDaySelected: (sel, _) => _selectDay(sel),
                    onPageChanged: (day) =>
                    ref.read(calendarFocusedDateProvider.notifier).state = day,

                    rowHeight: 60,
                    daysOfWeekHeight: 30,
                  ),

                  // ── Legend row inside card ────────────────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LegendDot('Technical', AppColors.categoryTechnical),
                        _LegendDot('Cultural',  AppColors.categoryCultural),
                        _LegendDot('Sports',    AppColors.categorySports),
                        _LegendDot('Workshop',  AppColors.categoryWorkshop),
                        _LegendDot('Seminar',   AppColors.categorySeminar),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Blue date pill on the left
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isSameDay(selected, DateTime.now())
                          ? 'Today'
                          : '${_months[selected.month].substring(0, 3)} ${selected.day}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dayEvents.isEmpty
                        ? 'No events scheduled'
                        : '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                    style: AppTextStyles.bodyS,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Event list ────────────────────────────────────────────────────
          if (dayEvents.isEmpty)
            SliverToBoxAdapter(child: _EmptyState(date: selected))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => FadeTransition(
                    opacity: _listFade,
                    child: SlideTransition(
                      position: _listSlide,
                      child: CalendarEventCard(
                        event: dayEvents[i],
                        index: i,
                      ),
                    ),
                  ),
                  childCount: dayEvents.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DAY CELL
// ══════════════════════════════════════════════════════════════════════════════

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<EventModel> events;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;

  const _DayCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
  });

  Color _catColor(String cat) => switch (cat) {
    'Technical' => AppColors.categoryTechnical,
    'Cultural'  => AppColors.categoryCultural,
    'Sports'    => AppColors.categorySports,
    'Workshop'  => AppColors.categoryWorkshop,
    'Seminar'   => AppColors.categorySeminar,
    _           => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final cats = events.map((e) => e.category).toSet().toList()
      ..sort((a, b) {
        final ia = _catOrder.indexOf(a), ib = _catOrder.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });

    // ── Number decoration ─────────────────────────────────────────────────
    final Color numColor;
    final BoxDecoration deco;

    if (isSelected) {
      numColor = AppColors.white;
      deco = const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      numColor = AppColors.primary;
      deco = BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1.5),
      );
    } else {
      numColor = isWeekend
          ? AppColors.textSecondary
          : AppColors.textPrimary;
      deco = const BoxDecoration(
          color: Colors.transparent, shape: BoxShape.circle);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Number circle
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: deco,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color:      numColor,
              fontSize:   13,
              fontWeight: isSelected || isToday
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 3),

        // Dot row — fixed 7px height so rows stay aligned
        SizedBox(
          height: 7,
          child: events.isEmpty
              ? const SizedBox.shrink()
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: cats.take(3).map((cat) => Container(
              margin:
              const EdgeInsets.symmetric(horizontal: 1.5),
              width:  isSelected ? 6 : 5,
              height: isSelected ? 6 : 5,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white
                    : _catColor(cat),
                shape: BoxShape.circle,
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.divider),
      ),
      child: Icon(icon, size: 19, color: AppColors.textSecondary),
    ),
  );
}

// ── Legend dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final String label;
  final Color  color;
  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6, height: 6,
        decoration:
        BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final DateTime date;
  const _EmptyState({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.event_available_rounded,
                size: 34, color: AppColors.primaryMuted),
          ),
          const SizedBox(height: 14),
          Text(
            isToday ? 'Nothing today' : 'No events',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? 'Your schedule is clear'
                : 'No events on ${_months[date.month]} ${date.day}',
            style: AppTextStyles.bodyS,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
