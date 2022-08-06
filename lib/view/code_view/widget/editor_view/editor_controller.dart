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
    final List<TextSpan> list = [];
    final lines = text.split("\n");
    final defaultStyle = Theme.of(context).textTheme.bodyText1!;
    for (final line in lines) {
      final words = line.split(" ");

      final List<TextSpan> wordSpanList = [];
      for (final word in words) {
        TextStyle tmpStyle = syntaxMap[word] ?? defaultStyle;
        wordSpanList.add(TextSpan(text: word, style: tmpStyle));
        wordSpanList.add(TextSpan(text: ' ', style: tmpStyle));
      }
      wordSpanList.removeLast();
      list.addAll(wordSpanList);
      list.add(TextSpan(text: "\n ", style: defaultStyle));
    }
    list.removeLast();
    return TextSpan(children: list);
  }
}
