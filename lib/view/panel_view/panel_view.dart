import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/panel_view/bloc/panel_bloc.dart';
import 'package:h_ide/widget/editor/editor.dart';
import 'package:h_ide/widget/tab.dart';

class PanelView extends StatefulWidget {
  const PanelView({super.key});

  @override
  State<PanelView> createState() => _PanelViewState();
}

class _PanelViewState extends State<PanelView> {
  PanelBloc get bloc => BlocProvider.of<PanelBloc>(context);

  @override
  void initState() {
    super.initState();
    bloc.add(PanelEventInited());
  }

  Widget emptyView() {
    return const Center(
      child: Text("HIDE"),
    );
  }

  Widget tabView() {
    return BlocBuilder<PanelBloc, PanelState>(
      builder: (context, state) {
        final fileList = state.fileList;
        final selectedIndex = state.selectedIndex;
        return HTab(
          fileList: fileList,
          selectedIndex: selectedIndex,
          onTap: (index) {
            bloc.add(
              PanelEventOpenFile(fileList[index]),
            );
          },
          onTapClose: (index) {
            bloc.add(
              PanelEventCloseFile(fileList[index]),
            );
          },
        );
      },
    );
  }

  Widget panelView() {
    return BlocBuilder<PanelBloc, PanelState>(
      buildWhen: (previous, current) {
        return previous.selectedFile?.path != current.selectedFile?.path;
      },
      builder: (context, state) {
        final fileList = state.fileList;
        if (fileList.isEmpty) {
          return emptyView();
        }
        return PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: state.pageController,
          children: fileList.map((file) {
            return HEditor(
              file: file,
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tabView(),
        const SizedBox(height: 8.0),
        Expanded(
          child: panelView(),
        ),
      ],
    );
  }
}
