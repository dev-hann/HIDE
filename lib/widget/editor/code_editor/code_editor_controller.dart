import 'package:flutter/material.dart';
import 'package:h_ide/model/syntax.dart';

class CodeEditorController extends TextEditingController {
  CodeEditorController({
    required String text,
    this.syntax,
  }) : super(text: text);
  final Syntax? syntax;

  int get lines {
    return text.split("\n").length;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> list = [];
    final lines = text.split("\n");
    final linesLen = lines.length;
    final defaultStyle = Theme.of(context).textTheme.bodyLarge!;
    for (int index = 0; index < linesLen; index++) {
      final line = lines[index];
      final words = line.split(" ");
      final List<TextSpan> wordSpanList = [];
      for (final word in words) {
        TextStyle tmpStyle = defaultStyle;
        if (syntax != null) {
          final color = syntax!.color(word);
          if (color != null) {
            tmpStyle = defaultStyle.apply(color: color);
          }
        }
        wordSpanList.add(TextSpan(text: word, style: tmpStyle));
        wordSpanList.add(TextSpan(text: ' ', style: tmpStyle));
      }
      wordSpanList.removeLast();
      list.addAll(wordSpanList);
      list.add(TextSpan(text: "\n", style: defaultStyle));
    }
    list.removeLast();
    return TextSpan(children: list, style: defaultStyle);
  }
}
