import 'package:flutter/services.dart';
import 'package:h_ide/enum/short_cut_type.dart';

class ShortCut {
  ShortCut({
    required this.enable,
    required this.type,
    LogicalKeyboardKey? initKey,
    LogicalKeyboardKey? commandKey,
  })  : initKey = enable ? initKey ?? type.initKey() : null,
        commandKey = enable ? commandKey ?? type.commandKey() : null;
  final bool enable;
  final ShortCutType type;
  final LogicalKeyboardKey? initKey;
  final LogicalKeyboardKey? commandKey;
}
