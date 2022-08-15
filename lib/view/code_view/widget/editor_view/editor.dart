import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

class Editor extends EditableText {
  Editor({
    super.key,
    required EditorController controller,
    required super.focusNode,
    required super.style,
    required super.cursorColor,
    required super.backgroundCursorColor,
  }) : super(
          controller: controller,
          maxLines: null,
          scrollController: ScrollController(),
          scrollPhysics: const NeverScrollableScrollPhysics(),
        );

  @override
  EditableTextState createState() {
    return EditorState();
  }
}

class EditorState extends EditableTextState {}
