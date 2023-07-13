import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor/editor.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

class EditorView extends StatelessWidget {
  const EditorView({
    Key? key,
    required this.controller,
    required this.readOnly,
  }) : super(key: key);
  final EditorController controller;
  final bool readOnly;
  @override
  Widget build(BuildContext context) {
    return Editor(controller: controller);
  }
}
