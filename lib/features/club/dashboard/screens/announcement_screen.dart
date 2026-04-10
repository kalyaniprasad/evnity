import 'package:evnity/features/club/providers/club_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';

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
        final target =
            (_selectedTargetEventId != null && _selectedTargetEventId != 'all')
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
    final activeEvents =
        clubEvents.where((e) => e.status.name == 'published').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isLockedToEvent ? 'Notify Participants' : 'Send Announcement',
          style: AppTextStyles.headingM,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            onPressed: () => context.push('/club/announcements/history'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Decoration
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Broadcast your message to the community',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              // Main Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 28,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Selector
                    Text('TARGET AUDIENCE',
                        style: AppTextStyles.labelS.copyWith(
                          letterSpacing: 1,
                          color: AppColors.textMuted,
                        )),
                    const SizedBox(height: 12),
                    if (isLockedToEvent)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Targeted: Users registered for this event',
                                style: AppTextStyles.labelS.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedTargetEventId ?? 'all',
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All Students (Broadcast)'),
                              ),
                              ...activeEvents.map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text('Event: ${e.title}'),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedTargetEventId = val;
                              });
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),
                    Text('HEADLINE',
                        style: AppTextStyles.labelS.copyWith(
                          letterSpacing: 1,
                          color: AppColors.textMuted,
                        )),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _titleController,
                      hint: 'e.g., Change in Schedule',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 24),
                    Text('MESSAGE DETAILS',
                        style: AppTextStyles.labelS.copyWith(
                          letterSpacing: 1,
                          color: AppColors.textMuted,
                        )),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _messageController,
                      hint: 'Type your message here...',
                      icon: Icons.message_rounded,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, size: 20),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Send Notification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: AppTextStyles.bodyM,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
          hintText: hint,
          hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }
}
