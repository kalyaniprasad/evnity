import 'package:evnity/features/club/providers/club_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/repositories/notification_repository.dart';

class AnnouncementScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const AnnouncementScreen({super.key, this.eventId});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _selectedTargetEventId;

  @override
  void initState() {
    super.initState();
    _selectedTargetEventId = widget.eventId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final user = ref.read(currentUserProvider);

      if (_selectedTargetEventId != null && _selectedTargetEventId != 'all') {
        // Event specific
        await repo.sendEventAnnouncement(
          senderClubId: user.id,
          eventId: _selectedTargetEventId!,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
        );
      } else {
        // Broadcast
        await repo.sendBroadcast(
          senderClubId: user.id,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
        );
      }

      if (mounted) {
        final target = (_selectedTargetEventId != null && _selectedTargetEventId != 'all')
            ? 'event participants'
            : 'all students';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement successfully sent to $target!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending announcement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockedToEvent = widget.eventId != null;
    final eventsAsync = ref.watch(clubEventsProvider);
    final clubEvents = eventsAsync.valueOrNull ?? [];
    // Only show published events for targeting
    final activeEvents = clubEvents.where((e) => e.status.name == 'published').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isLockedToEvent ? 'Notify Participants' : 'Send Announcement', style: AppTextStyles.headingM),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            onPressed: () => context.push('/club/announcements/history'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Selector
              Text('Who should receive this?', style: AppTextStyles.labelL),
              const SizedBox(height: 12),
              if (isLockedToEvent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Targeted: Users registered for this event',
                          style: AppTextStyles.labelS.copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedTargetEventId ?? 'all',
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Students (Broadcast)'),
                    ),
                    ...activeEvents.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('Event: ${e.title}'),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetEventId = val;
                    });
                  },
                ),

              const SizedBox(height: 28),
              Text('Headline', style: AppTextStyles.labelL),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Change in Schedule',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                validator: (value) =>
                  value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 24),
              Text('Message Details', style: AppTextStyles.labelL),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                validator: (value) =>
                  value == null || value.isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text('Send Notification',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
