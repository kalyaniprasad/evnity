import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/providers/student_providers.dart';
import '../widgets/calendar_event_card.dart';

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

// ── CalendarScreen ─────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<EventModel> _getEventsForDay(DateTime day, List<EventModel> allEvents) {
    return allEvents.where((e) {
      final parsed = _parseMockDate(e.date);
      return parsed != null && _isSameDay(parsed, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(studentEventProvider);
    final allEvents = allEventsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Campus Calendar', style: AppTextStyles.headingL),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Precise vertical fill calculation:
          // Remove limits to let it fill the entire available screen height.
          final availableHeight = constraints.maxHeight - 56 - 40;
          final rowHeight = availableHeight / 6;

          return TableCalendar<EventModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => false,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) => _getEventsForDay(day, allEvents),
            startingDayOfWeek: StartingDayOfWeek.sunday,
            rowHeight: rowHeight,
            sixWeekMonthsEnforced: true,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyles.headingM,
              leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              headerPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted),
              weekendStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(color: Colors.transparent),
              todayDecoration: BoxDecoration(color: Colors.transparent),
              markerDecoration: BoxDecoration(color: Colors.transparent),
            ),
            calendarBuilders: CalendarBuilders(
              // Explicitly return empty widget to hide default markers
              markerBuilder: (context, day, events) => const SizedBox.shrink(),
              defaultBuilder: (context, day, focusedDay) {
                final events = _getEventsForDay(day, allEvents);
                return _buildCalendarCell(day, events, isToday: false);
              },
              todayBuilder: (context, day, focusedDay) {
                final events = _getEventsForDay(day, allEvents);
                return _buildCalendarCell(day, events, isToday: true);
              },
              selectedBuilder: (context, day, focusedDay) {
                final events = _getEventsForDay(day, allEvents);
                return _buildCalendarCell(day, events, isToday: isSameDay(day, DateTime.now()));
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });

              final events = _getEventsForDay(selectedDay, allEvents);
              if (events.isNotEmpty) {
                context.push('/calendar/day-events', extra: {
                  'date': selectedDay,
                  'events': events,
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          );
        },
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, List<EventModel> events, {required bool isToday}) {
    const order = ['Technical', 'Cultural', 'Sports', 'Workshop', 'Seminar'];
    
    final presentCategories = events.map((e) => e.category).toSet().toList();
    presentCategories.sort((a, b) {
      final idxA = order.indexOf(a);
      final idxB = order.indexOf(b);
      return (idxA != -1 ? idxA : 99).compareTo(idxB != -1 ? idxB : 99);
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${day.day}',
          style: AppTextStyles.labelL.copyWith(
            color: isToday ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Ensure consistent horizontal alignment and height
        SizedBox(
          height: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: presentCategories.take(4).map((cat) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: getCategoryColor(cat),
                shape: BoxShape.circle,
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
