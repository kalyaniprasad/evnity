import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/theme/theme.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'Technical': return AppColors.categoryTechnical;
    case 'Cultural':  return AppColors.categoryCultural;
    case 'Sports':    return AppColors.categorySports;
    case 'Workshop':  return AppColors.categoryWorkshop;
    case 'Seminar':   return AppColors.categorySeminar;
    default:          return AppColors.primary;
  }
}

class CalendarEventCard extends StatelessWidget {
  final EventModel event;
  const CalendarEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final catColor = getCategoryColor(event.category);
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
