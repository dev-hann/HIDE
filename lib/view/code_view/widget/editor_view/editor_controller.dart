import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';

class EditorController extends TextEditingController with EquatableMixin {
  EditorController({
    required this.file,
    Map<String, TextStyle>? syntaxMap,
  })  : syntaxMap = syntaxMap ?? {},
        super(text: File(file.path).readAsStringSync());

  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final Map<String, TextStyle> syntaxMap;
  final HFile file;
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
      list.add(TextSpan(text: "\n", style: defaultStyle));
    }
    list.removeLast();
    return TextSpan(children: list);
  }

  @override
  List<Object?> get props => [file];
}
