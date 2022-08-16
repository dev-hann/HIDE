import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor/render_editor.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

class Editor extends StatefulWidget {
  const Editor({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final EditorController controller;
  @override
  State<StatefulWidget> createState() {
    return StateEditor();
  }
}

class StateEditor extends State<Editor> {
  @override
  Widget build(BuildContext context) {
    return RenderEditorWidget(
        text: widget.controller
            .buildTextSpan(context: context, withComposing: true));
  }
}
