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
    this.currentFolder = const HFolder("./"),
  });
  final FinderStatus state;
  final HFolder currentFolder;

  @override
  List<Object?> get props => [state, currentFolder];

  FinderState copyWith({
    FinderStatus? state,
    HFolder? currentFolder,
  }) {
    return FinderState(
      state: state ?? this.state,
      currentFolder: currentFolder ?? this.currentFolder,
    );
  }
}
