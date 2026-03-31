import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);
    final unread = ref.watch(unreadCountProvider);
    final user = ref.watch(currentUserProvider);
    final repo = ref.read(notificationRepositoryProvider);
    final isProfileIncomplete = ref.watch(isProfileIncompleteProvider);

    return notificationsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (notifications) {
        final unreadList = notifications.where((n) => !n.isRead).toList();
        final readList = notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Notifications', style: AppTextStyles.headingL),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => repo.markAllAsRead(user.id),
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelS.copyWith(color: AppColors.primary),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: (notifications.isEmpty && !isProfileIncomplete)
          ? const _EmptyNotifications()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (isProfileIncomplete)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ProfileCompletionBanner(),
                    ),
                  ),

                if (unreadList.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text('New', style: AppTextStyles.headingM),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _NotificationTile(
                          notification: unreadList[i],
                          onTap: () => repo.markAsRead(unreadList[i].id),
                        ),
                        childCount: unreadList.length,
                      ),
                    ),
                  ),
                ],
                if (readList.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Earlier',
                          style: AppTextStyles.headingM),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _NotificationTile(
                          notification: readList[i],
                          onTap: () {},
                        ),
                        childCount: readList.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
      },
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile(
      {required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
        NotificationType.eventUpdate => Icons.update_rounded,
        NotificationType.reminder => Icons.alarm_rounded,
        NotificationType.announcement => Icons.campaign_rounded,
        NotificationType.registration => Icons.check_circle_rounded,
        NotificationType.profileIncomplete => Icons.person_add_alt_1_rounded,
      };

  Color get _iconColor => switch (notification.type) {
        NotificationType.eventUpdate => const Color(0xFF1E40AF),
        NotificationType.reminder => const Color(0xFFD97706),
        NotificationType.announcement => const Color(0xFF7C3AED),
        NotificationType.registration => const Color(0xFF16A34A),
        NotificationType.profileIncomplete => const Color(0xFFD97706),
      };

  Color get _iconBg => switch (notification.type) {
        NotificationType.eventUpdate => const Color(0xFFEFF4FF),
        NotificationType.reminder => const Color(0xFFFFFBEB),
        NotificationType.announcement => const Color(0xFFF5F3FF),
        NotificationType.registration => const Color(0xFFF0FDF4),
        NotificationType.profileIncomplete => const Color(0xFFFFFBEB),
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.white
              : AppColors.primarySurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.divider
                : AppColors.primaryBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, size: 22, color: _iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.labelM.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: AppTextStyles.bodyS,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timestamp,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 40, color: AppColors.primaryMuted),
          ),
          const SizedBox(height: 16),
          Text('No notifications yet', style: AppTextStyles.headingM),
          const SizedBox(height: 8),
          Text('You\'re all caught up!', style: AppTextStyles.bodyS),
        ],
      ),
    );
  }
}

// ── Profile Completion Banner ──────────────────────────────────────────────────

class _ProfileCompletionBanner extends StatelessWidget {
  const _ProfileCompletionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.draw_rounded,
              size: 22,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Required',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete Your Profile',
                  style: AppTextStyles.labelM.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add your branch, year, and bio to help others know you better and improve your experience.',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed('studentProfileEdit');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: AppTextStyles.labelS.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
