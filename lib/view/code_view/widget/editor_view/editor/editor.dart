import 'dart:math' as math;
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
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextEditingShortcuts(
      child: GestureDetector(
        onTap: () {
          _controller.focusNode.requestFocus();
        },
        child: ColoredBox(
          color: Colors.transparent,
          child: Actions(
            actions: {
              ExtendSelectionByCharacterIntent:
            },
            child: Focus(
              focusNode: _controller.focusNode,
              child: RenderEditorWidget(
                text: _controller.buildTextSpan(
                  context: context,
                  withComposing: true,
                ),
                carotOffset: _controller.value.selection.baseOffset,
                onChangedCarotOffset: (value) {
                  print(value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomAction extends Action<ExtendSelectionByCharacterIntent> {
  CustomAction(this.controller);
  final EditorController controller;

  void _update(int offset) {
    controller.selection = TextSelection.collapsed(offset: offset);
  }


  @override
  void invoke(ExtendSelectionByCharacterIntent intent) {
    final offset = controller.selection.baseOffset;
    if(intent.forward){
      _update(offset+1);
    }
  }
}
