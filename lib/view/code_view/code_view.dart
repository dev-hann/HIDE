import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_view.dart';
import 'package:h_ide/view/code_view/widget/number_view/number_view.dart';

class CodeView extends StatelessWidget {
  CodeView({Key? key}) : super(key: key);

  final EditorController controller =
      EditorController(syntaxMap: <String, TextStyle>{
    "class": TextStyle(color: Colors.blue),
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CodeBloc, CodeState>(
      buildWhen: (pre, curr) {
        return pre != curr || curr.state == CodeStatus.success;
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            controller.moveToEnd();
          },
          child: SingleChildScrollView(
            controller: controller.scrollController,
            child: ColoredBox(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NumberView(
                    controller: controller,
                  ),
                  Expanded(
                    child: EditorView(
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
