part of 'panel_bloc.dart';

class PanelState extends Equatable {
  const PanelState({
    this.selectedIndex = -1,
    this.editorMap = const {},
    this.pageController,
  });
  final int selectedIndex;
  final Map<HFile, HEditor> editorMap;
  final PageController? pageController;

  @override
  List<Object?> get props => [
        selectedIndex,
        pageController,
      ];

  PanelState copyWith({
    int? selectedIndex,
    Map<HFile, HEditor>? editorMap,
    PageController? pageController,
  }) {
    return PanelState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      editorMap: editorMap ?? this.editorMap,
      pageController: pageController ?? this.pageController,
    );
  }
}
