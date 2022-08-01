import 'dart:io';

import 'package:equatable/equatable.dart';

class HFile extends Equatable with Comparable<HFile> {
  const HFile(
    this.path,
  );
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

  @override
  int compareTo(HFile other) {
    if (type == other.type) {
      return path.compareTo(other.path);
    }
    return isBinary ? 1 : -1;
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
    };
  }

  factory HFile.fromMap(dynamic map) {
    final data = Map<String, dynamic>.from(map);
    return HFile(
      data['path'],
    );
  }
}
