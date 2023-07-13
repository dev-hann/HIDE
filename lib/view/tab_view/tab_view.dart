import 'package:flutter/material.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/widget/tab_button.dart';

class TabView extends StatelessWidget {
  const TabView({
    super.key,
    required this.fileList,
    required this.selectedIndex,
    required this.onTap,
    required this.onTapClose,
  });
  final List<HFile> fileList;
  final int selectedIndex;
  final Function(HFile file) onTap;
  final Function(HFile file) onTapClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: fileList.length,
        itemBuilder: (context, index) {
          final file = fileList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: HTabButton(
                  isSelected: selectedIndex == index,
                  selectedColor: HColor.grey.withOpacity(0.5),
                  unSelectedColor: HColor.black,
                  selectedStyle: const TextStyle(
                    color: HColor.white,
                    fontWeight: FontWeight.w600,
                  ),
                  unSelectedStyle: const TextStyle(color: HColor.white),
                  file: file,
                  onTap: () {
                    onTap(file);
                  },
                  onTapClose: () {
                    onTapClose(file);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
