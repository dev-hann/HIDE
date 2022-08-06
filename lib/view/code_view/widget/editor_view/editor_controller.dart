import 'package:flutter/material.dart';

class EditorController extends TextEditingController {
  EditorController({
    Map<String, TextStyle>? syntaxMap,
  }) : syntaxMap = syntaxMap ?? {};
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final Map<String, TextStyle> syntaxMap;

  void moveToEnd() {
    focusNode.requestFocus();
    selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
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
