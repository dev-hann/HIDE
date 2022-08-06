import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

class EditorView extends StatelessWidget {
  const EditorView({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final EditorController controller;
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topLeft,
        child: EditableText(
          maxLines: null,
          controller: controller,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          backgroundCursorColor: Colors.red,
          focusNode: controller.focusNode,
        ),
      ),
    );
  }
}
