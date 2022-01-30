import 'package:flutter/services.dart';

class RestoreNonEmptyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length > 1 && newValue.text.isEmpty) {
      return oldValue;
    }
    return newValue;
  }
}
