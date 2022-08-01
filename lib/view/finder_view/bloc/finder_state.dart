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
    this.fileMap = const {},
  });
  final FinderStatus state;
  final Map<String, List<HFile>> fileMap;

  @override
  List<Object?> get props => [state, fileMap];

  FinderState copyWith({
    FinderStatus? state,
    Map<String, List<HFile>>? fileMap,
  }) {
    return FinderState(
      state: state ?? this.state,
      fileMap: fileMap ?? this.fileMap,
    );
  }
}
