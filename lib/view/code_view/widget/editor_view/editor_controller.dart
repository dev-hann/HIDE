import 'package:flutter/material.dart';

class EditorController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final syntaxMap = {"class": TextStyle(color: Colors.red)};
    final keyList = syntaxMap.keys;
    final List<TextSpan> list = [];
    final lines = text.split("\n");
    for (final line in lines) {
      final words = line.split(" ");
      final List<TextSpan> wordSpanList = [];
      for (final word in words) {
        TextStyle style = TextStyle(color: Colors.black);
        if (keyList.contains(word)) {
          style = syntaxMap[word]!;
        }
        wordSpanList.add(TextSpan(text: word, style: style));
        wordSpanList.add(TextSpan(text: ' ', style: style));
      }
      wordSpanList.removeLast();
      list.addAll(wordSpanList);
      list.add(TextSpan(text: "\n", style: TextStyle(color: Colors.black)));
    }
    list.removeLast();
    return TextSpan(children: list);
  }
}
