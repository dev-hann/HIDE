import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/code_view/widget/tab_view/tab_button.dart';
import 'package:h_ide/const/color.dart';

class TabView extends StatelessWidget {
  const TabView({
    Key? key,
    required this.index,
    required this.fileList,
    required this.onTap,
    required this.onTapClose,
    double? itemHeight,
  })  : itemHeight = itemHeight ?? kToolbarHeight,
        super(key: key);
  final int index;
  final List<HFile> fileList;
  final Function(HFile file) onTap;
  final Function(HFile file) onTapClose;
  final double itemHeight;

  Widget item(int itemIndex, BuildContext context) {
    final file = fileList[itemIndex];
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: TabButton(
        isSelected: index == itemIndex,
        selectedColor: const Color(grey).withOpacity(0.5),
        unSelectedColor: const Color(black),
        selectedStyle: const TextStyle(
          color: Color(white),
          fontWeight: FontWeight.w600,
        ),
        unSelectedStyle: const TextStyle(color: Color(white)),
        label: file.path.split("/").last,
        onTap: () {
          onTap(file);
        },
        onTapClose: () {
          onTapClose(file);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: fileList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: item(index, context)),
          );
        },
      ),
    );
  }
}
