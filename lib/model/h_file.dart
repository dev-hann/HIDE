import 'dart:io';

import 'package:equatable/equatable.dart';

class HFile extends Equatable implements Comparable<HFile> {
  const HFile(
    this.path, {
    this.isModified = false,
  });
  final String path;
  final bool isModified;

  Stream<FileSystemEvent> get stream {
    return _file.watch();
  }

  FileSystemEntityType get type {
    return _file.statSync().type;
  }

  File get _file => File(path);

  String get data => _file.readAsStringSync();

  bool get isFolder {
    return type == FileSystemEntityType.directory;
  }

  bool get isBinary {
    return type == FileSystemEntityType.file;
  }

  String get name {
    return _file.path.split("/").last;
  }

  String get extension {
    return name.split(".").last.toLowerCase();
  }

  Future write(String data) {
    return _file.writeAsString(data);
  }

  @override
  List<Object?> get props => [
        path,
        isModified,
      ];

  @override
  int compareTo(HFile other) {
    if (type == other.type) {
      return path.compareTo(other.path);
    }
    return isBinary ? 1 : -1;
  }

  HFile copyWith({
    String? path,
    bool? isModified,
  }) {
    return HFile(
      path ?? this.path,
      isModified: isModified ?? this.isModified,
    );
  }
}
