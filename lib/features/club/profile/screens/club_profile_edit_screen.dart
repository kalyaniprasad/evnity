import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../providers/club_providers.dart';
import '../../../../core/providers/student_providers.dart';

// ── Club Profile Edit Screen ───────────────────────────────────────────────────

class ClubProfileEditScreen extends ConsumerStatefulWidget {
  const ClubProfileEditScreen({super.key});

  @override
  ConsumerState<ClubProfileEditScreen> createState() =>
      _ClubProfileEditScreenState();
}

class _ClubProfileEditScreenState extends ConsumerState<ClubProfileEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _mentorCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _foundedCtrl;
  late final TextEditingController _locationCtrl;
  String _selectedCategory = 'Technical';
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    final p = ref.read(clubProfileProvider);
    final currentUser = ref.read(currentUserProvider);

    _nameCtrl = TextEditingController(
      text: p.name.isNotEmpty ? p.name : currentUser.name,
    );
    _taglineCtrl = TextEditingController(text: p.tagline);
    _descCtrl = TextEditingController(text: p.description);
    _mentorCtrl = TextEditingController(text: p.facultyMentor);
    _emailCtrl = TextEditingController(
      text: p.email.isNotEmpty ? p.email : currentUser.email,
    );
    _foundedCtrl = TextEditingController(text: p.founded);
    _locationCtrl = TextEditingController(text: p.location);

    _categories = [
      'Technical',
      'Cultural',
      'Sports',
      'Workshop',
      'Social',
      'Academic',
      'Other',
    ];
    _selectedCategory = p.category.isNotEmpty ? p.category : _categories.first;
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _descCtrl.dispose();
    _mentorCtrl.dispose();
    _emailCtrl.dispose();
    _foundedCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final tagline = _taglineCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final mentor = _mentorCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final founded = _foundedCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    final notifier = ref.read(clubProfileProvider.notifier);

    try {
      final user = ref.read(currentUserProvider);
      if (user.id.isNotEmpty) {
        final repo = ref.read(userRepositoryProvider);

        // 1. Update Club Document
        await repo.updateClub(user.id, {
          'name': name,
          'tagline': tagline,
          'description': description,
          'category': _selectedCategory,
          'facultyMentor': mentor,
          'email': email,
          'founded': founded,
          'location': location,
        });

        // 2. Update Local Club Profile State
        notifier.update(
          ClubProfileModel(
            name: name,
            tagline: tagline,
            description: description,
            category: _selectedCategory,
            facultyMentor: mentor,
            email: email,
            founded: founded,
            location: location,
          ),
        );

        // Dismiss profile-incomplete notification if profile is now complete
        final isNowComplete =
            tagline.isNotEmpty &&
            description.isNotEmpty &&
            mentor.isNotEmpty &&
            location.isNotEmpty;
        if (isNowComplete) {
          final notifRepo = ref.read(notificationRepositoryProvider);
          await notifRepo.dismissProfileIncompleteNotification(user.id);
        }
      }

      if (mounted) {
        showAppSnackbar(
          context,
          'Club profile updated!',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(
          context,
          'Failed to update profile: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Derive initials live from the name field
    final initials = _nameCtrl.text.trim().isEmpty
        ? 'CC'
        : _nameCtrl.text
              .trim()
              .split(' ')
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Club Profile', style: AppTextStyles.headingM),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.labelM.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo placeholder ────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A3697), Color(0xFF3B60D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.headingXL.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to change logo', style: AppTextStyles.caption),
              ),
              const SizedBox(height: 28),

              // ── Club Identity ───────────────────────────────────────────
              _FormSection('Club Identity', [
                _EditField(
                  label: 'Club Name',
                  hint: 'Official club name',
                  controller: _nameCtrl,
                  icon: Icons.groups_rounded,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Club name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Tagline',
                  hint: 'A catchy one-liner for your club',
                  controller: _taglineCtrl,
                  icon: Icons.format_quote_rounded,
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Description',
                  hint: 'What does your club do? Tell students about it…',
                  controller: _descCtrl,
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 12),
                _CategoryDropdown(
                  selectedCategory: _selectedCategory,
                  categories: _categories,
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Contact & Admin ─────────────────────────────────────────
              _FormSection('Contact & Admin', [
                _EditField(
                  label: 'Contact Email',
                  hint: 'club@college.edu',
                  controller: _emailCtrl,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Faculty Mentor',
                  hint: 'Dr. / Prof. name',
                  controller: _mentorCtrl,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Founded Year',
                  hint: 'e.g. 2019',
                  controller: _foundedCtrl,
                  icon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Location',
                  hint: 'Campus building / block',
                  controller: _locationCtrl,
                  icon: Icons.location_on_outlined,
                ),
              ]),
              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form Section ──────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection(this.title, this.children);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTextStyles.labelM.copyWith(color: AppColors.primary),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
}

// ── Editable Field ────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final bool readOnly = false;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _EditField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTextStyles.labelM.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption,
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          filled: true,
          fillColor: readOnly ? AppColors.surfaceAlt : AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    ],
  );
}

// ── Category Dropdown ─────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.selectedCategory,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Category', style: AppTextStyles.caption),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: selectedCategory,
        onChanged: onChanged,
        items: categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        style: AppTextStyles.labelM.copyWith(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.category_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}
