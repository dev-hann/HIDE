import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_view.dart';
import 'package:h_ide/view/code_view/widget/tab_view/tab_view.dart';

class CodeView extends StatelessWidget {
  const CodeView({Key? key}) : super(key: key);

  Widget tabView({
    required EditorController controller,
    required int index,
    required List<HFile> fileList,
    required Function(HFile) onTap,
    required Function(HFile) onTapClose,
  }) {
    return TabView(
      index: index,
      fileList: fileList,
      onTap: onTap,
      onTapClose: onTapClose,
    );
  }

  Widget codeView({
    required EditorController controller,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: EditorView(
        controller: controller,
      ),
    );
  }

  Widget emptyView() {
    return const Text("Controller is empty");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      child: BlocBuilder<CodeBloc, CodeState>(
        buildWhen: (pre, curr) {
          return pre != curr || curr.state == CodeStatus.success;
        },
        builder: (context, state) {
          final bloc = BlocProvider.of<CodeBloc>(context);
          final controller = bloc.controller;
          if (controller == null) {
            return emptyView();
          }
          return Column(
            children: [
              tabView(
                controller: controller,
                index: state.index,
                fileList: bloc.fileList,
                onTap: (file) {
                  bloc.add(CodeFileOpened(file));
                },
                onTapClose: (file) {
                  bloc.add(CodeFileClosed(file));
                },
              ),
              Expanded(
                child: codeView(
                  controller: controller,
                  onTap: controller.moveToEnd,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
