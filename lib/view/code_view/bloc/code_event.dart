part of code_bloc;

abstract class CodeEvent extends Equatable {}

class CodeInitialized extends CodeEvent {
  CodeInitialized(this.file);
  final HFile file;

  @override
  List<Object?> get props => [file];
}
