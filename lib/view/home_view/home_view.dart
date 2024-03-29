import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/view/bottom_view/bottom_view.dart';
import 'package:h_ide/view/finder_view/finder_view.dart';
import 'package:h_ide/view/home_view/bloc/home_bloc.dart';
import 'package:h_ide/view/panel_view/panel_view.dart';
import 'package:resizable_widget/resizable_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  HomeBloc get bloc => BlocProvider.of<HomeBloc>(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CallbackShortcuts(
          bindings: {
            LogicalKeySet(
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.keyB,
            ): () {
              bloc.add(
                const HomeEventUpdateLeftPanelSize(0.0),
              );
            }
          },
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              final bottomSize = state.bottomPanelSize;
              final leftSize = state.leftPanelSize;
              return ResizableWidget(
                percentages: [1 - bottomSize, bottomSize],
                onResized: (infoList) {
                  final size = infoList.last;
                  bloc.add(
                    HomeEventUpdateBottomPanelSize(size.percentage),
                  );
                },
                isHorizontalSeparator: true,
                separatorColor: HColor.grey,
                separatorSize: 2,
                children: [
                  ResizableWidget(
                    percentages: [leftSize, 1 - leftSize],
                    separatorColor: HColor.grey,
                    separatorSize: 2,
                    onResized: (infoList) {
                      final size = infoList.first;
                      bloc.add(
                        HomeEventUpdateLeftPanelSize(size.percentage),
                      );
                    },
                    children: const [
                      FinderView(),
                      PanelView(),
                    ],
                  ),
                  const BottomView(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
