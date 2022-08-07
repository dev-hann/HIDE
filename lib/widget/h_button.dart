import 'package:flutter/material.dart';
import 'package:h_ide/widget/hover_builder.dart';

abstract class HButton extends StatelessWidget {
  const HButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;

  Widget button(BuildContext context, bool onHover, Offset hoverOffset);

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, onHover, hoverOffset) {
        return GestureDetector(
          onTap: onTap,
          child: button(context, onHover, hoverOffset),
        );
      },
    );
  }
}
