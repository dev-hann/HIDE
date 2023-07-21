part of 'panel_bloc.dart';

class PanelState extends Equatable {
  const PanelState({
    this.selectedFile,
    this.fileList = const [],
    this.pageController,
  });
  final HFile? selectedFile;
  final List<HFile> fileList;
  final PageController? pageController;

  int get selectedIndex {
    if (selectedFile == null) {
      return -1;
    }
    return fileList.indexWhere((element) => element.path == selectedFile!.path);
  }

  @override
  List<Object?> get props => [
        selectedFile,
        pageController,
        fileList.hashCode,
      ];

  PanelState copyWith({
    HFile? selectedFile,
    List<HFile>? fileList,
    PageController? pageController,
  }) {
    return PanelState(
      selectedFile: selectedFile ?? this.selectedFile,
      fileList: fileList ?? this.fileList,
      pageController: pageController ?? this.pageController,
    );
  }
}
