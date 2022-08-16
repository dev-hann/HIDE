import 'dart:math' as math;
import 'package:flutter/material.dart';

class RenderEditorWidget extends SingleChildRenderObjectWidget {
  const RenderEditorWidget({
    Key? key,
    this.text,
  }) : super(key: key);
  final InlineSpan? text;
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEditor(
      text: text,
    );
  }
}

class _RenderEditor extends RenderBox {
  _RenderEditor({
    InlineSpan? text,
  }) : _textPainter = TextPainter(
          text: text,
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
        );

  final TextPainter _textPainter;
  double get lineHeight => _textPainter.preferredLineHeight;
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
    _layoutText();
    return _textPainter.size;
  }

  void _paintText(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset);
  }

  void _paintCursor(PaintingContext context, Offset offset) {}

  void _paintRuler(PaintingContext context, Offset offset) {
    // final paint = Paint()..color = Colors.blue.withOpacity(0.2);
    // context.canvas.drawRect(Rect.fromLTWH(0, 0, size.width, lineHeight), paint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintText(context, offset);
    _paintCursor(context, offset);
    _paintRuler(context, offset);
  }
}
