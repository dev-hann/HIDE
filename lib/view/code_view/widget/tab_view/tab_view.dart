import 'package:flutter/material.dart';

class TabView extends StatelessWidget {
  const TabView({
    Key? key,
    required this.tabList,
    required this.onTap,
    required this.onTapClose,
    double? itemWidth,
    double? itemHeight,
  })  : itemWidth = itemWidth ?? 150,
        itemHeight = itemHeight ?? 30,
        super(key: key);
  final List<String> tabList;
  final Function(int index) onTap;
  final Function(int index) onTapClose;
  final double itemHeight;
  final double itemWidth;
  Widget item(int index) {
    final ValueNotifier<bool> hoverNotifier = ValueNotifier(false);
    return ValueListenableBuilder(
        valueListenable: hoverNotifier,
        builder: (context, value, _) {
          return MouseRegion(
            onExit: (_) {
              hoverNotifier.value = false;
            },
            onEnter: (_) {
              hoverNotifier.value = true;
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(hoverNotifier.value ? 0.5 : 0),
                border: Border.all(color: Colors.red),
              ),
              child: SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tabList[index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Icon(Icons.close),
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: tabList.length,
        itemBuilder: (context, index) {
          return item(index);
        },
      ),
    );
  }
}
