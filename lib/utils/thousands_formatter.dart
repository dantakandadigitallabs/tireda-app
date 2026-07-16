import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove any existing commas to process the raw number
    String text = newValue.text.replaceAll(',', '');

    // Split at the decimal to handle whole numbers and cents separately
    List<String> parts = text.split('.');
    String intPart = parts[0];

    if (intPart.isNotEmpty) {
      try {
        int value = int.parse(intPart);
        intPart = NumberFormat('#,##0', 'en_US').format(value);
      } catch (e) {
        // Fallback if parsing fails (e.g., number is too long)
      }
    }

    String formattedText = intPart;

    // Reattach the decimal part if it exists
    if (parts.length > 1) {
      formattedText += '.${parts[1]}';
    } else if (text.endsWith('.')) {
      formattedText += '.';
    }

    // Return the new formatted value while keeping the cursor at the end
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}