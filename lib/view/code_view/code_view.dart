import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeView extends StatelessWidget {
  CodeView({Key? key}) : super(key: key);

  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      onKey: (event) {
        if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
          print("onPressed Tap");
        }

      },
      focusNode: FocusNode(),
      child: TextField(
        controller: textEditingController,
        expands: true,
        maxLines: null,
        minLines: null,
      ),
    );
  }
}
