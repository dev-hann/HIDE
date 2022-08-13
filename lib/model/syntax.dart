import 'dart:ui';

class Syntax {
  Syntax(this.laguage, this.items);
  final String laguage;
  final Map<String, dynamic> items;

  Color? color(String key) {
    final value = items[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return color(value);
    }
    return Color(value);
  }
}
