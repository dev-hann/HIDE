import 'dart:io';

import 'package:equatable/equatable.dart';

class HFile extends Equatable {
  const HFile(this.path);
  final String path;

  FileSystemEntityType get type {
    final file = File(path);
    return file.statSync().type;
  }

  bool get isHFolder {
    return type == FileSystemEntityType.directory;
  }

  @override
  List<Object?> get props => [path];
}
