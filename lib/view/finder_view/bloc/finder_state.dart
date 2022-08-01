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
    this.opnedFolderList = const [],
  });
  final FinderStatus state;
  final List<String> opnedFolderList;

  @override
  List<Object?> get props => [state, opnedFolderList];

  FinderState copyWith({
    FinderStatus? state,
    List<String>? opnedFolderList,
  }) {
    return FinderState(
      state: state ?? this.state,
      opnedFolderList: opnedFolderList ?? this.opnedFolderList,
    );
  }
}
