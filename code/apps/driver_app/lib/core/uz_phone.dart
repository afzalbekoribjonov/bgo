import 'package:flutter/services.dart';

/// O'zbek telefon raqami formatlash: "+998" qatiy prefiks (o'chmas), keyin 9 raqam
/// "+998 94 108 - 09 - 16" ko'rinishida. plan/06-driver-app.md
class UzPhoneFormatter extends TextInputFormatter {
  /// Matndan faqat abonent raqamini (998siz, 9 ta) ajratadi.
  static String digitsOf(String text) {
    var d = text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('998')) d = d.substring(3);
    if (d.length > 9) d = d.substring(0, 9);
    return d;
  }

  /// API uchun E.164: "+998XXXXXXXXX".
  static String e164(String text) => '+998${digitsOf(text)}';

  /// To'liq 9 raqam kiritilganmi.
  static bool isComplete(String text) => digitsOf(text).length == 9;

  /// 9 raqamni "+998 94 108 - 09 - 16" ko'rinishiga keltiradi.
  static String format(String digits) {
    final b = StringBuffer('+998 ');
    for (var i = 0; i < digits.length; i++) {
      b.write(digits[i]);
      final more = i < digits.length - 1;
      if (i == 1 && more) {
        b.write(' ');
      } else if (i == 4 && more) {
        b.write(' - ');
      } else if (i == 6 && more) {
        b.write(' - ');
      }
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = format(digitsOf(newValue.text));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
