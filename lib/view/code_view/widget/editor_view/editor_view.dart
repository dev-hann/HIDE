import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

class EditorView extends StatelessWidget {
  EditorView({Key? key}) : super(key: key);
  final EditorController controller = EditorController();
  @override
  Widget build(BuildContext context) {
    return EditableText(
      key: UniqueKey(),
      controller: controller,
      focusNode: FocusNode(),
      style: const TextStyle(color: Colors.black),
      cursorColor: Colors.black,
      backgroundCursorColor: Colors.red,
      maxLines: null,
    );
  }
}
