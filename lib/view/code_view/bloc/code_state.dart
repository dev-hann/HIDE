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
    this.list = const [],
  });
  final CodeStatus state;
  final List<dynamic> list;
  @override
  List<Object?> get props => [state, list];

  CodeState copyWith({
    CodeStatus? state,
    List<dynamic>? list,
  }) {
    return CodeState(
      state: state ?? this.state,
      list: list ?? this.list,
    );
  }
}
