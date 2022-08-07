import 'package:flutter/material.dart';

typedef HoverWidgetBuilder = Widget Function(
    BuildContext context, bool onHover, Offset hoverOffset);

class HoverBuilder extends StatelessWidget {
  HoverBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final HoverWidgetBuilder builder;

  final ValueNotifier<bool> _hoverNotifier = ValueNotifier(false);
  final ValueNotifier<Offset> _hoverOffsetNotofoer = ValueNotifier(Offset.zero);
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) {
        _hoverNotifier.value = false;
      },
      onEnter: (_) {
        _hoverNotifier.value = true;
      },
      onHover: (event) {
        _hoverOffsetNotofoer.value = event.position;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _hoverNotifier,
          _hoverOffsetNotofoer,
        ]),
        builder: (context, _) {
          return builder(
              context, _hoverNotifier.value, _hoverOffsetNotofoer.value);
        },
      ),
    );
  }
}
