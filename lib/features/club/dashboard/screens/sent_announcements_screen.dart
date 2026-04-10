import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';

class SentAnnouncementsScreen extends ConsumerWidget {
  const SentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Announcement History', style: AppTextStyles.headingM),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('club_announcements')
            .where('senderClubId', isEqualTo: user.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('index') ||
                error.contains('FAILED_PRECONDITION')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text('Index Required', style: AppTextStyles.headingM),
                      const SizedBox(height: 8),
                      Text(
                        'This view requires a Firestore index. Please click the link in your Firebase Console error log to generate it.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyS,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Error: $error'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text('No announcements sent yet', style: AppTextStyles.bodyL),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null
                  ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
                  : 'Unknown Date';
              final isBroadcast = data['target'] == 'broadcast_all';

              // Staggered Entrance Animation
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1.0 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Accent Bar
                      Container(
                        height: 4,
                        width: double.infinity,
                        color: isBroadcast ? AppColors.primary : AppColors.success,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isBroadcast
                                        ? AppColors.primarySurface
                                        : AppColors.successSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isBroadcast
                                            ? Icons.public_rounded
                                            : Icons.playlist_add_check_circle_rounded,
                                        size: 14,
                                        color: isBroadcast
                                            ? AppColors.primary
                                            : AppColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isBroadcast ? 'Broadcast' : 'Event Participants',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isBroadcast
                                              ? AppColors.primary
                                              : AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data['title'] ?? '',
                              style: AppTextStyles.headingM.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['message'] ?? '',
                              style: AppTextStyles.bodyM.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
