import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/syntax.dart';

class EditorController extends TextEditingController with EquatableMixin {
  EditorController({
    required this.file,
    this.syntax,
  }) : super(text: file.data);
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final Syntax? syntax;
  final HFile file;

  int get caretLineNumber {
    return text.substring(0, selection.baseOffset).split("\n").length;
  }

  int get maxLineNumber {
    return text.split("\n").length;
  }

  String? lineText(int line) {
    try {
      final list = text.split("\n");
      return list[line - 1];
    } catch (e) {
      return null;
    }
  }

  void moveToEnd() {
    // focusNode.requestFocus();
    // selection = TextSelection.collapsed(offset: text.length);
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
