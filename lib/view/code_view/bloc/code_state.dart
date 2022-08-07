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
    this.controllerMap = const {},
    this.currentControllerIndex = -1,
  });
  final CodeStatus state;
  final Map<HFile, EditorController> controllerMap;
  final int currentControllerIndex;
  @override
  List<Object?> get props => [state, controllerMap];

  CodeState copyWith({
    CodeStatus? state,
    Map<HFile, EditorController>? controllerMap,
  }) {
    return CodeState(
      state: state ?? this.state,
      controllerMap: controllerMap ?? this.controllerMap,
    );
  }
}
