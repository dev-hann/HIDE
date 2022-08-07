import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_view.dart';
import 'package:h_ide/view/code_view/widget/number_view/number_view.dart';
import 'package:h_ide/view/code_view/widget/tab_view/tab_view.dart';

class CodeView extends StatelessWidget {
  const CodeView({Key? key}) : super(key: key);

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
          return Column(
            children: [
              TabView(
                tabList: ["1", "2", "3", "4"],
                onTap: (index) {},
                onTapClose: (index) {},
              ),
              Expanded(
                child: GestureDetector(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
