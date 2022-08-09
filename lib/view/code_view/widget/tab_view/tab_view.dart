import 'package:flutter/material.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/view/code_view/widget/tab_view/tab_button.dart';

class TabView extends StatelessWidget {
  const TabView({
    Key? key,
    required this.index,
    required this.fileList,
    required this.onTap,
    required this.onTapClose,
    double? itemHeight,
  })  : itemHeight = itemHeight ?? 60,
        super(key: key);
  final int index;
  final List<HFile> fileList;
  final Function(HFile file) onTap;
  final Function(HFile file) onTapClose;
  final double itemHeight;

  Widget item(int itemIndex) {
    final file = fileList[itemIndex];
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: TabButton(
        isSelected: index == itemIndex,
        selectedColor: Colors.white.withOpacity(0.15),
        unSelectedColor: Color(0x1f1f1f),
        selectedStyle: TextStyle(),
        // unSelectedStyle: TextStyle(color: Color(0xA1A1A1)),
        unSelectedStyle: TextStyle(),
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
      child: ListView.separated(
        separatorBuilder: (_, index) {
          return const VerticalDivider(width: 1);
        },
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: fileList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: item(index)),
          );
        },
      ),
    );
  }
}
