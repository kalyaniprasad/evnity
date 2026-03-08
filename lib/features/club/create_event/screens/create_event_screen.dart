import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../providers/club_providers.dart';
import '../../models/club_event.dart';
import '../../models/club_mock_data.dart';
import '../../dashboard/widgets/upload_poster_widget.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Date Picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final label =
          '${days[picked.weekday - 1]}, ${picked.day} ${months[picked.month - 1]} ${picked.year}';
      ref.read(createEventProvider.notifier).setDate(label);
    }
  }

  // ── Time Picker ──────────────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final h =
          picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final m = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      ref.read(createEventProvider.notifier).setTime('$h:$m $period');
    }
  }

  // ── Publish ──────────────────────────────────────────────────────────────────
  void _publish() {
    final form = ref.read(createEventProvider);
    if (!form.isValid) {
      showAppSnackbar(context, 'Please fill in all required fields.',
          type: SnackbarType.error);
      return;
    }
    ref.read(clubEventsProvider.notifier).addEvent(ClubEvent(
          id: 'ce_${DateTime.now().millisecondsSinceEpoch}',
          title: form.title,
          category: form.category,
          date: form.date,
          time: form.time,
          venue: form.venue,
          posterUrl:
              'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&q=80',
          description: form.description,
          status: EventStatus.published,
          registrationCount: 0,
          messageCount: 0,
        ));
    ref.read(createEventProvider.notifier).reset();
    _titleCtrl.clear();
    _venueCtrl.clear();
    _descCtrl.clear();
    showAppSnackbar(context, 'Event published successfully! 🎉',
        type: SnackbarType.success);
    context.go('/club/home');
  }

  void _saveDraft() {
    showAppSnackbar(context, 'Saved as draft.', type: SnackbarType.info);
  }


  @override
  Widget build(BuildContext context) {
    final form = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.cardShadow,
        automaticallyImplyLeading: false,
        title: Text('Create Event', style: AppTextStyles.headingL),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Poster Upload ────────────────────────────────────────────
            UploadPosterWidget(
              isSelected: form.posterSelected,
              onTap: notifier.togglePoster,
            ),
            const SizedBox(height: 28),

            // ── Event Details ────────────────────────────────────────────
            _SectionHeader('Event Details'),
            const SizedBox(height: 14),

            _FieldLabel('Event Title *'),
            const SizedBox(height: 8),
            _InputField(
              controller: _titleCtrl,
              hint: 'e.g. National Hackathon 2025',
              onChanged: notifier.setTitle,
            ),
            const SizedBox(height: 16),

            _FieldLabel('Category *'),
            const SizedBox(height: 8),
            _CategoryDropdown(
              value: form.category,
              items: kClubEventCategories,
              onChanged: notifier.setCategory,
            ),
            const SizedBox(height: 16),

            _FieldLabel('Venue *'),
            const SizedBox(height: 8),
            _InputField(
              controller: _venueCtrl,
              hint: 'e.g. Main Auditorium, Block A',
              onChanged: notifier.setVenue,
            ),
            const SizedBox(height: 16),

            _FieldLabel('Description *'),
            const SizedBox(height: 8),
            _InputField(
              controller: _descCtrl,
              hint: 'Tell students what this event is about...',
              onChanged: notifier.setDescription,
              maxLines: 4,
            ),
            const SizedBox(height: 28),

            // ── Schedule ─────────────────────────────────────────────────
            _SectionHeader('Schedule'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: form.date.isEmpty ? null : form.date,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: form.time.isEmpty ? null : form.time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // ── Publish ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                label: const Text('Publish Event',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _saveDraft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save as Draft',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

// ── Reusable form sub-widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.headingM);
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.labelS.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final int maxLines;
  const _InputField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyM,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown(
      {required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted),
            style:
                AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
            items: items
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasValue ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? AppColors.primaryBorder : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: hasValue ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Select',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelS.copyWith(
                      color: hasValue
                          ? AppColors.primary
                          : AppColors.textMuted,
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
