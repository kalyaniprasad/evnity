import 'dart:io';
import '../../../../core/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/repositories/event_repository.dart';
import '../../providers/club_providers.dart';
import '../../dashboard/widgets/upload_poster_widget.dart';
import '../../create_event/widgets/form_builder_widget.dart';

class EventEditScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventEditScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Technical';
  String _date = 'Wed, 15 Mar 2025';
  String _time = '10:00 AM';

  bool _initialized = false;
  File? _newPosterFile;
  String? _existingPosterUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final title = _titleCtrl.text.trim();
    final venue = _venueCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || venue.isEmpty || desc.isEmpty) {
      showAppSnackbar(
        context,
        'Please fill in all required fields.',
        type: SnackbarType.error,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? updatedPosterUrl = _existingPosterUrl;

      if (_newPosterFile != null) {
        final url = await CloudinaryService.uploadImage(_newPosterFile!);
        if (url != null) updatedPosterUrl = url;
      }

      final repo = ref.read(eventRepositoryProvider);
      final clubProfile = ref.read(clubProfileProvider);
      final user = ref.read(currentUserProvider);

      // Grab the latest form fields from the provider
      final formFields = ref.read(createEventProvider).formFields;

      final updatedData = {
        'title': title,
        'venue': venue,
        'description': desc,
        'category': _category,
        'date': _date,
        'time': _time,
        'posterUrl': updatedPosterUrl,
        'organizerName': clubProfile.name.isNotEmpty
            ? clubProfile.name
            : user.aliasName,
        'status': 'published',
        // Save updated registration form fields
        'registrationFields': formFields.map((f) => f.toJson()).toList(),
      };

      await repo.updateEvent(widget.eventId, updatedData);

      if (mounted) Navigator.pop(context);
      if (mounted) {
        showAppSnackbar(
          context,
          'Event updated successfully! 🎉',
          type: SnackbarType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showAppSnackbar(
          context,
          'Error updating event: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final eventsAsync = ref.read(clubEventsProvider);
      final events = eventsAsync.valueOrNull ?? [];
      final event = events.where((e) => e.id == widget.eventId).firstOrNull;
      if (event != null) {
        _titleCtrl.text = event.title;
        _venueCtrl.text = event.venue;
        _descCtrl.text = event.description;
        _category = event.category;
        _date = event.date;
        _time = event.time;
        _existingPosterUrl = event.posterUrl;
      }
      _initialized = true;

      // Load existing registration fields from the club event model
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (event != null && event.registrationFields.isNotEmpty) {
          ref.read(createEventProvider.notifier).setFormFields(event.registrationFields);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.cardShadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Event', style: AppTextStyles.headingL),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () {
              // handle delete
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster Upload ────────────────────────────────────────────
            UploadPosterWidget(
              imageFile: _newPosterFile,
              existingImageUrl: _existingPosterUrl,
              onTap: () async {
                final file = await CloudinaryService.pickImage();
                if (file != null) {
                  setState(() => _newPosterFile = file);
                }
              },
            ),
            const SizedBox(height: 28),

            // ── Event Details ────────────────────────────────────────────
            _FieldLabel('Event Title *'),
            const SizedBox(height: 8),
            _InputField(controller: _titleCtrl),
            const SizedBox(height: 16),

            _FieldLabel('Venue *'),
            const SizedBox(height: 8),
            _InputField(controller: _venueCtrl),
            const SizedBox(height: 16),

            _FieldLabel('Description *'),
            const SizedBox(height: 8),
            _InputField(controller: _descCtrl, maxLines: 4),
            const SizedBox(height: 28),

            // ── Schedule ─────────────────────────────────────────────────
            Text('Schedule', style: AppTextStyles.headingM),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _date,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _time,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Registration Form Builder ────────────────────────────────
            const FormBuilderWidget(),
            const SizedBox(height: 36),

            // ── Save Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.labelS.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLines;
  const _InputField({required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelS.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
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
