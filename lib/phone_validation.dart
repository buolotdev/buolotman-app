import 'package:flutter/services.dart';

const countryPhoneRules = <String, ({String dial, int length})>{
  'Benin': (dial: '+229', length: 8),
  'Nigeria': (dial: '+234', length: 10),
  'Rwanda': (dial: '+250', length: 9),
  'Kenya': (dial: '+254', length: 9),
  'Ghana': (dial: '+233', length: 9),
  'South Africa': (dial: '+27', length: 9),
  'Ivory Coast': (dial: '+225', length: 10),
  'Togo': (dial: '+228', length: 8),
  'Cameroon': (dial: '+237', length: 9),
  'Senegal': (dial: '+221', length: 9),
};

bool validPhoneForCountry(String value, String country) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final rule = countryPhoneRules[country];
  if (rule == null) {
    return digits.length >= 7 &&
        digits.length <= 15 &&
        RegExp(r'[1-9]').hasMatch(digits);
  }
  final dialDigits = rule.dial.replaceAll('+', '');
  final national = digits.startsWith(dialDigits)
      ? digits.substring(dialDigits.length)
      : digits;
  if (national.length != rule.length || !RegExp(r'[1-9]').hasMatch(national)) {
    return false;
  }
  return !RegExp(r'^(\d)\1+$').hasMatch(national);
}

TextInputFormatter phoneInputFormatter(String country) {
  final rule = countryPhoneRules[country];
  final maxDigits = rule == null
      ? 15
      : rule.length + rule.dial.replaceAll('+', '').length;
  return TextInputFormatter.withFunction((oldValue, newValue) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^0-9+()\s-]'), '');
    if (cleaned.replaceAll(RegExp(r'\D'), '').length > maxDigits) {
      return oldValue;
    }
    return newValue.copyWith(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  });
}
