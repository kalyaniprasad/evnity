import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/club_event.dart';

class EventStatusBadge extends StatelessWidget {
  final EventStatus status;

  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPublished = status == EventStatus.published;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.successSurface
            : AppColors.warningSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPublished
              ? AppColors.success.withOpacity(0.25)
              : AppColors.warning.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isPublished ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isPublished ? 'Published' : 'Draft',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPublished ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
