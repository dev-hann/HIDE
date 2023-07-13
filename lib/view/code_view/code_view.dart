import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/code_view/bloc/code_bloc.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_view.dart';

class CodeView extends StatefulWidget {
  const CodeView({Key? key}) : super(key: key);

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  CodeBloc get bloc => BlocProvider.of<CodeBloc>(context);

  @override
  void initState() {
    super.initState();
    bloc.add(CodeInitialized());
  }

  Widget codeView({
    required EditorController controller,
    required VoidCallback onTap,
    required bool readOnly,
    required Function(RawKeyEvent event) onTapKey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: EditorView(
        key: UniqueKey(),
        controller: controller,
        readOnly: readOnly,
      ),
    );
  }

  Widget emptyView() {
    return const Center(child: Text("HIDE"));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CodeBloc, CodeState>(
      buildWhen: (pre, curr) {
        return pre != curr || curr.state == CodeStatus.success;
      },
      builder: (context, state) {
        final controller = bloc.controller;
        if (controller == null) {
          return emptyView();
        }
        return Expanded(
          child: TextField(
            controller: controller,
            expands: true,
            minLines: null,
            maxLines: null,
          ),
        );
        //        Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   mainAxisSize: MainAxisSize.max,
        //   children: [

        //     Expanded(
        //       child: ,

        //       // codeView(
        //       //   onTapKey: (event) {
        //       //     // bloc.add(CodeOnTapKey(
        //       //     //   event,
        //       //     //   controller.file.path,
        //       //     //   controller.selection.baseOffset,
        //       //     // ));
        //       //   },
        //       //   readOnly: state.readOnly,
        //       //   controller: controller,
        //       //   onTap: controller.moveToEnd,
        //       // ),
        //     ),
        //   ],
        // );
      },
    );
  }
}
