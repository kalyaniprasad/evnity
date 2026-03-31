import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/providers/student_providers.dart';

// ── Student Profile Edit Screen ────────────────────────────────────────────────

class StudentProfileEditScreen extends ConsumerStatefulWidget {
  const StudentProfileEditScreen({super.key});

  @override
  ConsumerState<StudentProfileEditScreen> createState() =>
      _StudentProfileEditScreenState();
}

class _StudentProfileEditScreenState
    extends ConsumerState<StudentProfileEditScreen> {
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _branchCtrl;
  late final TextEditingController _bioCtrl;
  String? _selectedYear;
  String? _selectedDept;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  static const _years = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  static const _departments = [
    'Computer Engineering',
    'Computer Engineering (RL)',
    'Information Technology',
    'Mechanical Engineering',
    'Electronics and Telecommunication Engineering',
    'Civil Engineering',
    'AI-ML',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final edit = ref.read(studentProfileEditProvider);
    _aliasCtrl = TextEditingController(text: edit.aliasName);
    _fullNameCtrl = TextEditingController(text: edit.fullName);
    
    // Determine initial department
    if (edit.branch.isEmpty) {
      _selectedDept = null;
      _branchCtrl = TextEditingController();
    } else if (_departments.contains(edit.branch)) {
      _selectedDept = edit.branch;
      _branchCtrl = TextEditingController();
    } else {
      _selectedDept = 'Other';
      _branchCtrl = TextEditingController(text: edit.branch);
    }

    _bioCtrl = TextEditingController(text: edit.bio);
    _selectedYear = edit.year.isEmpty ? null : edit.year;
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _fullNameCtrl.dispose();
    _branchCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Update the edit notifier
    final notifier = ref.read(studentProfileEditProvider.notifier);
    final branchValue = _selectedDept == 'Other' ? _branchCtrl.text.trim() : (_selectedDept ?? '');

    notifier.setAlias(_aliasCtrl.text.trim());
    notifier.setFullName(_fullNameCtrl.text.trim());
    notifier.setBranch(branchValue);
    notifier.setYear(_selectedYear ?? '');
    notifier.setBio(_bioCtrl.text.trim());

    try {
      // Commit alias back to the main user provider
      await notifier.save();

      if (mounted) {
        showAppSnackbar(context, 'Profile updated successfully!',
            type: SnackbarType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Failed to update profile: $e',
            type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider).email;

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
        title: Text('Edit Profile', style: AppTextStyles.headingM),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: AppTextStyles.labelM
                        .copyWith(color: AppColors.primary)),
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
              // ── Avatar placeholder ─────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A3697), Color(0xFF3B60D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _aliasCtrl.text.isNotEmpty
                              ? _aliasCtrl.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800),
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
                          border:
                              Border.all(color: AppColors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to change photo',
                    style: AppTextStyles.caption),
              ),
              const SizedBox(height: 28),

              // ── Form fields ────────────────────────────────────────────
              _FormSection('Personal Info', [
                _EditField(
                  label: 'Alias Name',
                  hint: 'Your public display name',
                  controller: _aliasCtrl,
                  icon: Icons.badge_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Alias name is required'
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tip: This name will be used to display or connect with others instead of your real name. Choose wisely, unless you want to be known as this alias name forever. 🙄',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Full Name',
                  hint: 'Your full legal name',
                  controller: _fullNameCtrl,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Full name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Email (read-only)',
                  hint: 'Cannot be changed',
                  controller: TextEditingController(text: email),
                  icon: Icons.lock_outline_rounded,
                  readOnly: true,
                ),
              ]),
              const SizedBox(height: 20),

              _FormSection('Academic Info', [
                _DepartmentDropdown(
                  selectedDept: _selectedDept,
                  departments: _departments,
                  onChanged: (v) {
                    setState(() {
                      _selectedDept = v;
                      if (v != 'Other') {
                        _branchCtrl.clear();
                      }
                    });
                  },
                ),
                if (_selectedDept == 'Other') ...[
                  const SizedBox(height: 12),
                  _EditField(
                    label: 'Specify Your Branch',
                    hint: 'e.g. Electrical Engineering',
                    controller: _branchCtrl,
                    icon: Icons.edit_outlined,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Branch is required'
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                _YearDropdown(
                  selectedYear: _selectedYear,
                  years: _years,
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
              ]),
              const SizedBox(height: 20),

              _FormSection('About You', [
                _EditField(
                  label: 'Bio',
                  hint: 'Tell others a bit about yourself…',
                  controller: _bioCtrl,
                  icon: Icons.info_outline_rounded,
                  maxLines: 4,
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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
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
          Text(title,
              style: AppTextStyles.labelM.copyWith(color: AppColors.primary)),
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
                    offset: Offset(0, 2))
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
  final bool readOnly;
  final String? Function(String?)? validator;

  const _EditField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.readOnly = false,
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
            validator: validator,
            style: AppTextStyles.labelM.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.caption,
              prefixIcon: Icon(icon,
                  size: 18,
                  color: readOnly
                      ? AppColors.textDisabled
                      : AppColors.primary),
              filled: true,
              fillColor: readOnly
                  ? AppColors.surfaceAlt
                  : AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
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

// ── Year Dropdown ─────────────────────────────────────────────────────────────

class _YearDropdown extends StatelessWidget {
  final String? selectedYear;
  final List<String> years;
  final ValueChanged<String?> onChanged;

  const _YearDropdown({
    required this.selectedYear,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Academic Year', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedYear,
            onChanged: onChanged,
            hint: Text('Select Year', style: AppTextStyles.caption),
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                .toList(),
            validator: (v) => v == null || v.isEmpty ? 'Year is required' : null,
            style: AppTextStyles.labelM.copyWith(fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_month_outlined,
                  size: 18, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      );
}

// ── Department Dropdown ─────────────────────────────────────────────────────────────

class _DepartmentDropdown extends StatelessWidget {
  final String? selectedDept;
  final List<String> departments;
  final ValueChanged<String?> onChanged;

  const _DepartmentDropdown({
    required this.selectedDept,
    required this.departments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Branch / Department', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => DropdownMenu<String>(
              initialSelection: selectedDept,
              onSelected: onChanged,
              width: constraints.maxWidth,
              hintText: 'Select Department',
              menuHeight: 300,
              textStyle: AppTextStyles.labelM.copyWith(fontSize: 14),
              leadingIcon: const Icon(Icons.school_outlined,
                  size: 18, color: AppColors.primary),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              dropdownMenuEntries: departments
                  .map((d) => DropdownMenuEntry(
                        value: d,
                        label: d,
                        style: MenuItemButton.styleFrom(
                          textStyle: AppTextStyles.labelM.copyWith(fontSize: 14),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
}
