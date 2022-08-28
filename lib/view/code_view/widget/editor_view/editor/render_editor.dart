import 'dart:math' as math;
import 'package:flutter/material.dart';

class RenderEditorWidget extends SingleChildRenderObjectWidget {
  const RenderEditorWidget({
    Key? key,
    this.text,
    required this.caretOffset,
    required this.onChangedCaretOffset,
    required this.insertMode,
  }) : super(key: key);
  final InlineSpan? text;
  final int caretOffset;
  final Function(Offset value) onChangedCaretOffset;
  final bool insertMode;
  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderEditor(
      text: text,
      carotOffset: caretOffset,
      onChangedCarotOffset: onChangedCaretOffset,
      insertMode: insertMode,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditor renderObject) {
    renderObject
      ..insertMode = insertMode
      ..carotOffset = caretOffset
      ..text = text;
  }
}

class RenderEditor extends RenderBox {
  RenderEditor({
    InlineSpan? text,
    required int carotOffset,
    required bool insertMode,
    required this.onChangedCarotOffset,
  })  : _insertMode = insertMode,
        _carotOffset = carotOffset,
        _textPainter = TextPainter(
          text: text,
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
        );

  late bool _insertMode;
  bool get insertMode => _insertMode;
  set insertMode(bool value) {
    if (_insertMode == value) {
      return;
    }
    _insertMode = value;
    markNeedsPaint();
  }

  final Function(Offset value) onChangedCarotOffset;

  late int _carotOffset;
  int get carotOffset => _carotOffset;
  set carotOffset(int value) {
    if (_carotOffset == value) {
      return;
    }
    _carotOffset = value;
    markNeedsPaint();
  }

  set text(InlineSpan? text) {
    if (_textPainter.text == text) {
      return;
    }
    _textPainter = TextPainter(
      text: text,
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
    );
    markNeedsPaint();
  }

  late TextPainter _textPainter;
  double get lineHeight => _textPainter.preferredLineHeight + 2;
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

  late Offset caretOffset = Offset.zero;
  void _paintCursor(PaintingContext context, Offset offset) {
    final position = TextPosition(offset: carotOffset);
    // get char width!.
    print(_textPainter.text!.style);
    final double caretWidth = insertMode ? 2 : 8;
    final rect = Rect.fromLTWH(0, 0, caretWidth, lineHeight);
    caretOffset = _textPainter.getOffsetForCaret(position, rect);
    onChangedCarotOffset(caretOffset);
    final paint = Paint()..color = Colors.red;
    final carrotRect = Rect.fromLTWH(
      caretOffset.dx + offset.dx,
      caretOffset.dy + offset.dy + 1,
      rect.width,
      rect.height,
    );
    context.canvas.drawRect(carrotRect, paint);
  }

  void _paintRuler(PaintingContext context, Offset offset) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1);
    // TODO: fix width
    context.canvas.drawRect(
        Rect.fromLTWH(0, caretOffset.dy, size.width * 100, lineHeight), paint);
  }

  void _paintNumber(PaintingContext context, Offset offset) {
    final lineNumber = _textPainter.computeLineMetrics().length;
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: List.generate(lineNumber, (index) => " $index\n ").join(),
        style: _textPainter.text!.style,
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
    );
    tp.layout();
    tp.paint(context.canvas, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintNumber(context, offset);
    Offset editorOffset = offset.translate(50, 0);
    _paintText(context, editorOffset);
    _paintCursor(context, editorOffset);
    _paintRuler(context, offset);
  }
}
