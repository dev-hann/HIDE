import 'package:flutter/material.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/view/bottom_view/bottom_view.dart';
import 'package:h_ide/view/code_view/code_view.dart';
import 'package:h_ide/view/finder_view/finder_view.dart';
import 'package:resizable_widget/resizable_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  Widget upperView() {
    return ResizableWidget(
      percentages: const [0.2, 0.8],
      separatorColor: const Color(grey),
      separatorSize: 2,
      children:  [
        FinderView(),
        CodeView(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ResizableWidget(
          percentages: const [0.8, 0.2],
          isHorizontalSeparator: true,
          separatorColor: const Color(grey),
          separatorSize: 2,
          children: [
            upperView(),
            const BottomView(),
          ],
        ),
      ),
    );
  }
}
