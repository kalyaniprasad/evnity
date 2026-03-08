import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/providers/student_providers.dart';

// ── Date Helpers ───────────────────────────────────────────────────────────────
// Mock dates are stored as e.g. "Sat, 15 Mar 2025"
// We parse that into a DateTime to match calendar day cells.

const _monthMap = {
  'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,  'May': 5,  'Jun': 6,
  'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
};

/// Parses "Sat, 15 Mar 2025" → DateTime(2025, 3, 15)
DateTime? _parseMockDate(String date) {
  try {
    // Remove optional day-of-week prefix: "Sat, 15 Mar 2025" or "15 Mar 2025"
    final clean = date.contains(',') ? date.split(', ').last.trim() : date.trim();
    final parts = clean.split(' ');
    final day   = int.parse(parts[0]);
    final month = _monthMap[parts[1]] ?? 1;
    final year  = int.parse(parts[2]);
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatMonthYear(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

Color _getCategoryColor(String category) {
  switch (category) {
    case 'Technical': return AppColors.categoryTechnical;
    case 'Cultural':  return AppColors.categoryCultural;
    case 'Sports':    return AppColors.categorySports;
    case 'Workshop':  return AppColors.categoryWorkshop;
    case 'Seminar':   return AppColors.categorySeminar;
    default:          return AppColors.primary;
  }
}

// ── CalendarScreen ─────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  List<EventModel> _getEventsForDate(DateTime date, List<EventModel> allEvents) {
    return allEvents.where((e) {
      final parsed = _parseMockDate(e.date);
      return parsed != null && _isSameDay(parsed, date);
    }).toList();
  }

  void _previousMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    final allEvents = ref.watch(studentEventProvider);

    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    // Sunday = 0 offset (weekday gives Mon=1..Sun=7, we want Sun=0)
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final totalCells = firstWeekday + daysInMonth;
    final selectedEvents = _getEventsForDate(_selectedDate, allEvents);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Campus Calendar', style: AppTextStyles.headingL),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // ── Calendar Panel ──────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
            child: Column(
              children: [
                // Month navigation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatMonthYear(_currentMonth),
                        style: AppTextStyles.headingM),
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: AppColors.textSecondary),
                        onPressed: _previousMonth,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                        onPressed: _nextMonth,
                      ),
                    ]),
                  ],
                ),

                // Day-of-week headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                        .map((d) => SizedBox(
                              width: 36,
                              child: Text(d,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Date grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 52,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    // Leading empty cells
                    if (index < firstWeekday) return const SizedBox.shrink();

                    final day = index - firstWeekday + 1;
                    final date = DateTime(
                        _currentMonth.year, _currentMonth.month, day);
                    final isSelected = _isSameDay(_selectedDate, date);
                    final isToday = _isSameDay(DateTime.now(), date);
                    final events = _getEventsForDate(date, allEvents);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: AppTextStyles.bodyS.copyWith(
                                color: isSelected
                                    ? AppColors.white
                                    : isToday
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                            if (events.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: events.take(3).map((e) {
                                    return Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.white
                                            : _getCategoryColor(e.category),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Section label ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedEvents.isEmpty
                    ? 'No events scheduled'
                    : '${selectedEvents.length} event${selectedEvents.length > 1 ? 's' : ''} found',
                style: AppTextStyles.labelM
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),

          // ── Events for selected day ─────────────────────────────────────────
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.event_available_outlined,
                              size: 30, color: AppColors.primaryMuted),
                        ),
                        const SizedBox(height: 12),
                        Text('Nothing here', style: AppTextStyles.headingM),
                        const SizedBox(height: 4),
                        Text('No events on this day.',
                            style: AppTextStyles.bodyS),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, i) =>
                        _CalendarEventCard(event: selectedEvents[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Event Card ─────────────────────────────────────────────────────────────────

class _CalendarEventCard extends StatelessWidget {
  final EventModel event;
  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(event.category);
    return GestureDetector(
      // Navigate to the existing EventDetailScreen via the named route
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Coloured category bar
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: AppTextStyles.caption.copyWith(
                              color: catColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        event.time,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(event.title,
                      style: AppTextStyles.labelL,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(event.venue,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
