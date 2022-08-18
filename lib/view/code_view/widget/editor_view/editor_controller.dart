import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/syntax.dart';

class EditorController with EquatableMixin {
  EditorController({
    required this.file,
    this.syntax,
  });
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final Syntax? syntax;
  final HFile file;
  String get text => file.data;
  int get cursorLineNumber {
    // return text.substring(0, selection.baseOffset).split("\n").length;
    return 0;
  }

  void moveToEnd() {
    // focusNode.requestFocus();
    // selection = TextSelection.collapsed(offset: text.length);
  }

  TextSpan buildTextSpan(BuildContext context) {
    final List<TextSpan> list = [];
    final lines = text.split("\n");
    final linesLen = lines.length;
    final defaultStyle = Theme.of(context).textTheme.bodyText1!;
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
    return TextSpan(children: list);
  }

  @override
  List<Object?> get props => [file];
}
