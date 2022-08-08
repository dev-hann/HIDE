part of code_bloc;

enum CodeStatus {
  init,
  loading,
  success,
  failure,
}

class CodeState extends Equatable {
  const CodeState({
    this.state = CodeStatus.init,
    this.controllerList = const [],
    this.index = -1,
  });
  final CodeStatus state;
  final List<EditorController> controllerList;
  final int index;
  @override
  List<Object?> get props => [state, controllerList];

  CodeState copyWith({
    CodeStatus? state,
    List<EditorController>? controllerList,
    int? index,
  }) {
    return CodeState(
      state: state ?? this.state,
      controllerList: controllerList ?? this.controllerList,
      index: index ?? this.index,
    );
  }
}
