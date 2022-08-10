import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'dart:math' as math;

class NumberView extends StatelessWidget {
  const NumberView({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final EditorController controller;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final length = value.text.split("\n").length;
        return SizedBox(
          width: math.max(length.toString().length * 10, 30),
          child: Center(
            child: Column(
              children: [
                for (int index = 0; index < length; index++)
                  Text("${index + 1}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
