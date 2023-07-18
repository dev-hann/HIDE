import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/panel_view/bloc/panel_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PanelBloc, PanelState>(
      builder: (context, state) {
        final fileList = state.editorMap.keys.toList();
        final selectedIndex = state.selectedIndex;
        if (fileList.isEmpty) {
          return emptyView();
        }
        return Column(
          children: [
            HTab(
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
            ),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: state.pageController,
                children: state.editorMap.values.toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
