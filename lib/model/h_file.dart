import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:h_ide/model/h_binary.dart';
import 'package:h_ide/model/h_folder.dart';

abstract class HFile extends Equatable with Comparable<HFile> {
  const HFile(this.path);
  final String path;

  FileSystemEntityType get type {
    final file = File(path);
    return file.statSync().type;
  }

  bool get isFolder {
    return type == FileSystemEntityType.directory;
  }

  bool get isBinary {
    return type == FileSystemEntityType.file;
  }

  @override
  List<Object?> get props => [path];

  static HFile fromPath(String path) {
    final file = File(path);
    final type = file.statSync().type;
    if (type == FileSystemEntityType.directory) {
      return HFileFolder(path);
    }
    return HFileBinary(path);
  }

  @override
  int compareTo(HFile other) {
    if (other.type == type) {
      return other.path.compareTo(path);
    }
    return isBinary ? 1 : -1;
  }
}
