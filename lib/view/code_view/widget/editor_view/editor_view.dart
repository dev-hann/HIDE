import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/number_view/number_view.dart';

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumberView(controller: controller),
            const SizedBox(width: 8),
            Expanded(
              child: EditableText(
                scrollPhysics: NeverScrollableScrollPhysics(),
                maxLines: null,
                controller: controller,
                style: TextStyle(),
                cursorColor: Colors.black,
                backgroundCursorColor: Colors.red,
                focusNode: controller.focusNode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
