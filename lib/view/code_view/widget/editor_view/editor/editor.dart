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
                  HorizontalCaretAction(_controller),
              ExtendSelectionVerticallyToAdjacentLineIntent:
                  VerticalCaretAction(_controller),
            },
            child: Focus(
              focusNode: _controller.focusNode,
              child: RenderEditorWidget(
                text: _controller.buildTextSpan(
                  context: context,
                  withComposing: true,
                ),
                caretOffset: _controller.value.selection.baseOffset,
                onChangedCaretOffset: (value) {
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

class VerticalCaretAction
    extends Action<ExtendSelectionVerticallyToAdjacentLineIntent> {
  VerticalCaretAction(this.controller);
  final EditorController controller;
  @override
  void invoke(ExtendSelectionVerticallyToAdjacentLineIntent intent) {
    final currentLine = controller.caretLineNumber;
    final maxLine = controller.maxLineNumber;
    if (intent.forward) {
      if (currentLine == maxLine) {
        controller.selection =
            TextSelection.collapsed(offset: controller.text.length);
      } else {
        final currentLineText = controller.lineText(currentLine);
        final nextLineText = controller.lineText(currentLine+1);
        final currentOffset = controller.selection.baseOffset;

        controller.selection = controller.selection.extendTo(position);
      }
    } else {
      if (currentLine == 1) {
        controller.selection = const TextSelection.collapsed(offset: 0);
      } else {
        final position = TextPosition(offset: controller.selection.baseOffset);
        controller.selection = controller.selection.extendTo(position);
      }
    }
  }
}

class HorizontalCaretAction extends Action<ExtendSelectionByCharacterIntent> {
  HorizontalCaretAction(this.controller);
  final EditorController controller;

  void _update(int offset) {
    controller.selection = TextSelection.collapsed(offset: offset);
  }

  @override
  void invoke(ExtendSelectionByCharacterIntent intent) {
    final offset = controller.selection.baseOffset;
    if (intent.forward) {
      _update(offset + 1);
    } else {
      _update(offset - 1);
    }
  }
}
