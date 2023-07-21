import 'package:flutter/material.dart';
import 'package:h_ide/const/color.dart';
import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/widget/h_button.dart';

class HTab extends StatelessWidget {
  const HTab({
    super.key,
    required this.fileList,
    required this.selectedIndex,
    required this.onTap,
    required this.onTapClose,
  });
  final List<HFile> fileList;
  final int selectedIndex;
  final Function(int index) onTap;
  final Function(int index) onTapClose;

  Widget item(int index) {
    final file = fileList[index];
    return Center(
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: HTabButton(
          isModified: file.isModified,
          isSelected: selectedIndex == index,
          selectedColor: HColor.grey.withOpacity(0.5),
          unSelectedColor: HColor.black,
          selectedStyle: const TextStyle(
            color: HColor.white,
            fontWeight: FontWeight.w600,
          ),
          unSelectedStyle: const TextStyle(color: HColor.white),
          name: file.name,
          onTap: () {
            onTap(index);
          },
          onTapClose: () {
            onTapClose(index);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int index = 0; index < fileList.length; index++) item(index),
          ],
        ),
      ),
    );
  }
}

class HTabButton extends HButton {
  const HTabButton({
    Key? key,
    required this.name,
    required this.isSelected,
    required this.isModified,
    required super.onTap,
    required this.onTapClose,
    required this.unSelectedColor,
    required this.selectedColor,
    required this.selectedStyle,
    required this.unSelectedStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    this.height = 36,
    this.width = 200,
  }) : super(key: key);
  final EdgeInsets padding;
  final double width;
  final double height;
  final String name;
  final bool isSelected;
  final bool isModified;
  final Color unSelectedColor;
  final Color selectedColor;
  final TextStyle selectedStyle;
  final TextStyle unSelectedStyle;
  final VoidCallback onTapClose;

  Color get hoverColor => selectedColor.withOpacity(0.05);
  Color buttonColor(bool onHover) {
    if (isSelected) {
      return selectedColor;
    }
    if (onHover) {
      return hoverColor;
    }
    return unSelectedColor;
  }

  Widget hoverGradient(BuildContext context, bool onHover, Offset hoverOffset) {
    if (!onHover || isSelected) {
      return const SizedBox();
    }
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(hoverOffset);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onHover
            ? RadialGradient(
                colors: [
                  hoverColor.withOpacity(0.1),
                  hoverColor,
                ],
                radius: 2,
                center: Alignment(
                  (offset.dx / width) * 2 - 1,
                  (offset.dy / height) * 2 - 1,
                ),
              )
            : null,
      ),
    );
  }

  Widget trailWidget() {
    return Icon(
      isModified ? Icons.circle : Icons.close,
      size: 16,
    );
  }

  @override
  Widget button(BuildContext context, bool onHover, Offset hoverOffset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: buttonColor(onHover),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: (isSelected ? selectedStyle : unSelectedStyle)
                            .apply(overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onTapClose,
                      child: trailWidget(),
                    ),
                  ],
                ),
              ),
            ),
            // hoverGradient(context, onHover, hoverOffset)
          ],
        ),
      ),
    );
  }
}
