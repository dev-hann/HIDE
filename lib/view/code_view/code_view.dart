import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_view.dart';
import 'package:h_ide/view/code_view/widget/number_view/number_view.dart';
import 'package:h_ide/view/code_view/widget/tab_view/tab_view.dart';

class CodeView extends StatelessWidget {
  const CodeView({Key? key}) : super(key: key);

  Widget tabView() {
    return BlocBuilder<CodeBloc, CodeState>(
      buildWhen: (pre, curr) {
        return pre != curr || curr.state == CodeStatus.success;
      },
      builder: (context, state) {
        final bloc = BlocProvider.of<CodeBloc>(context);
        return TabView(
          index: state.index,
          fileList: bloc.fileList,
          onTap: (file) {
            bloc.add(CodeFileOpened(file));
          },
          onTapClose: (file) {
            bloc.add(CodeFileClosed(file));
          },
        );
      },
    );
  }

  Widget codeView(EditorController controller) {
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
              const SizedBox(width: 8),
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
  }

  Widget emptyView() {
    return Text("Controller is empty");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey,
      child: BlocBuilder<CodeBloc, CodeState>(
        buildWhen: (pre, curr) {
          return pre != curr || curr.state == CodeStatus.success;
        },
        builder: (context, state) {
          final controller = BlocProvider.of<CodeBloc>(context).controller;
          if (controller == null) {
            return emptyView();
          }
          return Column(
            children: [
              tabView(),
              Expanded(
                child: codeView(controller),
              ),
            ],
          );
        },
      ),
    );
  }
}
