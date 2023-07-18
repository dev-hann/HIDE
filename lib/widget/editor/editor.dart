import 'dart:async';

import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/syntax.dart';
import 'package:h_ide/widget/editor/code_editor/code_editor.dart';
import 'package:h_ide/widget/editor/code_editor/code_editor_controller.dart';
import 'package:h_ide/widget/editor/photo_editor/photo_editor.dart';

final syntaxMap = <String, dynamic>{
  "class": Colors.orange.value,
  "import": Colors.greenAccent.value,
  "extends": Colors.orangeAccent.value,
};

class HEditor extends StatefulWidget {
  const HEditor({
    super.key,
    required this.file,
  });
  final HFile file;

  @override
  State<HEditor> createState() => _HEditorState();
}

class _HEditorState extends State<HEditor> with AutomaticKeepAliveClientMixin {
  late final StreamSubscription subStream;
  @override
  void initState() {
    super.initState();
    subStream = widget.file.stream.listen((event) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final file = widget.file;
    final String extension = file.extension.toLowerCase();
    if (PhotoEditor.enableExtenxionList.contains(extension)) {
      return PhotoEditor(file: file);
    }
    return CodeEditor(
      controller: CodeEditorController(
        text: file.data,
        syntax: Syntax(
          "Dart",
          syntaxMap,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
