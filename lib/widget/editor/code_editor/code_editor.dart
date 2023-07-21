import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/syntax.dart';
import 'package:h_ide/widget/editor/code_editor/code_editor_controller.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    required this.file,
    required this.onChanged,
    required this.onTapSaved,
    this.showLineNumber = true,
  });
  final HFile file;
  final bool showLineNumber;
  final Function(String value) onChanged;
  final Function(String value) onTapSaved;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final controller = CodeEditorController(
    text: widget.file.data,
    syntax: Syntax.dart(),
  );
  Widget lineNumberWidget() {
    if (!widget.showLineNumber) {
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
            child: CallbackShortcuts(
              bindings: {
                LogicalKeySet(
                  LogicalKeyboardKey.metaLeft,
                  LogicalKeyboardKey.keyS,
                ): () {
                  widget.onTapSaved(controller.text);
                },
              },
              child: TextField(
                onChanged: widget.onChanged,
                controller: controller,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
