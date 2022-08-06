import 'package:flutter/material.dart';

abstract class HButton extends StatelessWidget {
  HButton({
    Key? key,
    required this.child,
    required this.onTap,
  }) : super(key: key);

  final ValueNotifier<bool> _hoverNotifier = ValueNotifier(false);
  final ValueNotifier<Offset> _hoverOffsetNotofoer = ValueNotifier(Offset.zero);
  bool get onHover => _hoverNotifier.value;

  final VoidCallback onTap;

  final Widget child;

  Widget button(
      BuildContext context, bool onHover, Offset hoverOffset, Widget child);

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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverNotifier,
          ]),
          builder: (context, _) {
            return button(
              context,
              _hoverNotifier.value,
              _hoverOffsetNotofoer.value,
              child,
            );
          },
        ),
      ),
    );
  }
}
