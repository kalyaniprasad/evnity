import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/push_notification_service.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventRegistrationScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends ConsumerState<EventRegistrationScreen> {
  final _phoneCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    final event = ref.read(eventByIdProvider(widget.eventId));
    if (user.id.isEmpty || event == null) return;
    
    setState(() => _isLoading = true);
    final repo = ref.read(eventRepositoryProvider);
    
    try {
      await repo.registerForEvent(
        eventId: event.id,
        userId: user.id,
        registrationData: {
          'aliasName': user.aliasName,
          'email': user.email,
          'branch': user.branch,
          'year': user.year,
          'phone': _phoneCtrl.text.trim(),
          'reason': _reasonCtrl.text.trim(),
        },
        notificationData: {
          'title': 'Registration Confirmed! 🎉',
          'description': 'You are registered for ${event.title}.',
          'type': 'registration',
          'eventId': event.id,
          'isRead': false,
        },
      );
      // Trigger a refresh on current user to fetch the updated `registeredEventIds` array
      ref.invalidate(currentUserProvider);
      
      // Subscribe to event notifications topic
      await PushNotificationService.subscribeToEventTopic(event.id);
      
      if (mounted) {
        showAppSnackbar(context, 'Successfully registered for ${event.title}!', type: SnackbarType.success);
        context.pop(); // Go back to event detail
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error registering: $e', type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventByIdProvider(widget.eventId));
    final user = ref.watch(currentUserProvider);
    
    if (event == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Register', style: AppTextStyles.headingL),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registering for:', style: AppTextStyles.labelM),
            const SizedBox(height: 8),
            Text(event.title, style: AppTextStyles.headingM.copyWith(color: AppColors.primary)),
            const SizedBox(height: 28),
            
            Text('Confirm Details', style: AppTextStyles.headingM),
            const SizedBox(height: 16),
            
            _InfoRow(label: 'Name', value: user.aliasName),
            const SizedBox(height: 12),
            _InfoRow(label: 'Branch', value: user.branch?.isNotEmpty == true ? user.branch! : 'Not specified'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Year', value: user.year?.isNotEmpty == true ? user.year! : 'First Year'),
            const SizedBox(height: 24),
            Text('To update these details, edit your Profile.', style: AppTextStyles.caption),
            const SizedBox(height: 32),
            
            Text('Additional Info (Optional)', style: AppTextStyles.headingM),
            const SizedBox(height: 16),
            
            Text('Phone Number', style: AppTextStyles.labelS),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
              decoration: _inputDeco('Enter phone number'),
            ),
            const SizedBox(height: 16),
            
            Text('Why do you want to join?', style: AppTextStyles.labelS),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
              decoration: _inputDeco('e.g. To learn mobile development'),
            ),
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyM,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: AppTextStyles.labelM.copyWith(color: AppColors.textMuted))),
        Expanded(child: Text(value, style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary))),
      ],
    );
  }
}
