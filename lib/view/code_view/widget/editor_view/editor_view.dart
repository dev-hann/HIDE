import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/number_view/number_view.dart';

class EditorView extends StatelessWidget {
  final EditorController controller;
  const EditorView({
    Key? key,
    required this.controller,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller.scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberView(controller: controller),
          const SizedBox(width: 8),
          Expanded(
            child: EditableText(
              scrollController: ScrollController(),
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
    );
  }
}
