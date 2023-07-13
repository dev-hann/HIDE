import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/view/panel_view/bloc/panel_bloc.dart';
import 'package:h_ide/view/tab_view/tab_view.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PanelBloc, PanelState>(
      builder: (context, state) {
        final fileList = state.fileList;
        return Column(
          children: [
            TabView(
              fileList: fileList,
              selectedIndex: state.selectedIndex,
              onTap: (file) {
                bloc.add(
                  PanelEventOpenFile(file),
                );
              },
              onTapClose: (file) {
                bloc.add(
                  PanelEventCloseFile(file),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: state.controller,
                expands: true,
                maxLines: null,
                minLines: null,
              ),
            ),
          ],
        );
      },
    );
  }
}
