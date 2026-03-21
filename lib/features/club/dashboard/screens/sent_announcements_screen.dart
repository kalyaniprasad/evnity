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
            if (error.contains('index') || error.contains('FAILED_PRECONDITION')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.warning),
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
                  Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No announcements sent yet', style: AppTextStyles.bodyL),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null 
                ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}' 
                : 'Unknown Date';
              final isBroadcast = data['target'] == 'all';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isBroadcast ? AppColors.primarySurface : AppColors.successSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBroadcast ? 'Broadcast' : 'Event Targeted',
                            style: AppTextStyles.caption.copyWith(
                              color: isBroadcast ? AppColors.primary : AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(dateStr, style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(data['title'] ?? '', style: AppTextStyles.labelL),
                    const SizedBox(height: 4),
                    Text(data['message'] ?? '', style: AppTextStyles.bodyM),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
