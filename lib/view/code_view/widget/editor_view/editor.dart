import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui hide TextStyle;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_controller.dart';
import 'package:h_ide/view/code_view/widget/editor_view/editor_render.dart';

const double _kIPadWidth = 1488.0;

class Editor extends EditableText {
  Editor({
    super.key,
    required EditorController controller,
    required super.focusNode,
    required super.style,
    required super.cursorColor,
    required super.backgroundCursorColor,
  }) : super(
          controller: controller,
          maxLines: null,
          scrollController: ScrollController(),
          scrollPhysics: const NeverScrollableScrollPhysics(),
        );

  @override
  EditableTextState createState() {
    return EditorState();
  }
}

const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// The time the cursor is static in opacity before animating to become
// transparent.
const Duration _kCursorBlinkWaitForStart = Duration(milliseconds: 150);

// Number of cursor ticks during which the most recently entered character
// is shown in an obscured text field.
const int _kObscureShowLatestCharCursorTicks = 3;

// The minimum width of an iPad screen. The smallest iPad is currently the
// iPad Mini 6th Gen according to ios-resolution.com.
class EditorState extends EditableTextState {
  Timer? _cursorTimer;
  bool _targetCursorVisibility = false;
  final ValueNotifier<bool> _cursorVisibilityNotifier =
      ValueNotifier<bool>(true);
  final GlobalKey _editableKey = GlobalKey();
  final ClipboardStatusNotifier? _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();

  TextInputConnection? _textInputConnection;
  TextSelectionOverlay? _selectionOverlay;

  ScrollController? _internalScrollController;
  ScrollController get _scrollController =>
      widget.scrollController ??
      (_internalScrollController ??= ScrollController());

  AnimationController? _cursorBlinkOpacityController;

  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  bool _didAutoFocus = false;

  AutofillGroupState? _currentAutofillScope;
  @override
  AutofillScope? get currentAutofillScope => _currentAutofillScope;

  AutofillClient get _effectiveAutofillClient => widget.autofillClient ?? this;

  /// Whether to create an input connection with the platform for text editing
  /// or not.
  ///
  /// Read-only input fields do not need a connection with the platform since
  /// there's no need for text editing capabilities (e.g. virtual keyboard).
  ///
  /// On the web, we always need a connection because we want some browser
  /// functionalities to continue to work on read-only input fields like:
  ///
  /// - Relevant context menu.
  /// - cmd/ctrl+c shortcut to copy.
  /// - cmd/ctrl+a to select all.
  /// - Changing the selection using a physical keyboard.
  bool get _shouldCreateInputConnection => kIsWeb || !widget.readOnly;

  // This value is an eyeball estimation of the time it takes for the iOS cursor
  // to ease in and out.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  AnimationController? _floatingCursorResetController;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  Color get _cursorColor =>
      widget.cursorColor.withOpacity(_cursorBlinkOpacityController!.value);

  @override
  bool get cutEnabled =>
      widget.toolbarOptions.cut && !widget.readOnly && !widget.obscureText;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy && !widget.obscureText;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled =>
      widget.toolbarOptions.selectAll &&
      (!widget.readOnly || !widget.obscureText) &&
      widget.enableInteractiveSelection;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  TextEditingValue get _textEditingValueforTextLayoutMetrics {
    final Widget? editableWidget = _editableKey.currentContext?.widget;
    if (editableWidget is! EditorRenderWidget) {
      throw StateError('_Editable must be mounted.');
    }
    return editableWidget.value;
  }

  /// Copy current selection to [Clipboard].
  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection selection = textEditingValue.selection;
    assert(selection != null);
    if (selection.isCollapsed || widget.obscureText) {
      return;
    }
    final String text = textEditingValue.text;
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar(false);

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Collapse the selection and hide the toolbar and handles.
          userUpdateTextEditingValue(
            TextEditingValue(
              text: textEditingValue.text,
              selection: TextSelection.collapsed(
                  offset: textEditingValue.selection.end),
            ),
            SelectionChangedCause.toolbar,
          );
          break;
      }
    }
    _clipboardStatus?.update();
  }

  /// Cut current selection to [Clipboard].
  @override
  void cutSelection(SelectionChangedCause cause) {
    if (widget.readOnly || widget.obscureText) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    assert(selection != null);
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    _replaceText(ReplaceTextIntent(textEditingValue, '', selection, cause));
    if (cause == SelectionChangedCause.toolbar) {
      // Schedule a call to bringIntoView() after renderEditable updates.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bringIntoView(textEditingValue.selection.extent);
        }
      });
      hideToolbar();
    }
    _clipboardStatus?.update();
  }

  /// Paste text from [Clipboard].
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (widget.readOnly) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    assert(selection != null);
    if (!selection.isValid) {
      return;
    }
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return;
    }

    // After the paste, the cursor should be collapsed and located after the
    // pasted content.
    final int lastSelectionIndex =
        math.max(selection.baseOffset, selection.extentOffset);
    final TextEditingValue collapsedTextEditingValue =
        textEditingValue.copyWith(
      selection: TextSelection.collapsed(offset: lastSelectionIndex),
    );

    userUpdateTextEditingValue(
      collapsedTextEditingValue.replaced(selection, data.text!),
      cause,
    );
    if (cause == SelectionChangedCause.toolbar) {
      // Schedule a call to bringIntoView() after renderEditable updates.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bringIntoView(textEditingValue.selection.extent);
        }
      });
      hideToolbar();
    }
  }

  /// Select the entire text value.
  @override
  void selectAll(SelectionChangedCause cause) {
    if (widget.readOnly && widget.obscureText) {
      // If we can't modify it, and we can't copy it, there's no point in
      // selecting it.
      return;
    }
    userUpdateTextEditingValue(
      textEditingValue.copyWith(
        selection: TextSelection(
            baseOffset: 0, extentOffset: textEditingValue.text.length),
      ),
      cause,
    );
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
    }
  }

  // State lifecycle:

  @override
  void initState() {
    super.initState();
    _cursorBlinkOpacityController = AnimationController(
      vsync: this,
      duration: _fadeDuration,
    )..addListener(_onCursorColorTick);
    _clipboardStatus?.addListener(_onChangedClipboardStatus);
    widget.controller.addListener(_didChangeTextEditingValue);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController.addListener(_updateSelectionOverlayForScroll);
    _cursorVisibilityNotifier.value = widget.showCursor;
  }

  // Whether `TickerMode.of(context)` is true and animations (like blinking the
  // cursor) are supposed to run.
  bool _tickersEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final AutofillGroupState? newAutofillGroup = AutofillGroup.of(context);
    if (currentAutofillScope != newAutofillGroup) {
      _currentAutofillScope?.unregister(autofillId);
      _currentAutofillScope = newAutofillGroup;
      _currentAutofillScope?.register(_effectiveAutofillClient);
    }

    if (!_didAutoFocus && widget.autofocus) {
      _didAutoFocus = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && renderEditable.hasSize) {
          FocusScope.of(context).autofocus(widget.focusNode);
        }
      });
    }

    // Restart or stop the blinking cursor when TickerMode changes.
    final bool newTickerEnabled = TickerMode.of(context);
    if (_tickersEnabled != newTickerEnabled) {
      _tickersEnabled = newTickerEnabled;
      if (_tickersEnabled && _cursorActive) {
        _startCursorTimer();
      } else if (!_tickersEnabled && _cursorTimer != null) {
        // Cannot use _stopCursorTimer because it would reset _cursorActive.
        _cursorTimer!.cancel();
        _cursorTimer = null;
      }
    }
  }

  @override
  void didUpdateWidget(EditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      _updateRemoteEditingValueIfNeeded();
    }
    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(_value);
    }
    _selectionOverlay?.handlesVisible = widget.showSelectionHandles;

    if (widget.autofillClient != oldWidget.autofillClient) {
      _currentAutofillScope
          ?.unregister(oldWidget.autofillClient?.autofillId ?? autofillId);
      _currentAutofillScope?.register(_effectiveAutofillClient);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.scrollController != oldWidget.scrollController) {
      (oldWidget.scrollController ?? _internalScrollController)
          ?.removeListener(_updateSelectionOverlayForScroll);
      _scrollController.addListener(_updateSelectionOverlayForScroll);
    }

    if (!_shouldCreateInputConnection) {
      _closeInputConnectionIfNeeded();
    } else if (oldWidget.readOnly && _hasFocus) {
      _openInputConnection();
    }

    if (kIsWeb && _hasInputConnection) {
      if (oldWidget.readOnly != widget.readOnly) {
        _textInputConnection!
            .updateConfig(_effectiveAutofillClient.textInputConfiguration);
      }
    }

    if (widget.style != oldWidget.style) {
      final TextStyle style = widget.style;
      // The _textInputConnection will pick up the new style when it attaches in
      // _openInputConnection.
      if (_hasInputConnection) {
        _textInputConnection!.setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        );
      }
    }
    if (widget.selectionEnabled &&
        pasteEnabled &&
        (widget.selectionControls?.canPaste(this) ?? false)) {
      _clipboardStatus?.update();
    }
  }

  @override
  void dispose() {
    _internalScrollController?.dispose();
    _currentAutofillScope?.unregister(autofillId);
    widget.controller.removeListener(_didChangeTextEditingValue);
    _floatingCursorResetController?.dispose();
    _floatingCursorResetController = null;
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _cursorBlinkOpacityController?.dispose();
    _cursorBlinkOpacityController = null;
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.focusNode.removeListener(_handleFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    super.dispose();
    assert(_batchEditDepth <= 0, 'unfinished batch edits: $_batchEditDepth');
  }

  // TextInputClient implementation:

  /// The last known [TextEditingValue] of the platform text input plugin.
  ///
  /// This value is updated when the platform text input plugin sends a new
  /// update via [updateEditingValue], or when [EditableText] calls
  /// [TextInputConnection.setEditingState] to overwrite the platform text input
  /// plugin's [TextEditingValue].
  ///
  /// Used in [_updateRemoteEditingValueIfNeeded] to determine whether the
  /// remote value is outdated and needs updating.
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    // This method handles text editing state updates from the platform text
    // input plugin. The [EditableText] may not have the focus or an open input
    // connection, as autofill can update a disconnected [EditableText].

    // Since we still have to support keyboard select, this is the best place
    // to disable text updating.
    if (!_shouldCreateInputConnection) {
      return;
    }

    if (widget.readOnly) {
      // In the read-only case, we only care about selection changes, and reject
      // everything else.
      value = _value.copyWith(selection: value.selection);
    }
    _lastKnownRemoteTextEditingValue = value;

    if (value == _value) {
      // This is possible, for example, when the numeric keyboard is input,
      // the engine will notify twice for the same value.
      // Track at https://github.com/flutter/flutter/issues/65811
      return;
    }

    if (value.text == _value.text && value.composing == _value.composing) {
      // `selection` is the only change.
      _handleSelectionChanged(
          value.selection,
          (_textInputConnection?.scribbleInProgress ?? false)
              ? SelectionChangedCause.scribble
              : SelectionChangedCause.keyboard);
    } else {
      hideToolbar();
      _currentPromptRectRange = null;

      final bool revealObscuredInput = _hasInputConnection &&
          widget.obscureText &&
          WidgetsBinding.instance.platformDispatcher.brieflyShowPassword &&
          value.text.length == _value.text.length + 1;

      _obscureShowCharTicksPending =
          revealObscuredInput ? _kObscureShowLatestCharCursorTicks : 0;
      _obscureLatestCharIndex =
          revealObscuredInput ? _value.selection.baseOffset : null;
      _formatAndSetValue(value, SelectionChangedCause.keyboard);
    }

    // Wherever the value is changed by the user, schedule a showCaretOnScreen
    // to make sure the user can see the changes they just made. Programmatical
    // changes to `textEditingValue` do not trigger the behavior even if the
    // text field is focused.
    _scheduleShowCaretOnScreen(withAnimation: true);
    if (_hasInputConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _stopCursorTimer(resetCharTicks: false);
      _startCursorTimer();
    }
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        // If this is a multiline EditableText, do nothing for a "newline"
        // action; The newline is already inserted. Otherwise, finalize
        // editing.
        if (!_isMultiline) _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.next:
      case TextInputAction.previous:
      case TextInputAction.search:
      case TextInputAction.send:
        _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.continueAction:
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
        // Finalize editing, but don't give up focus because this keyboard
        // action does not imply the user is done inputting information.
        _finalizeEditing(action, shouldUnfocus: false);
        break;
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    widget.onAppPrivateCommand!(action, data);
  }

  // The original position of the caret on FloatingCursorDragState.start.
  Rect? _startCaretRect;

  // The most recent text position as determined by the location of the floating
  // cursor.
  TextPosition? _lastTextPosition;

  // The offset of the floating cursor as determined from the start call.
  Offset? _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset? _lastBoundedOffset;

  // Because the center of the cursor is preferredLineHeight / 2 below the touch
  // origin, but the touch origin is used to determine which line the cursor is
  // on, we need this offset to correctly render and move the cursor.
  Offset get _floatingCursorOffset =>
      Offset(0, renderEditable.preferredLineHeight / 2);

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    _floatingCursorResetController ??= AnimationController(
      vsync: this,
    )..addListener(_onFloatingCursorResetTick);
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (_floatingCursorResetController!.isAnimating) {
          _floatingCursorResetController!.stop();
          _onFloatingCursorResetTick();
        }
        // We want to send in points that are centered around a (0,0) origin, so
        // we cache the position.
        _pointOffsetOrigin = point.offset;

        final TextPosition currentTextPosition =
            TextPosition(offset: renderEditable.selection!.baseOffset);
        _startCaretRect =
            renderEditable.getLocalRectForCaret(currentTextPosition);

        _lastBoundedOffset = _startCaretRect!.center - _floatingCursorOffset;
        _lastTextPosition = currentTextPosition;
        renderEditable.setFloatingCursor(
            point.state, _lastBoundedOffset!, _lastTextPosition!);
        break;
      case FloatingCursorDragState.Update:
        final Offset centeredPoint = point.offset! - _pointOffsetOrigin!;
        final Offset rawCursorOffset =
            _startCaretRect!.center + centeredPoint - _floatingCursorOffset;

        _lastBoundedOffset = renderEditable
            .calculateBoundedFloatingCursorOffset(rawCursorOffset);
        _lastTextPosition = renderEditable.getPositionForPoint(renderEditable
            .localToGlobal(_lastBoundedOffset! + _floatingCursorOffset));
        renderEditable.setFloatingCursor(
            point.state, _lastBoundedOffset!, _lastTextPosition!);
        break;
      case FloatingCursorDragState.End:
        // We skip animation if no update has happened.
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          _floatingCursorResetController!.value = 0.0;
          _floatingCursorResetController!.animateTo(1.0,
              duration: _floatingCursorResetTime, curve: Curves.decelerate);
        }
        break;
    }
  }

  void _onFloatingCursorResetTick() {
    final Offset finalPosition =
        renderEditable.getLocalRectForCaret(_lastTextPosition!).centerLeft -
            _floatingCursorOffset;
    if (_floatingCursorResetController!.isCompleted) {
      renderEditable.setFloatingCursor(
          FloatingCursorDragState.End, finalPosition, _lastTextPosition!);
      if (_lastTextPosition!.offset != renderEditable.selection!.baseOffset)
        // The cause is technically the force cursor, but the cause is listed as tap as the desired functionality is the same.
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _lastTextPosition!.offset),
            SelectionChangedCause.forcePress);
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final double lerpValue = _floatingCursorResetController!.value;
      final double lerpX =
          ui.lerpDouble(_lastBoundedOffset!.dx, finalPosition.dx, lerpValue)!;
      final double lerpY =
          ui.lerpDouble(_lastBoundedOffset!.dy, finalPosition.dy, lerpValue)!;

      renderEditable.setFloatingCursor(FloatingCursorDragState.Update,
          Offset(lerpX, lerpY), _lastTextPosition!,
          resetLerpValue: lerpValue);
    }
  }

  @pragma('vm:notify-debugger-on-exception')
  void _finalizeEditing(TextInputAction action, {required bool shouldUnfocus}) {
    // Take any actions necessary now that the user has completed editing.
    if (widget.onEditingComplete != null) {
      try {
        widget.onEditingComplete!();
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context:
              ErrorDescription('while calling onEditingComplete for $action'),
        ));
      }
    } else {
      // Default behavior if the developer did not provide an
      // onEditingComplete callback: Finalize editing and remove focus, or move
      // it to the next/previous field, depending on the action.
      widget.controller.clearComposing();
      if (shouldUnfocus) {
        switch (action) {
          case TextInputAction.none:
          case TextInputAction.unspecified:
          case TextInputAction.done:
          case TextInputAction.go:
          case TextInputAction.search:
          case TextInputAction.send:
          case TextInputAction.continueAction:
          case TextInputAction.join:
          case TextInputAction.route:
          case TextInputAction.emergencyCall:
          case TextInputAction.newline:
            widget.focusNode.unfocus();
            break;
          case TextInputAction.next:
            widget.focusNode.nextFocus();
            break;
          case TextInputAction.previous:
            widget.focusNode.previousFocus();
            break;
        }
      }
    }

    final ValueChanged<String>? onSubmitted = widget.onSubmitted;
    if (onSubmitted == null) {
      return;
    }

    // Invoke optional callback with the user's submitted content.
    try {
      onSubmitted(_value.text);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context: ErrorDescription('while calling onSubmitted for $action'),
      ));
    }

    // If `shouldUnfocus` is true, the text field should no longer be focused
    // after the microtask queue is drained. But in case the developer cancelled
    // the focus change in the `onSubmitted` callback by focusing this input
    // field again, reset the soft keyboard.
    // See https://github.com/flutter/flutter/issues/84240.
    //
    // `_restartConnectionIfNeeded` creates a new TextInputConnection to replace
    // the current one. This on iOS switches to a new input view and on Android
    // restarts the input method, and in both cases the soft keyboard will be
    // reset.
    if (shouldUnfocus) {
      _scheduleRestartConnection();
    }
  }

  int _batchEditDepth = 0;

  /// Begins a new batch edit, within which new updates made to the text editing
  /// value will not be sent to the platform text input plugin.
  ///
  /// Batch edits nest. When the outermost batch edit finishes, [endBatchEdit]
  /// will attempt to send [currentTextEditingValue] to the text input plugin if
  /// it detected a change.
  void beginBatchEdit() {
    _batchEditDepth += 1;
  }

  /// Ends the current batch edit started by the last call to [beginBatchEdit],
  /// and send [currentTextEditingValue] to the text input plugin if needed.
  ///
  /// Throws an error in debug mode if this [EditableText] is not in a batch
  /// edit.
  void endBatchEdit() {
    _batchEditDepth -= 1;
    assert(
      _batchEditDepth >= 0,
      'Unbalanced call to endBatchEdit: beginBatchEdit must be called first.',
    );
    _updateRemoteEditingValueIfNeeded();
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (_batchEditDepth > 0 || !_hasInputConnection) return;
    final TextEditingValue localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue) return;
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  bool get _hasFocus => widget.focusNode.hasFocus;
  bool get _isMultiline => widget.maxLines != 1;

  // Finds the closest scroll offset to the current scroll offset that fully
  // reveals the given caret rect. If the given rect's main axis extent is too
  // large to be fully revealed in `renderEditable`, it will be centered along
  // the main axis.
  //
  // If this is a multiline EditableText (which means the Editable can only
  // scroll vertically), the given rect's height will first be extended to match
  // `renderEditable.preferredLineHeight`, before the target scroll offset is
  // calculated.
  RevealedOffset _getOffsetToRevealCaret(Rect rect) {
    if (!_scrollController.position.allowImplicitScrolling)
      return RevealedOffset(offset: _scrollController.offset, rect: rect);

    final Size editableSize = renderEditable.size;
    final double additionalOffset;
    final Offset unitOffset;

    if (!_isMultiline) {
      additionalOffset = rect.width >= editableSize.width
          // Center `rect` if it's oversized.
          ? editableSize.width / 2 - rect.center.dx
          // Valid additional offsets range from (rect.right - size.width)
          // to (rect.left). Pick the closest one if out of range.
          : 0.0.clamp(rect.right - editableSize.width, rect.left);
      unitOffset = const Offset(1, 0);
    } else {
      // The caret is vertically centered within the line. Expand the caret's
      // height so that it spans the line because we're going to ensure that the
      // entire expanded caret is scrolled into view.
      final Rect expandedRect = Rect.fromCenter(
        center: rect.center,
        width: rect.width,
        height: math.max(rect.height, renderEditable.preferredLineHeight),
      );

      additionalOffset = expandedRect.height >= editableSize.height
          ? editableSize.height / 2 - expandedRect.center.dy
          : 0.0.clamp(
              expandedRect.bottom - editableSize.height, expandedRect.top);
      unitOffset = const Offset(0, 1);
    }

    // No overscrolling when encountering tall fonts/scripts that extend past
    // the ascent.
    final double targetOffset =
        (additionalOffset + _scrollController.offset).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    final double offsetDelta = _scrollController.offset - targetOffset;
    return RevealedOffset(
        rect: rect.shift(unitOffset * offsetDelta), offset: targetOffset);
  }

  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  /// Whether to send the autofill information to the autofill service. True by
  /// default.
  bool get _needsAutofill => _effectiveAutofillClient
      .textInputConfiguration.autofillConfiguration.enabled;

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) {
      return;
    }
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      // When _needsAutofill == true && currentAutofillScope == null, autofill
      // is allowed but saving the user input from the text field is
      // discouraged.
      //
      // In case the autofillScope changes from a non-null value to null, or
      // _needsAutofill changes to false from true, the platform needs to be
      // notified to exclude this field from the autofill context. So we need to
      // provide the autofillId.
      _textInputConnection = _needsAutofill && currentAutofillScope != null
          ? currentAutofillScope!
              .attach(this, _effectiveAutofillClient.textInputConfiguration)
          : TextInput.attach(
              this, _effectiveAutofillClient.textInputConfiguration);
      _updateSizeAndTransform();
      _updateComposingRectIfNeeded();
      _updateCaretRectIfNeeded();
      final TextStyle style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        )
        ..setEditingState(localValue)
        ..show();
      if (_needsAutofill) {
        // Request autofill AFTER the size and the transform have been sent to
        // the platform text input plugin.
        _textInputConnection!.requestAutofill();
      }
      _lastKnownRemoteTextEditingValue = localValue;
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  bool _restartConnectionScheduled = false;
  void _scheduleRestartConnection() {
    if (_restartConnectionScheduled) {
      return;
    }
    _restartConnectionScheduled = true;
    scheduleMicrotask(_restartConnectionIfNeeded);
  }

  // Discards the current [TextInputConnection] and establishes a new one.
  //
  // This method is rarely needed. This is currently used to reset the input
  // type when the "submit" text input action is triggered and the developer
  // puts the focus back to this input field..
  void _restartConnectionIfNeeded() {
    _restartConnectionScheduled = false;
    if (!_hasInputConnection || !_shouldCreateInputConnection) {
      return;
    }
    _textInputConnection!.close();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;

    final AutofillScope? currentAutofillScope =
        _needsAutofill ? this.currentAutofillScope : null;
    final TextInputConnection newConnection = currentAutofillScope?.attach(
            this, textInputConfiguration) ??
        TextInput.attach(this, _effectiveAutofillClient.textInputConfiguration);
    _textInputConnection = newConnection;

    final TextStyle style = widget.style;
    newConnection
      ..show()
      ..setStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        textDirection: _textDirection,
        textAlign: widget.textAlign,
      )
      ..setEditingState(_value);
    _lastKnownRemoteTextEditingValue = _value;
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _finalizeEditing(TextInputAction.done, shouldUnfocus: true);
    }
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode
          .requestFocus(); // This eventually calls _openInputConnection also, see _handleFocusChanged.
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(_value);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    }
  }

  void _updateSelectionOverlayForScroll() {
    _selectionOverlay?.updateForScroll();
  }

  @pragma('vm:notify-debugger-on-exception')
  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    // We return early if the selection is not valid. This can happen when the
    // text of [EditableText] is updated at the same time as the selection is
    // changed by a gesture event.
    if (!widget.controller.isSelectionWithinTextBounds(selection)) return;

    widget.controller.selection = selection;

    // This will show the keyboard for all selection changes on the
    // EditableText except for those triggered by a keyboard input.
    // Typically EditableText shouldn't take user keyboard input if
    // it's not focused already. If the EditableText is being
    // autofilled it shouldn't request focus.
    switch (cause) {
      case null:
      case SelectionChangedCause.doubleTap:
      case SelectionChangedCause.drag:
      case SelectionChangedCause.forcePress:
      case SelectionChangedCause.longPress:
      case SelectionChangedCause.scribble:
      case SelectionChangedCause.tap:
      case SelectionChangedCause.toolbar:
        requestKeyboard();
        break;
      case SelectionChangedCause.keyboard:
        if (_hasFocus) {
          requestKeyboard();
        }
        break;
    }
    if (widget.selectionControls == null) {
      _selectionOverlay?.dispose();
      _selectionOverlay = null;
    } else {
      if (_selectionOverlay == null) {
        _selectionOverlay = TextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: _value,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditable,
          selectionControls: widget.selectionControls,
          selectionDelegate: this,
          dragStartBehavior: widget.dragStartBehavior,
          onSelectionHandleTapped: widget.onSelectionHandleTapped,
        );
      } else {
        _selectionOverlay!.update(_value);
      }
      _selectionOverlay!.handlesVisible = widget.showSelectionHandles;
      _selectionOverlay!.showHandles();
    }
    // TODO(chunhtai): we should make sure selection actually changed before
    // we call the onSelectionChanged.
    // https://github.com/flutter/flutter/issues/76349.
    try {
      widget.onSelectionChanged?.call(selection, cause);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context:
            ErrorDescription('while calling onSelectionChanged for $cause'),
      ));
    }

    // To keep the cursor from blinking while it moves, restart the timer here.
    if (_cursorTimer != null) {
      _stopCursorTimer(resetCharTicks: false);
      _startCursorTimer();
    }
  }

  Rect? _currentCaretRect;
  // ignore: use_setters_to_change_properties, (this is used as a callback, can't be a setter)
  void _handleCaretChanged(Rect caretRect) {
    _currentCaretRect = caretRect;
  }

  // Animation configuration for scrolling the caret back on screen.
  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  void _scheduleShowCaretOnScreen({required bool withAnimation}) {
    if (_showCaretOnScreenScheduled) {
      return;
    }
    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _showCaretOnScreenScheduled = false;
      if (_currentCaretRect == null || !_scrollController.hasClients) {
        return;
      }

      final double lineHeight = renderEditable.preferredLineHeight;

      // Enlarge the target rect by scrollPadding to ensure that caret is not
      // positioned directly at the edge after scrolling.
      double bottomSpacing = widget.scrollPadding.bottom;
      if (_selectionOverlay?.selectionControls != null) {
        final double handleHeight = _selectionOverlay!.selectionControls!
            .getHandleSize(lineHeight)
            .height;
        final double interactiveHandleHeight = math.max(
          handleHeight,
          kMinInteractiveDimension,
        );
        final Offset anchor =
            _selectionOverlay!.selectionControls!.getHandleAnchor(
          TextSelectionHandleType.collapsed,
          lineHeight,
        );
        final double handleCenter = handleHeight / 2 - anchor.dy;
        bottomSpacing = math.max(
          handleCenter + interactiveHandleHeight / 2,
          bottomSpacing,
        );
      }

      final EdgeInsets caretPadding =
          widget.scrollPadding.copyWith(bottom: bottomSpacing);

      final RevealedOffset targetOffset =
          _getOffsetToRevealCaret(_currentCaretRect!);

      if (withAnimation) {
        _scrollController.animateTo(
          targetOffset.offset,
          duration: _caretAnimationDuration,
          curve: _caretAnimationCurve,
        );
        renderEditable.showOnScreen(
          rect: caretPadding.inflateRect(targetOffset.rect),
          duration: _caretAnimationDuration,
          curve: _caretAnimationCurve,
        );
      } else {
        _scrollController.jumpTo(targetOffset.offset);
        renderEditable.showOnScreen(
          rect: caretPadding.inflateRect(targetOffset.rect),
        );
      }
    });
  }

  late double _lastBottomViewInset;

  @override
  void didChangeMetrics() {
    if (_lastBottomViewInset !=
        WidgetsBinding.instance.window.viewInsets.bottom) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _selectionOverlay?.updateForScroll();
      });
      if (_lastBottomViewInset <
          WidgetsBinding.instance.window.viewInsets.bottom) {
        // Because the metrics change signal from engine will come here every frame
        // (on both iOS and Android). So we don't need to show caret with animation.
        _scheduleShowCaretOnScreen(withAnimation: false);
      }
    }
    _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
  }

  @pragma('vm:notify-debugger-on-exception')
  void _formatAndSetValue(TextEditingValue value, SelectionChangedCause? cause,
      {bool userInteraction = false}) {
    // Only apply input formatters if the text has changed (including uncommitted
    // text in the composing region), or when the user committed the composing
    // text.
    // Gboard is very persistent in restoring the composing region. Applying
    // input formatters on composing-region-only changes (except clearing the
    // current composing region) is very infinite-loop-prone: the formatters
    // will keep trying to modify the composing region while Gboard will keep
    // trying to restore the original composing region.
    final bool textChanged = _value.text != value.text ||
        (!_value.composing.isCollapsed && value.composing.isCollapsed);
    final bool selectionChanged = _value.selection != value.selection;

    if (textChanged) {
      try {
        value = widget.inputFormatters?.fold<TextEditingValue>(
              value,
              (TextEditingValue newValue, TextInputFormatter formatter) =>
                  formatter.formatEditUpdate(_value, newValue),
            ) ??
            value;
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context: ErrorDescription('while applying input formatters'),
        ));
      }
    }

    // Put all optional user callback invocations in a batch edit to prevent
    // sending multiple `TextInput.updateEditingValue` messages.
    beginBatchEdit();
    _value = value;
    // Changes made by the keyboard can sometimes be "out of band" for listening
    // components, so always send those events, even if we didn't think it
    // changed. Also, the user long pressing should always send a selection change
    // as well.
    if (selectionChanged ||
        (userInteraction &&
            (cause == SelectionChangedCause.longPress ||
                cause == SelectionChangedCause.keyboard))) {
      _handleSelectionChanged(_value.selection, cause);
    }
    if (textChanged) {
      try {
        widget.onChanged?.call(_value.text);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context: ErrorDescription('while calling onChanged'),
        ));
      }
    }

    endBatchEdit();
  }

  void _onCursorColorTick() {
    renderEditable.cursorColor =
        widget.cursorColor.withOpacity(_cursorBlinkOpacityController!.value);
    _cursorVisibilityNotifier.value =
        widget.showCursor && _cursorBlinkOpacityController!.value > 0;
  }

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  @visibleForTesting
  bool get cursorCurrentlyVisible => _cursorBlinkOpacityController!.value > 0;

  /// The cursor blink interval (the amount of time the cursor is in the "on"
  /// state or the "off" state). A complete cursor blink period is twice this
  /// value (half on, half off).
  @visibleForTesting
  Duration get cursorBlinkInterval => _kCursorBlinkHalfPeriod;

  /// The current status of the text selection handles.
  @visibleForTesting
  TextSelectionOverlay? get selectionOverlay => _selectionOverlay;

  int _obscureShowCharTicksPending = 0;
  int? _obscureLatestCharIndex;

  void _cursorTick(Timer timer) {
    _targetCursorVisibility = !_targetCursorVisibility;
    final double targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (widget.cursorOpacityAnimates) {
      // If we want to show the cursor, we will animate the opacity to the value
      // of 1.0, and likewise if we want to make it disappear, to 0.0. An easing
      // curve is used for the animation to mimic the aesthetics of the native
      // iOS cursor.
      //
      // These values and curves have been obtained through eyeballing, so are
      // likely not exactly the same as the values for native iOS.
      _cursorBlinkOpacityController!
          .animateTo(targetOpacity, curve: Curves.easeOut);
    } else {
      _cursorBlinkOpacityController!.value = targetOpacity;
    }

    if (_obscureShowCharTicksPending > 0) {
      setState(() {
        _obscureShowCharTicksPending =
            WidgetsBinding.instance.platformDispatcher.brieflyShowPassword
                ? _obscureShowCharTicksPending - 1
                : 0;
      });
    }
  }

  void _cursorWaitForStart(Timer timer) {
    assert(_kCursorBlinkHalfPeriod > _fadeDuration);
    assert(!EditableText.debugDeterministicCursor);
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  // Indicates whether the cursor should be blinking right now (but it may
  // actually not blink because it's disabled via TickerMode.of(context)).
  bool _cursorActive = false;

  void _startCursorTimer() {
    assert(_cursorTimer == null);
    _cursorActive = true;
    if (!_tickersEnabled) {
      return;
    }
    _targetCursorVisibility = true;
    _cursorBlinkOpacityController!.value = 1.0;
    if (EditableText.debugDeterministicCursor) return;
    if (widget.cursorOpacityAnimates) {
      _cursorTimer =
          Timer.periodic(_kCursorBlinkWaitForStart, _cursorWaitForStart);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
    }
  }

  void _stopCursorTimer({bool resetCharTicks = true}) {
    _cursorActive = false;
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _cursorBlinkOpacityController!.value = 0.0;
    if (EditableText.debugDeterministicCursor) return;
    if (resetCharTicks) _obscureShowCharTicksPending = 0;
    if (widget.cursorOpacityAnimates) {
      _cursorBlinkOpacityController!.stop();
      _cursorBlinkOpacityController!.value = 0.0;
    }
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (_cursorTimer == null && _hasFocus && _value.selection.isCollapsed)
      _startCursorTimer();
    else if (_cursorActive && (!_hasFocus || !_value.selection.isCollapsed))
      _stopCursorTimer();
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    // TODO(abarth): Teach RenderEditable about ValueNotifier<TextEditingValue>
    // to avoid this setState().
    setState(() {/* We use widget.controller.value in build(). */});
    _adjacentLineAction.stopCurrentVerticalRunIfSelectionChanges();
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      // Listen for changing viewInsets, which indicates keyboard showing up.
      WidgetsBinding.instance.addObserver(this);
      _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
      if (!widget.readOnly) {
        _scheduleShowCaretOnScreen(withAnimation: true);
      }
      if (!_value.selection.isValid) {
        // Place cursor at the end if the selection is invalid when we receive focus.
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _value.text.length), null);
      }

      _cachedText = '';
      _cachedFirstRect = null;
      _cachedSize = Size.zero;
      _cachedPlaceholder = -1;
    } else {
      WidgetsBinding.instance.removeObserver(this);
      setState(() {
        _currentPromptRectRange = null;
      });
    }
    updateKeepAlive();
  }

  String _cachedText = '';
  Rect? _cachedFirstRect;
  Size _cachedSize = Size.zero;
  int _cachedPlaceholder = -1;
  TextStyle? _cachedTextStyle;

  void _updateSelectionRects({bool force = false}) {
    if (!widget.scribbleEnabled) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    // This is to avoid sending selection rects on non-iPad devices.
    if (WidgetsBinding.instance.window.physicalSize.shortestSide < _kIPadWidth)
      return;

    final String text =
        renderEditable.text?.toPlainText(includeSemanticsLabels: false) ?? '';
    final List<Rect> firstSelectionBoxes = renderEditable.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1));
    final Rect? firstRect =
        firstSelectionBoxes.isNotEmpty ? firstSelectionBoxes.first : null;
    final ScrollDirection scrollDirection =
        _scrollController.position.userScrollDirection;
    final Size size = renderEditable.size;
    final bool textChanged = text != _cachedText;
    final bool textStyleChanged = _cachedTextStyle != widget.style;
    final bool firstRectChanged = _cachedFirstRect != firstRect;
    final bool sizeChanged = _cachedSize != size;
    final bool placeholderChanged = _cachedPlaceholder != _placeholderLocation;
    if (scrollDirection == ScrollDirection.idle &&
        (force ||
            textChanged ||
            textStyleChanged ||
            firstRectChanged ||
            sizeChanged ||
            placeholderChanged)) {
      _cachedText = text;
      _cachedFirstRect = firstRect;
      _cachedTextStyle = widget.style;
      _cachedSize = size;
      _cachedPlaceholder = _placeholderLocation;
      bool belowRenderEditableBottom = false;
      final List<SelectionRect> rects = List<SelectionRect?>.generate(
        _cachedText.characters.length,
        (int i) {
          if (belowRenderEditableBottom) return null;

          final int offset =
              _cachedText.characters.getRange(0, i).string.length;
          final List<Rect> boxes = renderEditable.getBoxesForSelection(
              TextSelection(
                  baseOffset: offset,
                  extentOffset: offset +
                      _cachedText.characters.characterAt(i).string.length));
          if (boxes.isEmpty) return null;

          final SelectionRect selectionRect = SelectionRect(
            bounds: boxes.first,
            position: offset,
          );
          if (renderEditable.paintBounds.bottom < selectionRect.bounds.top) {
            belowRenderEditableBottom = true;
            return null;
          }
          return selectionRect;
        },
      )
          .where((SelectionRect? selectionRect) {
            if (selectionRect == null) return false;
            if (renderEditable.paintBounds.right < selectionRect.bounds.left ||
                selectionRect.bounds.right < renderEditable.paintBounds.left)
              return false;
            if (renderEditable.paintBounds.bottom < selectionRect.bounds.top ||
                selectionRect.bounds.bottom < renderEditable.paintBounds.top)
              return false;
            return true;
          })
          .map<SelectionRect>((SelectionRect? selectionRect) => selectionRect!)
          .toList();
      _textInputConnection!.setSelectionRects(rects);
    }
  }

  void _updateSizeAndTransform() {
    if (_hasInputConnection) {
      final Size size = renderEditable.size;
      final Matrix4 transform = renderEditable.getTransformTo(null);
      _textInputConnection!.setEditableSizeAndTransform(size, transform);
      _updateSelectionRects();
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateSizeAndTransform());
    } else if (_placeholderLocation != -1) {
      removeTextPlaceholder();
    }
  }

  // Sends the current composing rect to the iOS text input plugin via the text
  // input channel. We need to keep sending the information even if no text is
  // currently marked, as the information usually lags behind. The text input
  // plugin needs to estimate the composing rect based on the latest caret rect,
  // when the composing rect info didn't arrive in time.
  void _updateComposingRectIfNeeded() {
    final TextRange composingRange = _value.composing;
    if (_hasInputConnection) {
      assert(mounted);
      Rect? composingRect =
          renderEditable.getRectForComposingRange(composingRange);
      // Send the caret location instead if there's no marked text yet.
      if (composingRect == null) {
        assert(!composingRange.isValid || composingRange.isCollapsed);
        final int offset = composingRange.isValid ? composingRange.start : 0;
        composingRect =
            renderEditable.getLocalRectForCaret(TextPosition(offset: offset));
      }
      assert(composingRect != null);
      _textInputConnection!.setComposingRect(composingRect);
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateComposingRectIfNeeded());
    }
  }

  void _updateCaretRectIfNeeded() {
    if (_hasInputConnection) {
      if (renderEditable.selection != null &&
          renderEditable.selection!.isValid &&
          renderEditable.selection!.isCollapsed) {
        final TextPosition currentTextPosition =
            TextPosition(offset: renderEditable.selection!.baseOffset);
        final Rect caretRect =
            renderEditable.getLocalRectForCaret(currentTextPosition);
        _textInputConnection!.setCaretRect(caretRect);
      }
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateCaretRectIfNeeded());
    }
  }

  TextDirection get _textDirection {
    final TextDirection result =
        widget.textDirection ?? Directionality.of(context);
    assert(result != null,
        '$runtimeType created without a textDirection and with no ambient Directionality.');
    return result;
  }

  /// The renderer for this widget's descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures
  /// when [RenderEditable.ignorePointer] is true.
  RenderEditable get renderEditable =>
      _editableKey.currentContext!.findRenderObject()! as RenderEditable;

  @override
  TextEditingValue get textEditingValue => _value;

  double get _devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause? cause) {
    // Compare the current TextEditingValue with the pre-format new
    // TextEditingValue value, in case the formatter would reject the change.
    final bool shouldShowCaret =
        widget.readOnly ? _value.selection != value.selection : _value != value;
    if (shouldShowCaret) {
      _scheduleShowCaretOnScreen(withAnimation: true);
    }
    _formatAndSetValue(value, cause, userInteraction: true);
  }

  @override
  void bringIntoView(TextPosition position) {
    final Rect localRect = renderEditable.getLocalRectForCaret(position);
    final RevealedOffset targetOffset = _getOffsetToRevealCaret(localRect);

    _scrollController.jumpTo(targetOffset.offset);
    renderEditable.showOnScreen(rect: targetOffset.rect);
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }
    _clipboardStatus?.update();
    _selectionOverlay!.showToolbar();
    return true;
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (hideHandles) {
      // Hide the handles and the toolbar.
      _selectionOverlay?.hide();
    } else if (_selectionOverlay?.toolbarIsVisible ?? false) {
      // Hide only the toolbar but not the handles.
      _selectionOverlay?.hideToolbar();
    }
  }

  /// Toggles the visibility of the toolbar.
  void toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay!.toolbarIsVisible) {
      hideToolbar();
    } else {
      showToolbar();
    }
  }

  // Tracks the location a [_ScribblePlaceholder] should be rendered in the
  // text.
  //
  // A value of -1 indicates there should be no placeholder, otherwise the
  // value should be between 0 and the length of the text, inclusive.
  int _placeholderLocation = -1;

  @override
  void insertTextPlaceholder(Size size) {
    if (!widget.scribbleEnabled) return;

    if (!widget.controller.selection.isValid) return;

    setState(() {
      _placeholderLocation =
          _value.text.length - widget.controller.selection.end;
    });
  }

  @override
  void removeTextPlaceholder() {
    if (!widget.scribbleEnabled) return;

    setState(() {
      _placeholderLocation = -1;
    });
  }

  @override
  String get autofillId => 'EditableText-$hashCode';

  @override
  TextInputConfiguration get textInputConfiguration {
    final List<String>? autofillHints =
        widget.autofillHints?.toList(growable: false);
    final AutofillConfiguration autofillConfiguration = autofillHints != null
        ? AutofillConfiguration(
            uniqueIdentifier: autofillId,
            autofillHints: autofillHints,
            currentEditingValue: currentTextEditingValue,
          )
        : AutofillConfiguration.disabled;

    return TextInputConfiguration(
      inputType: widget.keyboardType,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      enableInteractiveSelection: true,
      inputAction: widget.textInputAction ??
          (widget.keyboardType == TextInputType.multiline
              ? TextInputAction.newline
              : TextInputAction.done),
      textCapitalization: widget.textCapitalization,
      keyboardAppearance: widget.keyboardAppearance,
      autofillConfiguration: autofillConfiguration,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
    );
  }

  @override
  void autofill(TextEditingValue value) => updateEditingValue(value);

  // null if no promptRect should be shown.
  TextRange? _currentPromptRectRange;

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    setState(() {
      _currentPromptRectRange = TextRange(start: start, end: end);
    });
  }

  VoidCallback? _semanticsOnCopy(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            copyEnabled &&
            _hasFocus &&
            (controls?.canCopy(this) ?? false)
        ? () => controls!.handleCopy(this)
        : null;
  }

  VoidCallback? _semanticsOnCut(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            cutEnabled &&
            _hasFocus &&
            (controls?.canCut(this) ?? false)
        ? () => controls!.handleCut(this)
        : null;
  }

  VoidCallback? _semanticsOnPaste(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            pasteEnabled &&
            _hasFocus &&
            (controls?.canPaste(this) ?? false) &&
            (_clipboardStatus == null ||
                _clipboardStatus!.value == ClipboardStatus.pasteable)
        ? () => controls!.handlePaste(this)
        : null;
  }

  // --------------------------- Text Editing Actions ---------------------------

  _TextBoundary _characterBoundary(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary = widget.obscureText
        ? _CodeUnitBoundary(_value)
        : _CharacterBoundary(_value);
    return _CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  _TextBoundary _nextWordBoundary(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary;
    final _TextBoundary boundary;

    if (widget.obscureText) {
      atomicTextBoundary = _CodeUnitBoundary(_value);
      boundary = _DocumentBoundary(_value);
    } else {
      final TextEditingValue textEditingValue =
          _textEditingValueforTextLayoutMetrics;
      atomicTextBoundary = _CharacterBoundary(textEditingValue);
      // This isn't enough. Newline characters.
      boundary = _ExpandedTextBoundary(_WhitespaceBoundary(textEditingValue),
          _WordBoundary(renderEditable, textEditingValue));
    }

    final _MixedBoundary mixedBoundary = intent.forward
        ? _MixedBoundary(atomicTextBoundary, boundary)
        : _MixedBoundary(boundary, atomicTextBoundary);
    // Use a _MixedBoundary to make sure we don't leave invalid codepoints in
    // the field after deletion.
    return _CollapsedSelectionBoundary(mixedBoundary, intent.forward);
  }

  _TextBoundary _linebreak(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary;
    final _TextBoundary boundary;

    if (widget.obscureText) {
      atomicTextBoundary = _CodeUnitBoundary(_value);
      boundary = _DocumentBoundary(_value);
    } else {
      final TextEditingValue textEditingValue =
          _textEditingValueforTextLayoutMetrics;
      atomicTextBoundary = _CharacterBoundary(textEditingValue);
      boundary = _LineBreak(renderEditable, textEditingValue);
    }

    // The _MixedBoundary is to make sure we don't leave invalid code units in
    // the field after deletion.
    // `boundary` doesn't need to be wrapped in a _CollapsedSelectionBoundary,
    // since the document boundary is unique and the linebreak boundary is
    // already caret-location based.
    return intent.forward
        ? _MixedBoundary(
            _CollapsedSelectionBoundary(atomicTextBoundary, true), boundary)
        : _MixedBoundary(
            boundary, _CollapsedSelectionBoundary(atomicTextBoundary, false));
  }

  _TextBoundary _documentBoundary(DirectionalTextEditingIntent intent) =>
      _DocumentBoundary(_value);

  Action<T> _makeOverridable<T extends Intent>(Action<T> defaultAction) {
    return Action<T>.overridable(
        context: context, defaultAction: defaultAction);
  }

  void _replaceText(ReplaceTextIntent intent) {
    final TextEditingValue oldValue = _value;
    final TextEditingValue newValue = intent.currentTextEditingValue.replaced(
      intent.replacementRange,
      intent.replacementText,
    );
    userUpdateTextEditingValue(newValue, intent.cause);

    // If there's no change in text and selection (e.g. when selecting and
    // pasting identical text), the widget won't be rebuilt on value update.
    // Handle this by calling _didChangeTextEditingValue() so caret and scroll
    // updates can happen.
    if (newValue == oldValue) {
      _didChangeTextEditingValue();
    }
  }

  late final Action<ReplaceTextIntent> _replaceTextAction =
      CallbackAction<ReplaceTextIntent>(onInvoke: _replaceText);

  // Scrolls either to the beginning or end of the document depending on the
  // intent's `forward` parameter.
  void _scrollToDocumentBoundary(ScrollToDocumentBoundaryIntent intent) {
    if (intent.forward) {
      bringIntoView(TextPosition(offset: _value.text.length));
    } else {
      bringIntoView(const TextPosition(offset: 0));
    }
  }

  void _updateSelection(UpdateSelectionIntent intent) {
    bringIntoView(intent.newSelection.extent);
    userUpdateTextEditingValue(
      intent.currentTextEditingValue.copyWith(selection: intent.newSelection),
      intent.cause,
    );
  }

  late final Action<UpdateSelectionIntent> _updateSelectionAction =
      CallbackAction<UpdateSelectionIntent>(onInvoke: _updateSelection);

  late final _UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent> _adjacentLineAction =
      _UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>(this);

  void _expandSelectionToDocumentBoundary(
      ExpandSelectionToDocumentBoundaryIntent intent) {
    final _TextBoundary textBoundary = _documentBoundary(intent);
    _expandSelection(intent.forward, textBoundary, true);
  }

  void _expandSelectionToLinebreak(ExpandSelectionToLineBreakIntent intent) {
    final _TextBoundary textBoundary = _linebreak(intent);
    _expandSelection(intent.forward, textBoundary);
  }

  void _expandSelection(bool forward, _TextBoundary textBoundary,
      [bool extentAtIndex = false]) {
    final TextSelection textBoundarySelection =
        textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return;
    }

    final bool inOrder =
        textBoundarySelection.baseOffset <= textBoundarySelection.extentOffset;
    final bool towardsExtent = forward == inOrder;
    final TextPosition position = towardsExtent
        ? textBoundarySelection.extent
        : textBoundarySelection.base;

    final TextPosition newExtent = forward
        ? textBoundary.getTrailingTextBoundaryAt(position)
        : textBoundary.getLeadingTextBoundaryAt(position);

    final TextSelection newSelection = textBoundarySelection.expandTo(
        newExtent, textBoundarySelection.isCollapsed || extentAtIndex);
    userUpdateTextEditingValue(
      _value.copyWith(selection: newSelection),
      SelectionChangedCause.keyboard,
    );
    bringIntoView(newSelection.extent);
  }

  Object? _hideToolbarIfVisible(DismissIntent intent) {
    if (_selectionOverlay?.toolbarIsVisible ?? false) {
      hideToolbar(false);
      return null;
    }
    return Actions.invoke(context, intent);
  }

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    DoNothingAndStopPropagationTextIntent: DoNothingAction(consumesKey: false),
    ReplaceTextIntent: _replaceTextAction,
    UpdateSelectionIntent: _updateSelectionAction,
    DirectionalFocusIntent: DirectionalFocusAction.forTextField(),
    DismissIntent:
        CallbackAction<DismissIntent>(onInvoke: _hideToolbarIfVisible),

    // Delete
    DeleteCharacterIntent: _makeOverridable(
        _DeleteTextAction<DeleteCharacterIntent>(this, _characterBoundary)),
    DeleteToNextWordBoundaryIntent: _makeOverridable(
        _DeleteTextAction<DeleteToNextWordBoundaryIntent>(
            this, _nextWordBoundary)),
    DeleteToLineBreakIntent: _makeOverridable(
        _DeleteTextAction<DeleteToLineBreakIntent>(this, _linebreak)),

    // Extend/Move Selection
    ExtendSelectionByCharacterIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(
      this,
      false,
      _characterBoundary,
    )),
    ExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(
            this, true, _nextWordBoundary)),
    ExtendSelectionToLineBreakIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(
            this, true, _linebreak)),
    ExpandSelectionToLineBreakIntent: _makeOverridable(
        CallbackAction<ExpandSelectionToLineBreakIntent>(
            onInvoke: _expandSelectionToLinebreak)),
    ExpandSelectionToDocumentBoundaryIntent: _makeOverridable(
        CallbackAction<ExpandSelectionToDocumentBoundaryIntent>(
            onInvoke: _expandSelectionToDocumentBoundary)),
    ExtendSelectionVerticallyToAdjacentLineIntent:
        _makeOverridable(_adjacentLineAction),
    ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
            this, true, _documentBoundary)),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: _makeOverridable(
        _ExtendSelectionOrCaretPositionAction(this, _nextWordBoundary)),
    ScrollToDocumentBoundaryIntent: _makeOverridable(
        CallbackAction<ScrollToDocumentBoundaryIntent>(
            onInvoke: _scrollToDocumentBoundary)),

    // Copy Paste
    SelectAllTextIntent: _makeOverridable(_SelectAllAction(this)),
    CopySelectionTextIntent: _makeOverridable(_CopySelectionAction(this)),
    PasteTextIntent: _makeOverridable(CallbackAction<PasteTextIntent>(
        onInvoke: (PasteTextIntent intent) => pasteText(intent.cause))),
  };

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final TextSelectionControls? controls = widget.selectionControls;
    return MouseRegion(
      cursor: widget.mouseCursor ?? SystemMouseCursors.text,
      child: Actions(
        actions: _actions,
        child: _TextEditingHistory(
          controller: widget.controller,
          onTriggered: (TextEditingValue value) {
            userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);
          },
          child: Focus(
            focusNode: widget.focusNode,
            includeSemantics: false,
            debugLabel: 'EditableText',
            child: Scrollable(
              excludeFromSemantics: true,
              axisDirection:
                  _isMultiline ? AxisDirection.down : AxisDirection.right,
              controller: _scrollController,
              physics: widget.scrollPhysics,
              dragStartBehavior: widget.dragStartBehavior,
              restorationId: widget.restorationId,
              // If a ScrollBehavior is not provided, only apply scrollbars when
              // multiline. The overscroll indicator should not be applied in
              // either case, glowing or stretching.
              scrollBehavior: widget.scrollBehavior ??
                  ScrollConfiguration.of(context).copyWith(
                    scrollbars: _isMultiline,
                    overscroll: false,
                  ),
              viewportBuilder: (BuildContext context, ViewportOffset offset) {
                return CompositedTransformTarget(
                  link: _toolbarLayerLink,
                  child: Semantics(
                    onCopy: _semanticsOnCopy(controls),
                    onCut: _semanticsOnCut(controls),
                    onPaste: _semanticsOnPaste(controls),
                    child: _ScribbleFocusable(
                      focusNode: widget.focusNode,
                      editableKey: _editableKey,
                      enabled: widget.scribbleEnabled,
                      updateSelectionRects: () {
                        _openInputConnection();
                        _updateSelectionRects(force: true);
                      },
                      child: EditorRenderWidget(
                        key: _editableKey,
                        startHandleLayerLink: _startHandleLayerLink,
                        endHandleLayerLink: _endHandleLayerLink,
                        inlineSpan: buildTextSpan(),
                        value: _value,
                        cursorColor: _cursorColor,
                        backgroundCursorColor: widget.backgroundCursorColor,
                        showCursor: EditableText.debugDeterministicCursor
                            ? ValueNotifier<bool>(widget.showCursor)
                            : _cursorVisibilityNotifier,
                        forceLine: widget.forceLine,
                        readOnly: widget.readOnly,
                        hasFocus: _hasFocus,
                        maxLines: widget.maxLines,
                        minLines: widget.minLines,
                        expands: widget.expands,
                        strutStyle: widget.strutStyle,
                        selectionColor: widget.selectionColor,
                        textScaleFactor: widget.textScaleFactor ??
                            MediaQuery.textScaleFactorOf(context),
                        textAlign: widget.textAlign,
                        textDirection: _textDirection,
                        locale: widget.locale,
                        textHeightBehavior: widget.textHeightBehavior ??
                            DefaultTextHeightBehavior.of(context),
                        textWidthBasis: widget.textWidthBasis,
                        obscuringCharacter: widget.obscuringCharacter,
                        obscureText: widget.obscureText,
                        offset: offset,
                        onCaretChanged: _handleCaretChanged,
                        rendererIgnoresPointer: widget.rendererIgnoresPointer,
                        cursorWidth: widget.cursorWidth,
                        cursorHeight: widget.cursorHeight,
                        cursorRadius: widget.cursorRadius,
                        cursorOffset: widget.cursorOffset ?? Offset.zero,
                        selectionHeightStyle: widget.selectionHeightStyle,
                        selectionWidthStyle: widget.selectionWidthStyle,
                        paintCursorAboveText: widget.paintCursorAboveText,
                        enableInteractiveSelection: true,
                        textSelectionDelegate: this,
                        devicePixelRatio: _devicePixelRatio,
                        promptRectRange: _currentPromptRectRange,
                        promptRectColor: widget.autocorrectionTextRectColor,
                        clipBehavior: widget.clipBehavior,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds [TextSpan] from current editing value.
  ///
  /// By default makes text in composing range appear as underlined.
  /// Descendants can override this method to customize appearance of text.
  TextSpan buildTextSpan() {
    if (widget.obscureText) {
      String text = _value.text;
      text = widget.obscuringCharacter * text.length;
      // Reveal the latest character in an obscured field only on mobile.
      const Set<TargetPlatform> mobilePlatforms = <TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.fuchsia,
      };
      final bool breiflyShowPassword =
          WidgetsBinding.instance.platformDispatcher.brieflyShowPassword &&
              mobilePlatforms.contains(defaultTargetPlatform);
      if (breiflyShowPassword) {
        final int? o =
            _obscureShowCharTicksPending > 0 ? _obscureLatestCharIndex : null;
        if (o != null && o >= 0 && o < text.length)
          text = text.replaceRange(o, o + 1, _value.text.substring(o, o + 1));
      }
      return TextSpan(style: widget.style, text: text);
    }
    if (_placeholderLocation >= 0 &&
        _placeholderLocation <= _value.text.length) {
      final List<_ScribblePlaceholder> placeholders = <_ScribblePlaceholder>[];
      final int placeholderLocation = _value.text.length - _placeholderLocation;
      if (_isMultiline) {
        // The zero size placeholder here allows the line to break and keep the caret on the first line.
        placeholders.add(
            const _ScribblePlaceholder(child: SizedBox(), size: Size.zero));
        placeholders.add(_ScribblePlaceholder(
            child: const SizedBox(),
            size: Size(renderEditable.size.width, 0.0)));
      } else {
        placeholders.add(const _ScribblePlaceholder(
            child: SizedBox(), size: Size(100.0, 0.0)));
      }
      return TextSpan(
        style: widget.style,
        children: <InlineSpan>[
          TextSpan(text: _value.text.substring(0, placeholderLocation)),
          ...placeholders,
          TextSpan(text: _value.text.substring(placeholderLocation)),
        ],
      );
    }

    // Read only mode should not paint text composing.
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: !widget.readOnly && _hasFocus,
    );
  }
}


abstract class _TextBoundary {
  const _TextBoundary();

  TextEditingValue get textEditingValue;

  /// Returns the leading text boundary at the given location, inclusive.
  TextPosition getLeadingTextBoundaryAt(TextPosition position);

  /// Returns the trailing text boundary at the given location, exclusive.
  TextPosition getTrailingTextBoundaryAt(TextPosition position);

  TextRange getTextBoundaryAt(TextPosition position) {
    return TextRange(
      start: getLeadingTextBoundaryAt(position).offset,
      end: getTrailingTextBoundaryAt(position).offset,
    );
  }
}

class _CodeUnitBoundary extends _TextBoundary {
  const _CodeUnitBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      TextPosition(offset: position.offset);
  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) => TextPosition(
      offset: math.min(position.offset + 1, textEditingValue.text.length));
}

// The word modifier generally removes the word boundaries around white spaces
// (and newlines), IOW white spaces and some other punctuations are considered
// a part of the next word in the search direction.
class _WhitespaceBoundary extends _TextBoundary {
  const _WhitespaceBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    for (int index = position.offset; index >= 0; index -= 1) {
      if (!TextLayoutMetrics.isWhitespace(
          textEditingValue.text.codeUnitAt(index))) {
        return TextPosition(offset: index);
      }
    }
    return const TextPosition(offset: 0);
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    for (int index = position.offset;
        index < textEditingValue.text.length;
        index += 1) {
      if (!TextLayoutMetrics.isWhitespace(
          textEditingValue.text.codeUnitAt(index))) {
        return TextPosition(offset: index + 1);
      }
    }
    return TextPosition(offset: textEditingValue.text.length);
  }
}

// Most apps delete the entire grapheme when the backspace key is pressed.
// Also always put the new caret location to character boundaries to avoid
// sending malformed UTF-16 code units to the paragraph builder.
class _CharacterBoundary extends _TextBoundary {
  const _CharacterBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    final int endOffset =
        math.min(position.offset + 1, textEditingValue.text.length);
    return TextPosition(
      offset:
          CharacterRange.at(textEditingValue.text, position.offset, endOffset)
              .stringBeforeLength,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    final int endOffset =
        math.min(position.offset + 1, textEditingValue.text.length);
    final CharacterRange range =
        CharacterRange.at(textEditingValue.text, position.offset, endOffset);
    return TextPosition(
      offset: textEditingValue.text.length - range.stringAfterLength,
    );
  }

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    final int endOffset =
        math.min(position.offset + 1, textEditingValue.text.length);
    final CharacterRange range =
        CharacterRange.at(textEditingValue.text, position.offset, endOffset);
    return TextRange(
      start: range.stringBeforeLength,
      end: textEditingValue.text.length - range.stringAfterLength,
    );
  }
}

// [UAX #29](https://unicode.org/reports/tr29/) defined word boundaries.
class _WordBoundary extends _TextBoundary {
  const _WordBoundary(this.textLayout, this.textEditingValue);

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getWordBoundary(position).start,
      // Word boundary seems to always report downstream on many platforms.
      affinity:
          TextAffinity.downstream, // ignore: avoid_redundant_argument_values
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getWordBoundary(position).end,
      // Word boundary seems to always report downstream on many platforms.
      affinity:
          TextAffinity.downstream, // ignore: avoid_redundant_argument_values
    );
  }
}

// The linebreaks of the current text layout. The input [TextPosition]s are
// interpreted as caret locations because [TextPainter.getLineAtOffset] is
// text-affinity-aware.
class _LineBreak extends _TextBoundary {
  const _LineBreak(
    this.textLayout,
    this.textEditingValue,
  );

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getLineAtOffset(position).start,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
  }
}

// The document boundary is unique and is a constant function of the input
// position.
class _DocumentBoundary extends _TextBoundary {
  const _DocumentBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      const TextPosition(offset: 0);
  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textEditingValue.text.length,
      affinity: TextAffinity.upstream,
    );
  }
}

// ------------------------  Text Boundary Combinators ------------------------

// Expands the innerTextBoundary with outerTextBoundary.
class _ExpandedTextBoundary extends _TextBoundary {
  _ExpandedTextBoundary(this.innerTextBoundary, this.outerTextBoundary);

  final _TextBoundary innerTextBoundary;
  final _TextBoundary outerTextBoundary;

  @override
  TextEditingValue get textEditingValue {
    assert(innerTextBoundary.textEditingValue ==
        outerTextBoundary.textEditingValue);
    return innerTextBoundary.textEditingValue;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return outerTextBoundary.getLeadingTextBoundaryAt(
      innerTextBoundary.getLeadingTextBoundaryAt(position),
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return outerTextBoundary.getTrailingTextBoundaryAt(
      innerTextBoundary.getTrailingTextBoundaryAt(position),
    );
  }
}

// Force the innerTextBoundary to interpret the input [TextPosition]s as caret
// locations instead of code unit positions.
//
// The innerTextBoundary must be a [_TextBoundary] that interprets the input
// [TextPosition]s as code unit positions.
class _CollapsedSelectionBoundary extends _TextBoundary {
  _CollapsedSelectionBoundary(this.innerTextBoundary, this.isForward);

  final _TextBoundary innerTextBoundary;
  final bool isForward;

  @override
  TextEditingValue get textEditingValue => innerTextBoundary.textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getLeadingTextBoundaryAt(position)
        : position.offset <= 0
            ? const TextPosition(offset: 0)
            : innerTextBoundary.getLeadingTextBoundaryAt(
                TextPosition(offset: position.offset - 1));
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getTrailingTextBoundaryAt(position)
        : position.offset <= 0
            ? const TextPosition(offset: 0)
            : innerTextBoundary.getTrailingTextBoundaryAt(
                TextPosition(offset: position.offset - 1));
  }
}

// A _TextBoundary that creates a [TextRange] where its start is from the
// specified leading text boundary and its end is from the specified trailing
// text boundary.
class _MixedBoundary extends _TextBoundary {
  _MixedBoundary(this.leadingTextBoundary, this.trailingTextBoundary);

  final _TextBoundary leadingTextBoundary;
  final _TextBoundary trailingTextBoundary;

  @override
  TextEditingValue get textEditingValue {
    assert(leadingTextBoundary.textEditingValue ==
        trailingTextBoundary.textEditingValue);
    return leadingTextBoundary.textEditingValue;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      leadingTextBoundary.getLeadingTextBoundaryAt(position);

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) =>
      trailingTextBoundary.getTrailingTextBoundaryAt(position);
}

// -------------------------------  Text Actions -------------------------------
class _DeleteTextAction<T extends DirectionalTextEditingIntent>
    extends ContextAction<T> {
  _DeleteTextAction(this.state, this.getTextBoundariesForIntent);

  final EditorState state;
  final _TextBoundary Function(T intent) getTextBoundariesForIntent;

  TextRange _expandNonCollapsedRange(TextEditingValue value) {
    final TextRange selection = value.selection;
    assert(selection.isValid);
    assert(!selection.isCollapsed);
    final _TextBoundary atomicBoundary = state.widget.obscureText
        ? _CodeUnitBoundary(value)
        : _CharacterBoundary(value);

    return TextRange(
      start: atomicBoundary
          .getLeadingTextBoundaryAt(TextPosition(offset: selection.start))
          .offset,
      end: atomicBoundary
          .getTrailingTextBoundaryAt(TextPosition(offset: selection.end - 1))
          .offset,
    );
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    if (!selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
            state._value,
            '',
            _expandNonCollapsedRange(state._value),
            SelectionChangedCause.keyboard),
      );
    }

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    if (!textBoundary.textEditingValue.selection.isValid) {
      return null;
    }
    if (!textBoundary.textEditingValue.selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
            state._value,
            '',
            _expandNonCollapsedRange(textBoundary.textEditingValue),
            SelectionChangedCause.keyboard),
      );
    }

    return Actions.invoke(
      context!,
      ReplaceTextIntent(
        textBoundary.textEditingValue,
        '',
        textBoundary
            .getTextBoundaryAt(textBoundary.textEditingValue.selection.base),
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      !state.widget.readOnly && state._value.selection.isValid;
}

class _UpdateTextSelectionAction<T extends DirectionalCaretMovementIntent>
    extends ContextAction<T> {
  _UpdateTextSelectionAction(
    this.state,
    this.ignoreNonCollapsedSelection,
    this.getTextBoundariesForIntent,
  );

  final EditorState state;
  final bool ignoreNonCollapsedSelection;
  final _TextBoundary Function(T intent) getTextBoundariesForIntent;

  static const int NEWLINE_CODE_UNIT = 10;

  // Returns true iff the given position is at a wordwrap boundary in the
  // upstream position.
  bool _isAtWordwrapUpstream(TextPosition position) {
    final TextPosition end = TextPosition(
      offset: state.renderEditable.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
    return end == position &&
        end.offset != state.textEditingValue.text.length &&
        state.textEditingValue.text.codeUnitAt(position.offset) !=
            NEWLINE_CODE_UNIT;
  }

  // Returns true iff the given position at a wordwrap boundary in the
  // downstream position.
  bool _isAtWordwrapDownstream(TextPosition position) {
    final TextPosition start = TextPosition(
      offset: state.renderEditable.getLineAtOffset(position).start,
    );
    return start == position &&
        start.offset != 0 &&
        state.textEditingValue.text.codeUnitAt(position.offset - 1) !=
            NEWLINE_CODE_UNIT;
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    final bool collapseSelection =
        intent.collapseSelection || !state.widget.selectionEnabled;
    // Collapse to the logical start/end.
    TextSelection _collapse(TextSelection selection) {
      assert(selection.isValid);
      assert(!selection.isCollapsed);
      return selection.copyWith(
        baseOffset: intent.forward ? selection.end : selection.start,
        extentOffset: intent.forward ? selection.end : selection.start,
      );
    }

    if (!selection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
            state._value, _collapse(selection), SelectionChangedCause.keyboard),
      );
    }

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    final TextSelection textBoundarySelection =
        textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return null;
    }
    if (!textBoundarySelection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(state._value, _collapse(textBoundarySelection),
            SelectionChangedCause.keyboard),
      );
    }

    TextPosition extent = textBoundarySelection.extent;

    // If continuesAtWrap is true extent and is at the relevant wordwrap, then
    // move it just to the other side of the wordwrap.
    if (intent.continuesAtWrap) {
      if (intent.forward && _isAtWordwrapUpstream(extent)) {
        extent = TextPosition(
          offset: extent.offset,
        );
      } else if (!intent.forward && _isAtWordwrapDownstream(extent)) {
        extent = TextPosition(
          offset: extent.offset,
          affinity: TextAffinity.upstream,
        );
      }
    }

    final TextPosition newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final TextSelection newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : textBoundarySelection.extendTo(newExtent);

    // If collapseAtReversal is true and would have an effect, collapse it.
    if (!selection.isCollapsed &&
        intent.collapseAtReversal &&
        (selection.baseOffset < selection.extentOffset !=
            newSelection.baseOffset < newSelection.extentOffset)) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          state._value,
          TextSelection.fromPosition(selection.base),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(textBoundary.textEditingValue, newSelection,
          SelectionChangedCause.keyboard),
    );
  }

  @override
  bool get isActionEnabled => state._value.selection.isValid;
}

class _ExtendSelectionOrCaretPositionAction extends ContextAction<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  _ExtendSelectionOrCaretPositionAction(
      this.state, this.getTextBoundariesForIntent);

  final EditorState state;
  final _TextBoundary Function(
          ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent)
      getTextBoundariesForIntent;

  @override
  Object? invoke(ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent,
      [BuildContext? context]) {
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    final TextSelection textBoundarySelection =
        textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return null;
    }

    final TextPosition extent = textBoundarySelection.extent;
    final TextPosition newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final TextSelection newSelection =
        (newExtent.offset - textBoundarySelection.baseOffset) *
                    (textBoundarySelection.extentOffset -
                        textBoundarySelection.baseOffset) <
                0
            ? textBoundarySelection.copyWith(
                extentOffset: textBoundarySelection.baseOffset,
                affinity: textBoundarySelection.extentOffset >
                        textBoundarySelection.baseOffset
                    ? TextAffinity.downstream
                    : TextAffinity.upstream,
              )
            : textBoundarySelection.extendTo(newExtent);

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(textBoundary.textEditingValue, newSelection,
          SelectionChangedCause.keyboard),
    );
  }

  @override
  bool get isActionEnabled =>
      state.widget.selectionEnabled && state._value.selection.isValid;
}

class _UpdateTextSelectionToAdjacentLineAction<
    T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  _UpdateTextSelectionToAdjacentLineAction(this.state);

  final EditorState state;

  VerticalCaretMovementRun? _verticalMovementRun;
  TextSelection? _runSelection;

  void stopCurrentVerticalRunIfSelectionChanges() {
    final TextSelection? runSelection = _runSelection;
    if (runSelection == null) {
      assert(_verticalMovementRun == null);
      return;
    }
    _runSelection = state._value.selection;
    final TextSelection currentSelection = state.widget.controller.selection;
    final bool continueCurrentRun = currentSelection.isValid &&
        currentSelection.isCollapsed &&
        currentSelection.baseOffset == runSelection.baseOffset &&
        currentSelection.extentOffset == runSelection.extentOffset;
    if (!continueCurrentRun) {
      _verticalMovementRun = null;
      _runSelection = null;
    }
  }

  @override
  void invoke(T intent, [BuildContext? context]) {
    assert(state._value.selection.isValid);

    final bool collapseSelection =
        intent.collapseSelection || !state.widget.selectionEnabled;
    final TextEditingValue value = state._textEditingValueforTextLayoutMetrics;
    if (!value.selection.isValid) {
      return;
    }

    if (_verticalMovementRun?.isValid == false) {
      _verticalMovementRun = null;
      _runSelection = null;
    }

    final VerticalCaretMovementRun currentRun = _verticalMovementRun ??
        state.renderEditable
            .startVerticalCaretMovement(state.renderEditable.selection!.extent);

    final bool shouldMove =
        intent.forward ? currentRun.moveNext() : currentRun.movePrevious();
    final TextPosition newExtent = shouldMove
        ? currentRun.current
        : (intent.forward
            ? TextPosition(offset: state._value.text.length)
            : const TextPosition(offset: 0));
    final TextSelection newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : value.selection.extendTo(newExtent);

    Actions.invoke(
      context!,
      UpdateSelectionIntent(
          value, newSelection, SelectionChangedCause.keyboard),
    );
    if (state._value.selection == newSelection) {
      _verticalMovementRun = currentRun;
      _runSelection = newSelection;
    }
  }

  @override
  bool get isActionEnabled => state._value.selection.isValid;
}

class _SelectAllAction extends ContextAction<SelectAllTextIntent> {
  _SelectAllAction(this.state);

  final EditorState state;

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        state._value,
        TextSelection(baseOffset: 0, extentOffset: state._value.text.length),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled => state.widget.selectionEnabled;
}

class _CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  _CopySelectionAction(this.state);

  final EditorState state;

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      state.cutSelection(intent.cause);
    } else {
      state.copySelection(intent.cause);
    }
  }

  @override
  bool get isActionEnabled =>
      state._value.selection.isValid && !state._value.selection.isCollapsed;
}

/// A void function that takes a [TextEditingValue].
@visibleForTesting
typedef TextEditingValueCallback = void Function(TextEditingValue value);

/// Provides undo/redo capabilities for text editing.
///
/// Listens to [controller] as a [ValueNotifier] and saves relevant values for
/// undoing/redoing. The cadence at which values are saved is a best
/// approximation of the native behaviors of a hardware keyboard on Flutter's
/// desktop platforms, as there are subtle differences between each of these
/// platforms.
///
/// Listens to keyboard undo/redo shortcuts and calls [onTriggered] when a
/// shortcut is triggered that would affect the state of the [controller].
class _TextEditingHistory extends StatefulWidget {
  /// Creates an instance of [_TextEditingHistory].
  const _TextEditingHistory({
    Key? key,
    required this.child,
    required this.controller,
    required this.onTriggered,
  }) : super(key: key);

  /// The child widget of [_TextEditingHistory].
  final Widget child;

  /// The [TextEditingController] to save the state of over time.
  final TextEditingController controller;

  /// Called when an undo or redo causes a state change.
  ///
  /// If the state would still be the same before and after the undo/redo, this
  /// will not be called. For example, receiving a redo when there is nothing
  /// to redo will not call this method.
  ///
  /// It is also not called when the controller is changed for reasons other
  /// than undo/redo.
  final TextEditingValueCallback onTriggered;

  @override
  State<_TextEditingHistory> createState() => _TextEditingHistoryState();
}

class _TextEditingHistoryState extends State<_TextEditingHistory> {
  final _UndoStack<TextEditingValue> _stack = _UndoStack<TextEditingValue>();
  late final _Throttled<TextEditingValue> _throttledPush;
  Timer? _throttleTimer;

  // This duration was chosen as a best fit for the behavior of Mac, Linux,
  // and Windows undo/redo state save durations, but it is not perfect for any
  // of them.
  static const Duration _kThrottleDuration = Duration(milliseconds: 500);

  void _undo(UndoTextIntent intent) {
    _update(_stack.undo());
  }

  void _redo(RedoTextIntent intent) {
    _update(_stack.redo());
  }

  void _update(TextEditingValue? nextValue) {
    if (nextValue == null) {
      return;
    }
    if (nextValue.text == widget.controller.text) {
      return;
    }
    widget.onTriggered(widget.controller.value.copyWith(
      text: nextValue.text,
      selection: nextValue.selection,
    ));
  }

  void _push() {
    if (widget.controller.value == TextEditingValue.empty) {
      return;
    }

    _throttleTimer = _throttledPush(widget.controller.value);
  }

  @override
  void initState() {
    super.initState();
    _throttledPush = _throttle<TextEditingValue>(
      duration: _kThrottleDuration,
      function: _stack.push,
    );
    _push();
    widget.controller.addListener(_push);
  }

  @override
  void didUpdateWidget(_TextEditingHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _stack.clear();
      oldWidget.controller.removeListener(_push);
      widget.controller.addListener(_push);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_push);
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        UndoTextIntent: Action<UndoTextIntent>.overridable(
            context: context,
            defaultAction: CallbackAction<UndoTextIntent>(onInvoke: _undo)),
        RedoTextIntent: Action<RedoTextIntent>.overridable(
            context: context,
            defaultAction: CallbackAction<RedoTextIntent>(onInvoke: _redo)),
      },
      child: widget.child,
    );
  }
}

/// A data structure representing a chronological list of states that can be
/// undone and redone.
class _UndoStack<T> {
  /// Creates an instance of [_UndoStack].
  _UndoStack();

  final List<T> _list = <T>[];

  // The index of the current value, or null if the list is emtpy.
  late int _index;

  /// Returns the current value of the stack.
  T? get currentValue => _list.isEmpty ? null : _list[_index];

  /// Add a new state change to the stack.
  ///
  /// Pushing identical objects will not create multiple entries.
  void push(T value) {
    if (_list.isEmpty) {
      _index = 0;
      _list.add(value);
      return;
    }

    assert(_index < _list.length && _index >= 0);

    if (value == currentValue) {
      return;
    }

    // If anything has been undone in this stack, remove those irrelevant states
    // before adding the new one.
    if (_index != null && _index != _list.length - 1) {
      _list.removeRange(_index + 1, _list.length);
    }
    _list.add(value);
    _index = _list.length - 1;
  }

  /// Returns the current value after an undo operation.
  ///
  /// An undo operation moves the current value to the previously pushed value,
  /// if any.
  ///
  /// Iff the stack is completely empty, then returns null.
  T? undo() {
    if (_list.isEmpty) {
      return null;
    }

    assert(_index < _list.length && _index >= 0);

    if (_index != 0) {
      _index = _index - 1;
    }

    return currentValue;
  }

  /// Returns the current value after a redo operation.
  ///
  /// A redo operation moves the current value to the value that was last
  /// undone, if any.
  ///
  /// Iff the stack is completely empty, then returns null.
  T? redo() {
    if (_list.isEmpty) {
      return null;
    }

    assert(_index < _list.length && _index >= 0);

    if (_index < _list.length - 1) {
      _index = _index + 1;
    }

    return currentValue;
  }

  /// Remove everything from the stack.
  void clear() {
    _list.clear();
    _index = -1;
  }

  @override
  String toString() {
    return '_UndoStack $_list';
  }
}

/// A function that can be throttled with the throttle function.
typedef _Throttleable<T> = void Function(T currentArg);

/// A function that has been throttled by [_throttle].
typedef _Throttled<T> = Timer Function(T currentArg);

/// Returns a _Throttled that will call through to the given function only a
/// maximum of once per duration.
///
/// Only works for functions that take exactly one argument and return void.
_Throttled<T> _throttle<T>({
  required Duration duration,
  required _Throttleable<T> function,
  // If true, calls at the start of the timer.
  bool leadingEdge = false,
}) {
  Timer? timer;
  bool calledDuringTimer = false;
  late T arg;

  return (T currentArg) {
    arg = currentArg;
    if (timer != null) {
      calledDuringTimer = true;
      return timer!;
    }
    if (leadingEdge) {
      function(arg);
    }
    calledDuringTimer = false;
    timer = Timer(duration, () {
      if (!leadingEdge || calledDuringTimer) {
        function(arg);
      }
      timer = null;
    });
    return timer!;
  };
}
class _ScribbleFocusable extends StatefulWidget {
  const _ScribbleFocusable({
    Key? key,
    required this.child,
    required this.focusNode,
    required this.editableKey,
    required this.updateSelectionRects,
    required this.enabled,
  }): super(key: key);

  final Widget child;
  final FocusNode focusNode;
  final GlobalKey editableKey;
  final VoidCallback updateSelectionRects;
  final bool enabled;

  @override
  _ScribbleFocusableState createState() => _ScribbleFocusableState();
}

class _ScribbleFocusableState extends State<_ScribbleFocusable> implements ScribbleClient {
  _ScribbleFocusableState(): _elementIdentifier = (_nextElementIdentifier++).toString();

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      TextInput.registerScribbleElement(elementIdentifier, this);
    }
  }

  @override
  void didUpdateWidget(_ScribbleFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      TextInput.registerScribbleElement(elementIdentifier, this);
    }

    if (oldWidget.enabled && !widget.enabled) {
      TextInput.unregisterScribbleElement(elementIdentifier);
    }
  }

  @override
  void dispose() {
    TextInput.unregisterScribbleElement(elementIdentifier);
    super.dispose();
  }

  RenderEditable? get renderEditable => widget.editableKey.currentContext?.findRenderObject() as RenderEditable?;

  static int _nextElementIdentifier = 1;
  final String _elementIdentifier;

  @override
  String get elementIdentifier => _elementIdentifier;

  @override
  void onScribbleFocus(Offset offset) {
    widget.focusNode.requestFocus();
    renderEditable?.selectPositionAt(from: offset, cause: SelectionChangedCause.scribble);
    widget.updateSelectionRects();
  }

  @override
  bool isInScribbleRect(Rect rect) {
    final Rect calculatedBounds = bounds;
    if (renderEditable?.readOnly ?? false)
      return false;
    if (calculatedBounds == Rect.zero)
      return false;
    if (!calculatedBounds.overlaps(rect))
      return false;
    final Rect intersection = calculatedBounds.intersect(rect);
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, intersection.center);
    return result.path.any((HitTestEntry entry) => entry.target == renderEditable);
  }

  @override
  Rect get bounds {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !mounted || !box.attached)
      return Rect.zero;
    final Matrix4 transform = box.getTransformTo(null);
    return MatrixUtils.transformRect(transform, Rect.fromLTWH(0, 0, box.size.width, box.size.height));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ScribblePlaceholder extends WidgetSpan {
  const _ScribblePlaceholder({
    required Widget child,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    TextBaseline? baseline,
    TextStyle? style,
    required this.size,
  }) : assert(child != null),
       assert(baseline != null || !(
         identical(alignment, ui.PlaceholderAlignment.aboveBaseline) ||
         identical(alignment, ui.PlaceholderAlignment.belowBaseline) ||
         identical(alignment, ui.PlaceholderAlignment.baseline)
       )),
       super(
         alignment: alignment,
         baseline: baseline,
         style: style,
         child: child,
       );

  /// The size of the span, used in place of adding a placeholder size to the [TextPainter].
  final Size size;

  @override
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions>? dimensions }) {
    assert(debugAssertIsValid());
    final bool hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style!.getTextStyle(textScaleFactor: textScaleFactor));
    }
    builder.addPlaceholder(
      size.width,
      size.height,
      alignment,
      scale: textScaleFactor,
    );
    if (hasStyle) {
      builder.pop();
    }
  }
}

