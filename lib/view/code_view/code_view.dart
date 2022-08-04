import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';

class CodeView extends StatelessWidget {
  const CodeView({Key? key}) : super(key: key);

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
          return QuillEditor(
            textCapitalization: TextCapitalization.none,
            scrollable: true,
            controller: BlocProvider.of<CodeBloc>(context).codeController,
            readOnly: false,
            autoFocus: true,
            expands: true,
            focusNode: FocusNode(),
            padding: EdgeInsets.all(8),
            scrollController: ScrollController(),
          );
        },
      ),
    );
  }
}
