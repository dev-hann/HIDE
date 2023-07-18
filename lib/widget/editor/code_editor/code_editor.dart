import 'package:flutter/material.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/widget/editor/code_editor/code_editor_controller.dart';

class CodeEditor extends StatelessWidget {
  const CodeEditor({
    super.key,
    required this.controller,
    this.showLineNumber = true,
  });
  final CodeEditorController controller;
  final bool showLineNumber;

  Widget lineNumberWidget() {
    if (!showLineNumber) {
      return const SizedBox();
    }
    return SizedBox(
      width: 40.0,
      child: TextField(
        enabled: false,
        maxLines: null,
        minLines: null,
        textAlign: TextAlign.end,
        decoration: const InputDecoration(),
        controller: CodeEditorController(
          text: List.generate(
            controller.lines,
            (index) {
              return "${index + 1}\n";
            },
          ).join(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          lineNumberWidget(),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}
