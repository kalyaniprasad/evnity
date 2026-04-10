import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../providers/club_providers.dart';
import '../../models/registration_field_model.dart';

class FormBuilderWidget extends ConsumerStatefulWidget {
  const FormBuilderWidget({super.key});

  @override
  ConsumerState<FormBuilderWidget> createState() => _FormBuilderWidgetState();
}

class _FormBuilderWidgetState extends ConsumerState<FormBuilderWidget> {
  bool _isPreviewMode = false;

  @override
  Widget build(BuildContext context) {
    final formFields = ref.watch(createEventProvider).formFields;
    final notifier = ref.read(createEventProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registration Form', style: AppTextStyles.headingM),
                  Text(
                    'Build a custom form for your attendees',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Preview', style: AppTextStyles.labelS.copyWith(fontSize: 10)),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: _isPreviewMode,
                        onChanged: (val) => setState(() => _isPreviewMode = val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                _QuickAddMenu(onAdd: (type) => notifier.addFormField(type: type)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (formFields.isEmpty)
          _EmptyFormState(onAdd: notifier.addFormField)
        else if (_isPreviewMode)
          _FormPreview(fields: formFields)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: formFields.length,
            onReorder: notifier.reorderFormFields,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final field = formFields[index];
              return _FieldEditorCard(
                key: ValueKey(field.id),
                field: field,
                onUpdate: (updated) =>
                    notifier.updateFormField(field.id, updated),
                onDelete: () => notifier.removeFormField(field.id),
              );
            },
          ),
        const SizedBox(height: 20),
        if (formFields.isNotEmpty)
          _QuickAddBar(onAdd: (type) => notifier.addFormField(type: type)),
      ],
    );
  }
}

class _EmptyFormState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyFormState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.dynamic_form_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ready to build your form?',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 8),
          Text(
            'Add custom questions to collect specific\ninformation from your attendees.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldEditorCard extends StatefulWidget {
  final RegistrationFieldModel field;
  final ValueChanged<RegistrationFieldModel> onUpdate;
  final VoidCallback onDelete;

  const _FieldEditorCard({
    super.key,
    required this.field,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_FieldEditorCard> createState() => _FieldEditorCardState();
}

class _FieldEditorCardState extends State<_FieldEditorCard> {
  late final TextEditingController _labelCtrl;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label);
  }

  @override
  void didUpdateWidget(covariant _FieldEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.label != widget.field.label &&
        _labelCtrl.text != widget.field.label) {
      _labelCtrl.text = widget.field.label;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded ? AppColors.primary : AppColors.divider,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Drag handle + Type + Actions
          _CardHeader(
            field: field,
            isExpanded: _isExpanded,
            onToggleExpand: () => setState(() => _isExpanded = !_isExpanded),
            onTypeChanged: (type) => widget.onUpdate(field.copyWith(type: type)),
            onDelete: widget.onDelete,
          ),

          // Main Content: Label + Placeholder/Options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabelInput(
                  controller: _labelCtrl,
                  onChanged: (val) => widget.onUpdate(field.copyWith(label: val)),
                  type: field.type,
                ),
                if (field.type == FormFieldType.multipleChoice ||
                    field.type == FormFieldType.checkboxes ||
                    field.type == FormFieldType.dropdown) ...[
                  const SizedBox(height: 16),
                  _OptionsBuilder(
                    options: field.options,
                    onUpdate: (opts) =>
                        widget.onUpdate(field.copyWith(options: opts)),
                  ),
                ],
                if (field.type == FormFieldType.repeatingBlock) ...[
                  const SizedBox(height: 16),
                  _NestedFieldsEditor(
                    nestedFields: field.nestedFields ?? [],
                    onUpdate: (fields) =>
                        widget.onUpdate(field.copyWith(nestedFields: fields)),
                  ),
                ],
                if (field.type == FormFieldType.fileUpload) ...[
                  const SizedBox(height: 16),
                  _AttachmentEditor(
                    field: field,
                    onUpdate: widget.onUpdate,
                  ),
                ],
              ],
            ),
          ),

          // Advanced Settings (Animated Expansion)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _AdvancedSettings(
              field: field,
              onUpdate: widget.onUpdate,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // Footer
          _CardFooter(
            field: field,
            onUpdate: widget.onUpdate,
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final RegistrationFieldModel field;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<FormFieldType?> onTypeChanged;
  final VoidCallback onDelete;

  const _CardHeader({
    required this.field,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onTypeChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator_rounded,
              color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FormFieldType>(
                value: field.type,
                isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted),
                style: AppTextStyles.labelS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                items: FormFieldType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(t),
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(t.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onTypeChanged,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isExpanded ? Icons.settings_rounded : Icons.settings_outlined,
              size: 20,
              color: isExpanded ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: onToggleExpand,
            tooltip: 'Advanced Settings',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'Delete Question',
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(FormFieldType type) {
    return switch (type) {
      FormFieldType.shortText => Icons.short_text_rounded,
      FormFieldType.longText => Icons.notes_rounded,
      FormFieldType.multipleChoice => Icons.radio_button_checked_rounded,
      FormFieldType.checkboxes => Icons.check_box_rounded,
      FormFieldType.dropdown => Icons.arrow_drop_down_circle_rounded,
      FormFieldType.email => Icons.email_rounded,
      FormFieldType.phone => Icons.phone_rounded,
      FormFieldType.number => Icons.numbers_rounded,
      FormFieldType.date => Icons.calendar_today_rounded,
      FormFieldType.time => Icons.access_time_rounded,
      FormFieldType.fileUpload => Icons.upload_file_rounded,
      FormFieldType.repeatingBlock => Icons.replay_rounded,
    };
  }
}

class _FieldLabelInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FormFieldType type;

  const _FieldLabelInput({
    required this.controller,
    required this.onChanged,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          if (type != FormFieldType.shortText) ...[
            Icon(_getTypeIcon(type), size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.labelM.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: type == FormFieldType.shortText
                    ? 'Enter your question...'
                    : 'Enter your question here...',
                hintStyle: AppTextStyles.bodyM
                    .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.normal),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(FormFieldType type) {
    return switch (type) {
      FormFieldType.shortText => Icons.short_text_rounded,
      FormFieldType.longText => Icons.notes_rounded,
      FormFieldType.multipleChoice => Icons.radio_button_checked_rounded,
      FormFieldType.checkboxes => Icons.check_box_rounded,
      FormFieldType.dropdown => Icons.arrow_drop_down_circle_rounded,
      FormFieldType.email => Icons.email_rounded,
      FormFieldType.phone => Icons.phone_rounded,
      FormFieldType.number => Icons.numbers_rounded,
      FormFieldType.date => Icons.calendar_today_rounded,
      FormFieldType.time => Icons.access_time_rounded,
      FormFieldType.fileUpload => Icons.upload_file_rounded,
      FormFieldType.repeatingBlock => Icons.replay_rounded,
    };
  }
}

class _CardFooter extends StatelessWidget {
  final RegistrationFieldModel field;
  final ValueChanged<RegistrationFieldModel> onUpdate;

  const _CardFooter({required this.field, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Required', style: AppTextStyles.labelS),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: field.isRequired,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => onUpdate(field.copyWith(isRequired: val)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsBuilder extends StatelessWidget {
  final List<String> options;
  final ValueChanged<List<String>> onUpdate;

  const _OptionsBuilder({required this.options, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final val = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.drag_indicator_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                const Icon(Icons.circle_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: val)
                      ..selection = TextSelection.collapsed(offset: val.length),
                    style: AppTextStyles.bodyM,
                    decoration: const InputDecoration(
                      hintText: 'Option text',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                    ),
                    onChanged: (newVal) {
                      final updated = List<String>.from(options);
                      updated[idx] = newVal;
                      onUpdate(updated);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: () {
                    final updated = List<String>.from(options)..removeAt(idx);
                    onUpdate(updated);
                  },
                )
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            final updated = List<String>.from(options)
              ..add('Option ${options.length + 1}');
            onUpdate(updated);
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Add Option',
                    style:
                        AppTextStyles.labelS.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAddMenu extends StatelessWidget {
  final ValueChanged<FormFieldType> onAdd;
  const _QuickAddMenu({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FormFieldType>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
      ),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onAdd,
      itemBuilder: (context) => FormFieldType.values.map((type) {
        return PopupMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getTypeIcon(type), size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(type.label, style: AppTextStyles.labelS),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getTypeIcon(FormFieldType type) {
    return switch (type) {
      FormFieldType.shortText => Icons.short_text_rounded,
      FormFieldType.longText => Icons.notes_rounded,
      FormFieldType.multipleChoice => Icons.radio_button_checked_rounded,
      FormFieldType.checkboxes => Icons.check_box_rounded,
      FormFieldType.dropdown => Icons.arrow_drop_down_circle_rounded,
      FormFieldType.email => Icons.email_rounded,
      FormFieldType.phone => Icons.phone_rounded,
      FormFieldType.number => Icons.numbers_rounded,
      FormFieldType.date => Icons.calendar_today_rounded,
      FormFieldType.time => Icons.access_time_rounded,
      FormFieldType.fileUpload => Icons.upload_file_rounded,
      FormFieldType.repeatingBlock => Icons.replay_rounded,
    };
  }
}

class _FormPreview extends StatelessWidget {
  final List<RegistrationFieldModel> fields;
  const _FormPreview({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Live Preview', style: AppTextStyles.labelM.copyWith(color: AppColors.primary)),
              const Spacer(),
              Text('${fields.length} Questions', style: AppTextStyles.caption),
            ],
          ),
          const Divider(height: 32),
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(f.label, style: AppTextStyles.labelM),
                    if (f.isRequired)
                      Text(' *', style: AppTextStyles.labelM.copyWith(color: AppColors.error)),
                  ],
                ),
                if (f.helpText != null) ...[
                  const SizedBox(height: 4),
                  Text(f.helpText!, style: AppTextStyles.caption),
                ],
                if (f.attachmentUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      f.attachmentUrl!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildPreviewInput(f),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPreviewInput(RegistrationFieldModel field) {
    switch (field.type) {
      case FormFieldType.shortText:
      case FormFieldType.email:
      case FormFieldType.phone:
      case FormFieldType.number:
        return _PreviewPlaceholder('Text Input Area');
      case FormFieldType.longText:
        return _PreviewPlaceholder('Paragraph Input Area', height: 80);
      case FormFieldType.multipleChoice:
      case FormFieldType.dropdown:
        return Column(
          children: field.options.map((o) => _PreviewOption(label: o, isRadio: true)).toList(),
        );
      case FormFieldType.checkboxes:
        return Column(
          children: field.options.map((o) => _PreviewOption(label: o, isRadio: false)).toList(),
        );
      case FormFieldType.date:
        return _PreviewPlaceholder('Select Date', icon: Icons.calendar_today_rounded);
      case FormFieldType.time:
        return _PreviewPlaceholder('Select Time', icon: Icons.access_time_rounded);
      case FormFieldType.fileUpload:
        return _PreviewPlaceholder('Upload File', icon: Icons.upload_file_rounded);
      case FormFieldType.repeatingBlock:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Add Entry for ${field.label}', style: AppTextStyles.labelS.copyWith(color: AppColors.primary)),
            ],
          ),
        );
    }
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double height;
  const _PreviewPlaceholder(this.text, {this.icon, this.height = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 12),
          ],
          Text(text, style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _PreviewOption extends StatelessWidget {
  final String label;
  final bool isRadio;
  const _PreviewOption({required this.label, required this.isRadio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isRadio ? Icons.radio_button_off_rounded : Icons.check_box_outline_blank_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyM),
        ],
      ),
    );
  }
}

class _QuickAddBar extends StatelessWidget {
  final ValueChanged<FormFieldType> onAdd;
  const _QuickAddBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AddIconButton(
              icon: Icons.short_text_rounded,
              label: 'Text',
              onTap: () => onAdd(FormFieldType.shortText)),
          _AddIconButton(
              icon: Icons.radio_button_checked_rounded,
              label: 'Choice',
              onTap: () => onAdd(FormFieldType.multipleChoice)),
          _AddIconButton(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              onTap: () => onAdd(FormFieldType.date)),
          _AddIconButton(
              icon: Icons.upload_file_rounded,
              label: 'File',
              onTap: () => onAdd(FormFieldType.fileUpload)),
          _AddIconButton(
              icon: Icons.replay_rounded,
              label: 'Logic',
              onTap: () => onAdd(FormFieldType.repeatingBlock)),
        ],
      ),
    );
  }
}

class _AddIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddIconButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _AdvancedSettings extends StatelessWidget {
  final RegistrationFieldModel field;
  final ValueChanged<RegistrationFieldModel> onUpdate;

  const _AdvancedSettings({required this.field, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'ADVANCED CONFIGURATION',
                style: AppTextStyles.labelS.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingInput(
            label: 'Help Text / Description',
            hint: 'Small hint shown below the field for guidance...',
            initialValue: field.helpText,
            onChanged: (val) => onUpdate(field.copyWith(helpText: val.isEmpty ? null : val)),
          ),
          const SizedBox(height: 16),
          _LogicBuilder(
            field: field,
            onUpdate: onUpdate,
          ),
          if (field.type == FormFieldType.number) ...[
            const SizedBox(height: 16),
            _ConstraintsEditor(
              field: field,
              onUpdate: onUpdate,
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingInput extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const _SettingInput({
    required this.label,
    required this.hint,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SettingInput> createState() => _SettingInputState();
}

class _SettingInputState extends State<_SettingInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          style: AppTextStyles.bodyS,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _LogicBuilder extends ConsumerWidget {
  final RegistrationFieldModel field;
  final ValueChanged<RegistrationFieldModel> onUpdate;

  const _LogicBuilder({required this.field, required this.onUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFields = ref.watch(createEventProvider).formFields;
    // Only allow depending on fields that come BEFORE this one to prevent circular logic
    final currentIdx = allFields.indexWhere((f) => f.id == field.id);
    final previousFields =
        currentIdx > 0 ? allFields.sublist(0, currentIdx) : <RegistrationFieldModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Visibility Logic (Show If)',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (previousFields.isEmpty)
              Text('No previous questions to depend on',
                  style:
                      AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              if (field.showIf != null)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          child: Column(
            children: [
              if (field.showIf == null)
                _buildEmptyState(context, previousFields)
              else
                _buildActiveLogic(context, previousFields),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, List<RegistrationFieldModel> previousFields) {
    return Column(
      children: [
        const Icon(Icons.auto_fix_high_rounded, size: 32, color: AppColors.divider),
        const SizedBox(height: 8),
        Text('No logic applied', style: AppTextStyles.caption),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: previousFields.isEmpty
                ? null
                : () => _showLogicDialog(context, previousFields),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Show Logic'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveLogic(BuildContext context, List<RegistrationFieldModel> previousFields) {
    // Attempt to parse the logic string for display
    // Format is usually: [id] == 'value' or [id] != 'value'
    final parts = field.showIf!.split(' ');
    String displayString = field.showIf!;

    if (parts.length >= 3) {
      final triggerId = parts[0];
      final operator = parts[1];
      final value = parts.sublist(2).join(' ').replaceAll("'", "");

      final triggerField = previousFields.firstWhere(
        (f) => f.id == triggerId,
        orElse: () => RegistrationFieldModel(id: '?', label: 'Deleted Question'),
      );

      displayString = "Show if \"${triggerField.label}\" ${operator == '==' ? 'is' : 'is not'} \"$value\"";
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_tree_rounded, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayString,
                style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _showLogicDialog(context, previousFields),
                child: const Text('Edit Condition'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onUpdate(field.copyWith(showIf: null, dependsOnField: null)),
              icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: AppColors.error),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogicDialog(BuildContext context, List<RegistrationFieldModel> previousFields) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogicEditorSheet(
        previousFields: previousFields,
        initialLogic: field.showIf,
        onSave: (logic, dependsOnId) {
          onUpdate(field.copyWith(showIf: logic, dependsOnField: dependsOnId));
        },
      ),
    );
  }
}

class _LogicEditorSheet extends StatefulWidget {
  final List<RegistrationFieldModel> previousFields;
  final String? initialLogic;
  final Function(String logic, String dependsOnId) onSave;

  const _LogicEditorSheet({
    required this.previousFields,
    this.initialLogic,
    required this.onSave,
  });

  @override
  State<_LogicEditorSheet> createState() => _LogicEditorSheetState();
}

class _LogicEditorSheetState extends State<_LogicEditorSheet> {
  String? _selectedFieldId;
  String _operator = '==';
  final _valueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLogic != null) {
      final parts = widget.initialLogic!.split(' ');
      if (parts.length >= 3) {
        _selectedFieldId = parts[0];
        _operator = parts[1];
        _valueCtrl.text = parts.sublist(2).join(' ').replaceAll("'", "");
      }
    } else if (widget.previousFields.isNotEmpty) {
      _selectedFieldId = widget.previousFields.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Setup Condition', style: AppTextStyles.headingM),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('When this question...', style: AppTextStyles.labelS),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            value: _selectedFieldId,
            items: widget.previousFields.map((f) {
              return DropdownMenuItem(value: f.id, child: Text(f.label.isEmpty ? 'Untitled' : f.label));
            }).toList(),
            onChanged: (val) => setState(() => _selectedFieldId = val),
          ),
          const SizedBox(height: 20),
          Text('Has an answer that...', style: AppTextStyles.labelS),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            value: _operator,
            items: _getOperatorsForSelectedField(),
            onChanged: (val) => setState(() => _operator = val!),
          ),
          const SizedBox(height: 20),
          Text('This value:', style: AppTextStyles.labelS),
          const SizedBox(height: 8),
          _buildValueInput(),
          const SizedBox(height: 12),
          _buildSuggestions(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Apply Logic'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getOperatorsForSelectedField() {
    final selectedField = widget.previousFields.firstWhere(
      (f) => f.id == _selectedFieldId,
      orElse: () => RegistrationFieldModel.create(),
    );

    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: '==', child: Text('Is equal to')),
      const DropdownMenuItem(value: '!=', child: Text('Is not equal to')),
    ];

    if (selectedField.type == FormFieldType.number) {
      items.addAll([
        const DropdownMenuItem(value: '>', child: Text('Is greater than')),
        const DropdownMenuItem(value: '<', child: Text('Is less than')),
      ]);
    }

    return items;
  }

  Widget _buildSuggestions() {
    final suggestions = <String>[];
    for (final f in widget.previousFields) {
      if (f.label.toLowerCase().contains('yes') ||
          f.label.toLowerCase().contains('no') ||
          f.options.any((o) => o.toLowerCase() == 'yes')) {
        suggestions.add("${f.id} == 'Yes'");
      }
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUGGESTIONS',
            style: AppTextStyles.caption
                .copyWith(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: suggestions.take(3).map((s) {
            return InkWell(
              onTap: () {
                final parts = s.split(' ');
                setState(() {
                  _selectedFieldId = parts[0];
                  _operator = parts[1];
                  _valueCtrl.text = parts.sublist(2).join(' ').replaceAll("'", "");
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Text('Common Rule',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontSize: 10)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildValueInput() {
    final selectedField = widget.previousFields.firstWhere(
      (f) => f.id == _selectedFieldId,
      orElse: () => RegistrationFieldModel.create(),
    );

    if (selectedField.type == FormFieldType.multipleChoice ||
        selectedField.type == FormFieldType.dropdown ||
        selectedField.type == FormFieldType.checkboxes) {
      final opts = selectedField.options;
      if (opts.isNotEmpty) {
        if (!_valueCtrl.text.isNotEmpty || !opts.contains(_valueCtrl.text)) {
           _valueCtrl.text = opts.first;
        }
        return _buildDropdown<String>(
          value: _valueCtrl.text,
          items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) => setState(() => _valueCtrl.text = val!),
        );
      }
    }

    return TextField(
      controller: _valueCtrl,
      decoration: InputDecoration(
        hintText: 'Enter value',
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }

  void _save() {
    if (_selectedFieldId != null && _valueCtrl.text.isNotEmpty) {
      final logic = "$_selectedFieldId $_operator '${_valueCtrl.text}'";
      widget.onSave(logic, _selectedFieldId!);
      Navigator.pop(context);
    }
  }
}

class _ConstraintsEditor extends StatelessWidget {
  final RegistrationFieldModel field;
  final ValueChanged<RegistrationFieldModel> onUpdate;

  const _ConstraintsEditor({required this.field, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SettingInput(
            label: 'Min Value',
            hint: '0',
            initialValue: field.minValue?.toString(),
            onChanged: (val) => onUpdate(field.copyWith(minValue: double.tryParse(val))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SettingInput(
            label: 'Max Value',
            hint: '100',
            initialValue: field.maxValue?.toString(),
            onChanged: (val) => onUpdate(field.copyWith(maxValue: double.tryParse(val))),
          ),
        ),
      ],
    );
  }
}

class _NestedFieldsEditor extends StatelessWidget {
  final List<RegistrationFieldModel> nestedFields;
  final ValueChanged<List<RegistrationFieldModel>> onUpdate;

  const _NestedFieldsEditor({required this.nestedFields, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Sub-questions for each entry', style: AppTextStyles.labelS.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (nestedFields.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No internal fields added yet.',
                style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
            ),
          ...nestedFields.asMap().entries.map((entry) {
             final idx = entry.key;
             final f = entry.value;
             return Container(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               decoration: BoxDecoration(
                 color: AppColors.white,
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Row(
                 children: [
                   Icon(_getTypeIcon(f.type), size: 14, color: AppColors.primary),
                   const SizedBox(width: 8),
                   Expanded(child: Text(f.label.isEmpty ? 'Untitled Question' : f.label, style: AppTextStyles.bodyS)),
                   IconButton(
                     icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                     constraints: const BoxConstraints(),
                     padding: EdgeInsets.zero,
                     onPressed: () {
                       final updated = List<RegistrationFieldModel>.from(nestedFields)..removeAt(idx);
                       onUpdate(updated);
                     },
                   ),
                 ],
               ),
             );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              final updated = List<RegistrationFieldModel>.from(nestedFields)..add(RegistrationFieldModel.create());
              onUpdate(updated);
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Internal Question'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTextStyles.labelS,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(FormFieldType type) {
    return switch (type) {
      FormFieldType.shortText => Icons.short_text_rounded,
      FormFieldType.longText => Icons.notes_rounded,
      FormFieldType.multipleChoice => Icons.radio_button_checked_rounded,
      FormFieldType.checkboxes => Icons.check_box_rounded,
      FormFieldType.dropdown => Icons.arrow_drop_down_circle_rounded,
      FormFieldType.email => Icons.email_rounded,
      FormFieldType.phone => Icons.phone_rounded,
      FormFieldType.number => Icons.numbers_rounded,
      FormFieldType.date => Icons.calendar_today_rounded,
      FormFieldType.time => Icons.access_time_rounded,
      FormFieldType.fileUpload => Icons.upload_file_rounded,
      FormFieldType.repeatingBlock => Icons.replay_rounded,
    };
  }
}

class _AttachmentEditor extends StatefulWidget {
  final RegistrationFieldModel field;
  final ValueChanged<RegistrationFieldModel> onUpdate;

  const _AttachmentEditor({required this.field, required this.onUpdate});

  @override
  State<_AttachmentEditor> createState() => _AttachmentEditorState();
}

class _AttachmentEditorState extends State<_AttachmentEditor> {
  bool _isUploading = false;

  Future<void> _pickAndUpload({bool fromCamera = false}) async {
    setState(() => _isUploading = true);
    try {
      File? file;
      if (fromCamera) {
        file = await CloudinaryService.pickImageFromCamera();
      } else {
        // Show choice: gallery or any file
        file = await CloudinaryService.pickImage();
      }
      if (file == null) return;
      final url = await CloudinaryService.uploadFile(file);
      if (url != null) {
        widget.onUpdate(widget.field.copyWith(attachmentUrl: url));
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
        widget.onUpdate(widget.field.copyWith(attachmentUrl: url));
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

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'QR Code / Attachment',
                style: AppTextStyles.labelS.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (field.attachmentUrl != null)
                TextButton.icon(
                  onPressed: () => widget.onUpdate(field.copyWith(attachmentUrl: null)),
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: AppTextStyles.labelS.copyWith(fontSize: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isUploading)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 8),
                    Text('Uploading to Cloudinary...', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            )
          else if (field.attachmentUrl == null)
            _buildEmptyState()
          else
            _buildPreviewState(field.attachmentUrl!),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        // Option 1: Image (gallery)
        _UploadButton(
          icon: Icons.photo_library_rounded,
          label: 'Pick from Gallery',
          subtitle: 'Upload QR code or screenshot',
          onTap: () => _pickAndUpload(),
        ),
        const SizedBox(height: 8),
        // Option 2: Camera
        _UploadButton(
          icon: Icons.camera_alt_rounded,
          label: 'Take a Photo',
          subtitle: 'Use camera to capture QR code',
          onTap: () => _pickAndUpload(fromCamera: true),
        ),
        const SizedBox(height: 8),
        // Option 3: Any file (PDF etc)
        _UploadButton(
          icon: Icons.attach_file_rounded,
          label: 'Attach Any File',
          subtitle: 'PDF, document, or other file',
          onTap: _pickAnyFile,
        ),
      ],
    );
  }

  Widget _buildPreviewState(String url) {
    final isImage = CloudinaryService.isImageUrl(url);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isImage) ...[
          // ── Image Preview Container ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Image fills a 16:9 aspect ratio box
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.background,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Loading preview...',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_rounded,
                                color: AppColors.textMuted, size: 36),
                            SizedBox(height: 6),
                            Text('Could not load preview',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Floating "Change" chip on top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _pickAndUpload(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Image uploaded successfully',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
        ] else ...[
          // ── Non-image File Preview ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insert_drive_file_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File uploaded',
                          style: AppTextStyles.labelS
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(
                        url,
                        style: AppTextStyles.caption
                            .copyWith(fontSize: 9, color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.success),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        // ── Action Buttons ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  textStyle: AppTextStyles.labelS.copyWith(fontSize: 11),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Link copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  textStyle: AppTextStyles.labelS.copyWith(fontSize: 11),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadButton extends StatelessWidget {

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelS.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

