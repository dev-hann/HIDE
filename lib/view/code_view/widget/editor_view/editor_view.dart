import 'package:flutter/material.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/number_view/number_view.dart';

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
    return SingleChildScrollView(
      controller: controller.scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberView(controller: controller),
          const SizedBox(width: 8),
          Expanded(
            child: EditableText(
              readOnly: readOnly,
              scrollController: ScrollController(),
              scrollPhysics: const NeverScrollableScrollPhysics(),
              maxLines: null,
              controller: controller,
              style: Theme.of(context).textTheme.bodyText1!,
              cursorColor: const Color(white),
              backgroundCursorColor: Colors.transparent,
              focusNode: controller.focusNode,
            ),
          ),
        ],
      ),
    );
  }
}
