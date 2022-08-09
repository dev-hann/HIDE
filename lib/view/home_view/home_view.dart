import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:h_ide/view/bottom_view/bottom_view.dart';
import 'package:h_ide/view/code_view/code_view.dart';
import 'package:h_ide/view/finder_view/finder_view.dart';
import 'package:resizable_widget/resizable_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  Widget upperView() {
    return ResizableWidget(
      percentages: [0.2, 0.8],
      separatorColor: Colors.black,
      children: [
        FinderView(),
        CodeView(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x1f1f1f),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ResizableWidget(
          percentages: [0.8, 0.2],
          isHorizontalSeparator: true,
          separatorColor: Colors.black,
          children: [
            upperView(),
            BottomView(),
          ],
        ),
      ),
    );
  }
}
