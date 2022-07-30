part of finder_bloc;

enum FinderStatus {
  init,
  loading,
  success,
  failure,
}

class FinderState extends Equatable {
  const FinderState({
    this.state = FinderStatus.init,
    this.currentFolder = const HFileFolder("./"),
    this.openedMap = const {},
  });
  final FinderStatus state;
  final HFileFolder currentFolder;
  final Map<HFileFolder, bool> openedMap;
  @override
  List<Object?> get props => [state, currentFolder];

  FinderState copyWith({
    FinderStatus? state,
    HFileFolder? currentFolder,
    Map<HFileFolder, bool>? openedMap,
  }) {
    return FinderState(
      state: state ?? this.state,
      currentFolder: currentFolder ?? this.currentFolder,
      openedMap: openedMap ?? this.openedMap,
    );
  }
}
