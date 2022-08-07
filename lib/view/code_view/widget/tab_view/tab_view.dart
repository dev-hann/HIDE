import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/tab_view/tab_button.dart';

class TabView extends StatelessWidget {
  const TabView({
    Key? key,
    required this.tabList,
    required this.onTap,
    required this.onTapClose,
    double? itemWidth,
    double? itemHeight,
  })  : itemWidth = itemWidth ?? 150,
        itemHeight = itemHeight ?? 30,
        super(key: key);
  final List<String> tabList;
  final Function(int index) onTap;
  final Function(int index) onTapClose;
  final double itemHeight;
  final double itemWidth;
  Widget item(int index) {
    final label = tabList[index];
    return TabButton(
      isSelected: index == 1,
      selectedColor: Colors.grey,
      unSelectedColor: Colors.black,
      label: label,
      onTap: () {
        print("$index");
      },
      onTapClose: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        separatorBuilder: (_, index) {
          return const VerticalDivider(
            width: 1,
          );
        },
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: tabList.length,
        itemBuilder: (context, index) {
          return item(index);
        },
      ),
    );
  }
}
