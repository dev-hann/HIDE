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
    this.syntaxMap = const {},
    this.readOnly = false,
  });
  final CodeStatus state;
  final List<EditorController> controllerList;
  final int index;
  final Map<String, Syntax> syntaxMap;
  final bool readOnly;
  @override
  List<Object?> get props => [
        state,
        controllerList,
        index,
        syntaxMap,
        readOnly,
      ];

  CodeState copyWith({
    CodeStatus? state,
    List<EditorController>? controllerList,
    int? index,
    Map<String, Syntax>? syntaxMap,
    bool? readOnly,
  }) {
    return CodeState(
      state: state ?? this.state,
      controllerList: controllerList ?? this.controllerList,
      index: index ?? this.index,
      syntaxMap: syntaxMap ?? this.syntaxMap,
      readOnly: readOnly ?? this.readOnly,
    );
  }
}
