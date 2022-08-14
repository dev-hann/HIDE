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
      text: controller.buildTextSpan(context: context, withComposing: true),
    );
  }
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

  void _layoutText({double minWidth = 0.0, double maxWidth = double.infinity}) {
    final double availableMaxWidth = math.max(0.0, maxWidth /*- _caretMargin*/);
    final double availableMinWidth = math.min(minWidth, availableMaxWidth);
    _textPainter.layout(
      minWidth: availableMinWidth,
      maxWidth: availableMaxWidth,
    );
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    print(constraints.biggest);
    _layoutText();
    /// constraints can get size , determin height
    return _textPainter.size;
  }

  @override
  void performLayout() {
    _layoutText();
    // size = _textPainter.size;
  }

  void _paintText(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset);
  }

  void _paintCursor(PaintingContext context, Offset offset) {}
  @override
  void paint(PaintingContext context, Offset offset) {
    print(size);
    _paintText(context, offset);
    _paintCursor(context, offset);
  }
}
