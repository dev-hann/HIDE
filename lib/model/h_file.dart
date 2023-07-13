import 'dart:io';

import 'package:equatable/equatable.dart';

class HFile extends Equatable implements Comparable<HFile> {
  const HFile(this.path);
  final String path;

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

  String get extension {
    return path.split("/").last.split(".").last;
  }

  List<HFile> get children {
    if (isBinary) {
      return [];
    }
    final directory = Directory(path);
    final list = directory.listSync().map((item) => item.path).toList();
    return list.map((e) => HFile(e)).toList();
  }

  String get name {
    return _file.path.split("/").last;
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
