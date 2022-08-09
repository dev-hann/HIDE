import 'package:flutter/material.dart';
import 'package:h_ide/widget/h_button.dart';

class TabButton extends HButton {
  const TabButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required super.onTap,
    required this.onTapClose,
    required this.unSelectedColor,
    required this.selectedColor,
    required this.selectedStyle,
    required this.unSelectedStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    this.height = 40,
    this.width = 200,
  }) : super(key: key);
  final EdgeInsets padding;
  final double width;
  final double height;
  final String label;
  final bool isSelected;
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
                
                padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: (isSelected ? selectedStyle : unSelectedStyle).apply(overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.close, size: 16),
                  ],
                ),
              ),
            ),
            hoverGradient(context, onHover, hoverOffset)
          ],
        ),
      ),
    );
  }
}
