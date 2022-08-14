import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';

class Editor extends SingleChildRenderObjectWidget {
  const Editor({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final EditorController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderEditor(
      text: controller.buildTextSpan(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditor renderObject) {}
}

class RenderEditor extends RenderBox {
  RenderEditor({
    InlineSpan? text,
  }) : _textPainter = TextPainter(
          text: text,
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
        );

  final TextPainter _textPainter;

  void _layoutText() {
    _textPainter.layout();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _layoutText();
    final s = constraints.constrainDimensions(
        constraints.maxWidth, _textPainter.size.height);
    return s;
  }

  // not supported mouse
  // @override
  // bool hitTestSelf(Offset position) {
  //   print(position);
  //   return super.hitTestSelf(position);
  // }

  void _paintText(PaintingContext context, Offset offset) {
    _layoutText();
    _textPainter.paint(context.canvas, offset);
  }

  void _paintCursor(PaintingContext context, Offset offset) {
    final cursorWidth = 1.0;
    final cursorHeight = _textPainter.preferredLineHeight;
    final cursorRect = Rect.fromLTWH(0, 0, cursorWidth, cursorHeight);
    final paint = Paint()..color = Colors.white;
    context.canvas.drawRect(cursorRect, paint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintText(context, offset);
    _paintCursor(context, offset);
  }
}
