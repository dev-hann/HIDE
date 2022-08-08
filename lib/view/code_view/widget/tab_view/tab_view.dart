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
    double? itemWidth,
    double? itemHeight,
  })  : itemWidth = itemWidth ?? 150,
        itemHeight = itemHeight ?? 30,
        super(key: key);
  final int index;
  final List<HFile> fileList;
  final Function(HFile file) onTap;
  final Function(HFile file) onTapClose;
  final double itemHeight;
  final double itemWidth;
  Widget item(int index) {
    final file = fileList[index];
    return TabButton(
      isSelected: index == this.index,
      selectedColor: Colors.grey,
      unSelectedColor: Colors.black,
      label: file.path.split("/").last,
      onTap: () {
        onTap(file);
      },
      onTapClose: () {
        onTapClose(file);
      },
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
          return item(index);
        },
      ),
    );
  }
}
