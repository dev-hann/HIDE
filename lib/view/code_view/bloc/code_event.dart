part of code_bloc;

abstract class CodeEvent extends Equatable {}

class CodeInitialized extends CodeEvent {
  @override
  List<Object?> get props => [];
}

class CodeFileOpened extends CodeEvent {
  CodeFileOpened(this.file);
  final HFile file;

  @override
  List<Object?> get props => [file];
}

class CodeFileClosed extends CodeEvent {
  CodeFileClosed(this.file);
  final HFile file;

  @override
  List<Object?> get props => [file];
}

class CodeOnTapKey extends CodeEvent {
  CodeOnTapKey(this.key, this.filePath, this.offset);
  final RawKeyEvent key;
  final String filePath;
  final int offset;

  @override
  List<Object?> get props => [key, filePath, offset];
}
