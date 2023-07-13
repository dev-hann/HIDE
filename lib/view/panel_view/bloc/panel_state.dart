part of 'panel_bloc.dart';

class PanelState extends Equatable {
  const PanelState({
    this.fileList = const [],
    this.selectedIndex = -1,
    this.controllerMap = const {},
  });
  final int selectedIndex;
  final List<HFile> fileList;
  final Map<HFile, TextEditingController> controllerMap;

  TextEditingController get controller {
    if (selectedIndex == -1) {
      return TextEditingController();
    }
    final file = fileList[selectedIndex];

    return controllerMap[file] ??= TextEditingController(
      text: file.data,
    );
  }

  @override
  List<Object?> get props => [
        selectedIndex,
        fileList.hashCode,
        controllerMap.hashCode,
      ];

  PanelState copyWith({
    int? selectedIndex,
    List<HFile>? fileList,
    Map<HFile, TextEditingController>? controllerMap,
  }) {
    return PanelState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      fileList: fileList ?? this.fileList,
      controllerMap: controllerMap ?? this.controllerMap,
    );
  }
}
