
class ConditionEvaluator {
  /// Evaluates a condition string against current form values.
  /// Supported format: "fieldId == 'Value'" or "fieldId != 'Value'"
  /// or "fieldId > Number" or "fieldId < Number"
  static bool evaluate(String condition, Map<String, dynamic> formValues) {
    try {
      final parts = condition.split(' ');
      if (parts.length < 3) return true;

      final fieldId = parts[0];
      final operator = parts[1];
      var threshold = parts.sublist(2).join(' ');

      final actualValue = formValues[fieldId];
      if (actualValue == null) return false;

      // Strip quotes from comparison value if present
      if (threshold.startsWith("'") && threshold.endsWith("'")) {
        threshold = threshold.substring(1, threshold.length - 1);
      } else if (threshold.startsWith('"') && threshold.endsWith('"')) {
        threshold = threshold.substring(1, threshold.length - 1);
      }

      switch (operator) {
        case '==':
          return actualValue.toString() == threshold;
        case '!=':
          return actualValue.toString() != threshold;
        case '>':
          final actualNum = double.tryParse(actualValue.toString()) ?? 0;
          final thresholdNum = double.tryParse(threshold) ?? 0;
          return actualNum > thresholdNum;
        case '<':
          final actualNum = double.tryParse(actualValue.toString()) ?? 0;
          final thresholdNum = double.tryParse(threshold) ?? 0;
          return actualNum < thresholdNum;
        case '>=':
          final actualNum = double.tryParse(actualValue.toString()) ?? 0;
          final thresholdNum = double.tryParse(threshold) ?? 0;
          return actualNum >= thresholdNum;
        case '<=':
          final actualNum = double.tryParse(actualValue.toString()) ?? 0;
          final thresholdNum = double.tryParse(threshold) ?? 0;
          return actualNum <= thresholdNum;
        default:
          return true;
      }
    } catch (e) {
      return true; // Default to showing if error parsing
    }
  }
}
