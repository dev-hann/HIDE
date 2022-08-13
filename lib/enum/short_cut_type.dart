import 'package:flutter/services.dart';

enum ShortCutType {
  suggestion,
}

extension ShortCutExtension on ShortCutType {
  LogicalKeyboardKey initKey() {
    switch (this) {
      case ShortCutType.suggestion:
        return LogicalKeyboardKey.alt;
    }
  }

  LogicalKeyboardKey commandKey() {
    switch (this) {
      case ShortCutType.suggestion:
        return LogicalKeyboardKey.enter;
    }
  }
}
