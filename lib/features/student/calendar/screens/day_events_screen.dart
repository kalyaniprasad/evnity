import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/calendar_event_card.dart';

class DayEventsScreen extends StatelessWidget {
  final DateTime date;
  final List<EventModel> events;

  const DayEventsScreen({
    super.key,
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events', style: AppTextStyles.headingM),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(date),
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: events.isEmpty
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
                  Text('No events on this day.', style: AppTextStyles.bodyS),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              itemBuilder: (context, i) => CalendarEventCard(event: events[i]),
            ),
    );
  }
}
