

enum FormFieldType {
  shortText,
  longText,
  multipleChoice,
  checkboxes,
  dropdown,
  email,
  phone,
  number,
  date,
  time,
  fileUpload,
  repeatingBlock,
}

extension FormFieldTypeExtension on FormFieldType {
  String get label {
    switch (this) {
      case FormFieldType.shortText:
        return 'Short Text';
      case FormFieldType.longText:
        return 'Long Text';
      case FormFieldType.multipleChoice:
        return 'Multiple Choice';
      case FormFieldType.checkboxes:
        return 'Checkboxes';
      case FormFieldType.dropdown:
        return 'Dropdown';
      case FormFieldType.email:
        return 'Email';
      case FormFieldType.phone:
        return 'Phone';
      case FormFieldType.number:
        return 'Number';
      case FormFieldType.date:
        return 'Date Picker';
      case FormFieldType.time:
        return 'Time Picker';
      case FormFieldType.fileUpload:
        return 'File Upload';
      case FormFieldType.repeatingBlock:
        return 'Repeating Block';
    }
  }

  static FormFieldType fromString(String val) {
    return FormFieldType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FormFieldType.shortText,
    );
  }
}

class RegistrationFieldModel {
  final String id;
  final FormFieldType type;
  final String label;
  final bool isRequired;
  final List<String> options;
  final String? helpText;
  final String? attachmentUrl; // For QR codes, payment instructions, etc.
  
  // Conditional Logic
  final String? showIf; // e.g. "accommodationNeeded == 'Yes'"
  final String? dependsOnField; // ID of the field that triggers this condition

  // Repeating Block Logic (e.g. for team members)
  final bool isRepeatingBlock;
  final String? repeatSourceField; // ID of the field (number type) that controls repetition
  final List<RegistrationFieldModel>? nestedFields;

  // Constraints
  final double? minValue;
  final double? maxValue;

  const RegistrationFieldModel({
    required this.id,
    this.type = FormFieldType.shortText,
    this.label = '',
    this.isRequired = false,
    this.options = const [],
    this.helpText,
    this.attachmentUrl,
    this.showIf,
    this.dependsOnField,
    this.isRepeatingBlock = false,
    this.repeatSourceField,
    this.nestedFields,
    this.minValue,
    this.maxValue,
  });

  /// Factory for a brand new empty field
  factory RegistrationFieldModel.create() {
    return RegistrationFieldModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );
  }

  RegistrationFieldModel copyWith({
    FormFieldType? type,
    String? label,
    bool? isRequired,
    List<String>? options,
    String? helpText,
    String? attachmentUrl,
    String? showIf,
    String? dependsOnField,
    bool? isRepeatingBlock,
    String? repeatSourceField,
    List<RegistrationFieldModel>? nestedFields,
    double? minValue,
    double? maxValue,
  }) {
    return RegistrationFieldModel(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      helpText: helpText ?? this.helpText,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      showIf: showIf ?? this.showIf,
      dependsOnField: dependsOnField ?? this.dependsOnField,
      isRepeatingBlock: isRepeatingBlock ?? this.isRepeatingBlock,
      repeatSourceField: repeatSourceField ?? this.repeatSourceField,
      nestedFields: nestedFields ?? this.nestedFields,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'isRequired': isRequired,
      'options': options,
      'helpText': helpText,
      'attachmentUrl': attachmentUrl,
      'showIf': showIf,
      'dependsOnField': dependsOnField,
      'isRepeatingBlock': isRepeatingBlock,
      'repeatSourceField': repeatSourceField,
      'nestedFields': nestedFields?.map((f) => f.toJson()).toList(),
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }

  factory RegistrationFieldModel.fromJson(Map<String, dynamic> json) {
    return RegistrationFieldModel(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: FormFieldTypeExtension.fromString(json['type'] as String? ?? ''),
      label: json['label'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      helpText: json['helpText'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      showIf: json['showIf'] as String?,
      dependsOnField: json['dependsOnField'] as String?,
      isRepeatingBlock: json['isRepeatingBlock'] as bool? ?? false,
      repeatSourceField: json['repeatSourceField'] as String?,
      nestedFields: (json['nestedFields'] as List<dynamic>?)
          ?.map((f) => RegistrationFieldModel.fromJson(f as Map<String, dynamic>))
          .toList(),
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
    );
  }
}
