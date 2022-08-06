import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_view.dart';

class CodeView extends StatelessWidget {
  CodeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      onKey: (event) {
        if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
          print("onPressed Tap");
        }
      },
      focusNode: FocusNode(),
      child: BlocBuilder<CodeBloc, CodeState>(
        buildWhen: (pre, curr) {
          return pre != curr || curr.state == CodeStatus.success;
        },
        builder: (context, state) {
          return EditorView();
        },
      ),
    );
  }
}
