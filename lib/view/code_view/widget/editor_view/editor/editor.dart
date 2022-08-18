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
  late EditorController _controller;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  int _offset = 0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("@#@#@");
        _controller.focusNode.requestFocus();
      },
      child: ColoredBox(
        color: Colors.transparent,
        child: Actions(
          actions: {
            DirectionalFocusIntent: DirectionalFocusAction.forTextField()
          },
          child: Focus(
            focusNode: _controller.focusNode,
            child: RenderEditorWidget(
              text: _controller.buildTextSpan(context),
              carotOffset: _offset,
              onChangedCarotOffset: (value) {
                print(value);
              },
            ),
          ),
        ),
      ),
    );
  }
}

