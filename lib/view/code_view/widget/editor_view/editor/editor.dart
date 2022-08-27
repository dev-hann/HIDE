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
                  // print(value);
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

  // TODO : Need Optimize!
  @override
  void invoke(ExtendSelectionVerticallyToAdjacentLineIntent intent) {
    final currentLine = controller.caretLineNumber;
    final currentLineText = controller.lineText(currentLine);
    final maxLine = controller.maxLineNumber;
    if (intent.forward) {
      if (currentLine == maxLine) {
        controller.selection =
            TextSelection.collapsed(offset: controller.text.length);
      } else {
        int textLength = 0;
        for (int index = 0; index < currentLine; index++) {
          textLength += controller.lineText(index).length;
          textLength++;
        }
        final nomalizedOffset = controller.selection.baseOffset - textLength;
        final leftLineOffset = currentLineText.length - nomalizedOffset;
        controller.selection = TextSelection.collapsed(
            offset: controller.selection.baseOffset + leftLineOffset);
        final nextLineCaretOffset = math.min(
            nomalizedOffset + 1, controller.lineText(currentLine + 1).length);
        controller.selection = TextSelection.collapsed(
            offset: controller.selection.baseOffset + nextLineCaretOffset);
      }
    } else {
      if (currentLine == 1) {
        controller.selection = const TextSelection.collapsed(offset: 0);
      } else {
        int textLength = 0;
        for (int index = 0; index < currentLine; index++) {
          textLength += controller.lineText(index).length;
          textLength++;
        }
        final nomalizedOffset = controller.selection.baseOffset - textLength;
        final beforeLineText = controller.lineText(currentLine - 1);
        controller.selection = TextSelection.collapsed(offset: textLength - 1);
        controller.selection = TextSelection.collapsed(
          offset: controller.selection.baseOffset -
              beforeLineText.length -
              1 +
              1 +
              (math.min(beforeLineText.length - 1, nomalizedOffset)),
        );
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
      if (offset != 0) {
        _update(offset - 1);
      }
    }
  }
}
