import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/student_providers.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../features/club/models/registration_field_model.dart';
import '../../../../core/utils/condition_evaluator.dart';
import '../../../../core/repositories/event_repository.dart';
import '../../../../core/models/models.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventRegistrationScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState
    extends ConsumerState<EventRegistrationScreen> {
  final _phoneCtrl = TextEditingController();
  final Map<String, dynamic> _formResponses = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _validateRegistration(List<RegistrationFieldModel> fields) {
    for (final field in fields) {
      if (!_isFieldVisible(field)) continue;

      if (field.isRepeatingBlock) {
        final count = _getRepeatCount(field);
        final blocks = (_formResponses[field.id] as List?) ?? [];
        if (blocks.length < count) return false;
        
        for (var i = 0; i < count; i++) {
          final blockData = blocks[i] as Map<String, dynamic>? ?? {};
          for (final nested in field.nestedFields ?? []) {
            if (nested.isRequired && (blockData[nested.id] == null || blockData[nested.id].toString().isEmpty)) {
              return false;
            }
          }
        }
      } else if (field.isRequired) {
        final val = _formResponses[field.id];
        if (val == null || val.toString().trim().isEmpty) return false;
        if (val is List && val.isEmpty) return false;
      }
    }
    return true;
  }

  bool _isFieldVisible(RegistrationFieldModel field) {
    if (field.showIf == null || field.dependsOnField == null) return true;
    return ConditionEvaluator.evaluate(field.showIf!, _formResponses);
  }

  int _getRepeatCount(RegistrationFieldModel field) {
    if (!field.isRepeatingBlock || field.repeatSourceField == null) return 0;
    final sourceVal = _formResponses[field.repeatSourceField!];
    return int.tryParse(sourceVal?.toString() ?? '0') ?? 0;
  }

  Future<void> _submit(dynamic event) async {
    final user = ref.read(currentUserProvider);
    if (user.id.isEmpty || event == null) return;

    if (!_validateRegistration(event.registrationFields)) {
      showAppSnackbar(
        context,
        'Please fill all required and visible fields.',
        type: SnackbarType.warning,
      );
      return;
    }

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
          'responses': _formResponses, // Store raw responses map
          'submittedAt': DateTime.now().toIso8601String(),
        },
        notificationData: {
          'title': 'Registration Confirmed! 🎉',
          'description': 'You are registered for ${event.title}.',
          'type': 'registration',
          'eventId': event.id,
          'isRead': false,
        },
      );
      
      ref.invalidate(currentUserProvider);
      await PushNotificationService.subscribeToEventTopic(event.id);
      
      if (mounted) {
        showAppSnackbar(
          context,
          'Successfully registered for ${event.title}!',
          type: SnackbarType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(
          context,
          'Error registering: $e',
          type: SnackbarType.error,
        );
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
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Event Registration', style: AppTextStyles.headingM),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Header Section
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: AppTextStyles.headingM.copyWith(color: AppColors.primary)),
                            Text(event.clubName, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildProfileSummary(user),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            ...event.registrationFields.map((field) => _renderFieldOrBlock(field)),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submit(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR DETAILS', style: AppTextStyles.labelS.copyWith(letterSpacing: 1, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        _buildInfoItem(Icons.person_outline_rounded, 'Name', user.name),
        const SizedBox(height: 10),
        _buildInfoItem(Icons.email_outlined, 'Email', user.email),
        const SizedBox(height: 10),
        if ((user.year ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildInfoItem(Icons.school_outlined, 'Year', user.year!),
          ),
        if ((user.branch ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildInfoItem(Icons.category_outlined, 'Branch', user.branch!),
          ),
        // Phone — Optional
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: AppTextStyles.bodyS,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.phone_iphone_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              hintText: 'Phone number (optional)',
              hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
              suffixText: 'Optional',
              suffixStyle: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label:', style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _renderFieldOrBlock(RegistrationFieldModel field) {
    if (!_isFieldVisible(field)) return const SizedBox.shrink();

    if (field.isRepeatingBlock) {
      final count = _getRepeatCount(field);
      if (count == 0) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(field.label, style: AppTextStyles.labelM.copyWith(color: AppColors.textPrimary)),
          ),
          ...List.generate(count, (index) => _renderRepeatingInstance(field, index)),
        ],
      );
    }

    return _DynamicFieldWidget(
      field: field,
      value: _formResponses[field.id],
      onChanged: (val) {
        setState(() {
          _formResponses[field.id] = val;
        });
      },
    );
  }

  Widget _renderRepeatingInstance(RegistrationFieldModel block, int index) {
    final blockId = block.id;
    final List<dynamic> currentBlocks = List.from(_formResponses[blockId] ?? []);
    
    // Ensure the list is long enough
    while (currentBlocks.length <= index) {
      currentBlocks.add(<String, dynamic>{});
    }
    
    final Map<String, dynamic> instanceData = currentBlocks[index];

    return _SectionCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Block ${index + 1}', style: AppTextStyles.labelS.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          ...?block.nestedFields?.map((nested) {
            return _DynamicFieldWidget(
              field: nested,
              value: instanceData[nested.id],
              onChanged: (val) {
                setState(() {
                  instanceData[nested.id] = val;
                  _formResponses[blockId] = currentBlocks;
                });
              },
            );
          }),
        ],
      ),
    );
  }
}

// ── Shared Section UI ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  const _SectionCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

// ── Dynamic Field Widget ──────────────────────────────────────────────────────

class _DynamicFieldWidget extends StatefulWidget {
  final RegistrationFieldModel field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _DynamicFieldWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_DynamicFieldWidget> createState() => _DynamicFieldWidgetState();
}

class _DynamicFieldWidgetState extends State<_DynamicFieldWidget> {
  bool _isUploading = false;

  RegistrationFieldModel get field => widget.field;
  dynamic get value => widget.value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(field.label, style: AppTextStyles.labelS.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (field.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Required', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (field.helpText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(field.helpText!, style: AppTextStyles.caption),
            ),
          // Show club's attachment (QR / screenshot) inline for images, or as a link
          if (field.attachmentUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CloudinaryService.isImageUrl(field.attachmentUrl!)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            field.attachmentUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(field.attachmentUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 13),
                          label: const Text('View Full Image'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(field.attachmentUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('View Attachment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        textStyle: AppTextStyles.caption,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
            ),
          const SizedBox(height: 10),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (field.type) {
      case FormFieldType.shortText:
      case FormFieldType.email:
      case FormFieldType.phone:
        return TextField(
          onChanged: widget.onChanged,
          keyboardType: _getKeyboardType(),
          controller: value == null ? null : (TextEditingController()..text = value.toString()..selection = TextSelection.collapsed(offset: value.toString().length)),
          decoration: _inputDeco(field.label),
        );
      case FormFieldType.longText:
        return TextField(
          onChanged: widget.onChanged,
          maxLines: 3,
          controller: value == null ? null : (TextEditingController()..text = value.toString()..selection = TextSelection.collapsed(offset: value.toString().length)),
          decoration: _inputDeco('Your answer...'),
        );
      case FormFieldType.number:
        return TextField(
          onChanged: (val) => widget.onChanged(double.tryParse(val)),
          keyboardType: TextInputType.number,
          decoration: _inputDeco('0'),
        );
      case FormFieldType.multipleChoice:
      case FormFieldType.dropdown:
        return _buildChoice(context);
      case FormFieldType.checkboxes:
        return _buildCheckboxes();
      case FormFieldType.date:
        return _buildDatePicker(context);
      case FormFieldType.time:
        return _buildTimePicker(context);
      case FormFieldType.fileUpload:
        return _buildFilePicker(context);
      default:
        return const SizedBox.shrink();
    }
  }

  TextInputType _getKeyboardType() {
    if (field.type == FormFieldType.email) return TextInputType.emailAddress;
    if (field.type == FormFieldType.phone) return TextInputType.phone;
    return TextInputType.text;
  }

  Widget _buildChoice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value as String?,
          hint: const Text('Select Option'),
          items: field.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  Widget _buildCheckboxes() {
    final List<String> selected = List<String>.from(value ?? []);
    return Column(
      children: field.options.map((opt) {
        return CheckboxListTile(
          title: Text(opt, style: AppTextStyles.bodyS),
          value: selected.contains(opt),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (val) {
            final updated = List<String>.from(selected);
            if (val == true) {
              updated.add(opt);
            } else {
              updated.remove(opt);
            }
            widget.onChanged(updated);
          },
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (context.mounted && d != null) {
          widget.onChanged(DateFormat('yyyy-MM-dd').format(d));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(value?.toString() ?? 'Select Date', style: AppTextStyles.bodyS),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (context.mounted && t != null) {
          widget.onChanged(t.format(context));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(value?.toString() ?? 'Select Time', style: AppTextStyles.bodyS),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(BuildContext context) {
    final uploadedUrl = value?.toString();
    final hasUrl = uploadedUrl != null && uploadedUrl.startsWith('http');
    final isImage = hasUrl && CloudinaryService.isImageUrl(uploadedUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show inline image preview if already uploaded
        if (hasUrl && isImage)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                uploadedUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          )
        else if (hasUrl)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(uploadedUrl, style: AppTextStyles.caption.copyWith(color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(uploadedUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

        // Upload controls
        if (_isUploading)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Uploading...', style: TextStyle(fontSize: 13)),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndUpload(fromCamera: false),
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: Text(hasUrl ? 'Change Image' : 'Pick Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAnyFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(hasUrl ? 'Change File' : 'Any File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        if (hasUrl)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Uploaded successfully', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUpload({required bool fromCamera}) async {
    setState(() => _isUploading = true);
    try {
      final file = fromCamera
          ? await CloudinaryService.pickImageFromCamera()
          : await CloudinaryService.pickImage();
      if (file == null) return;
      final url = await CloudinaryService.uploadFile(file);
      if (url != null) {
        widget.onChanged(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAnyFile() async {
    setState(() => _isUploading = true);
    try {
      final file = await CloudinaryService.pickFile();
      if (file == null) return;
      final url = await CloudinaryService.uploadFile(file);
      if (url != null) {
        widget.onChanged(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}

