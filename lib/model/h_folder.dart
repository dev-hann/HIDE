import 'dart:io';

import 'package:h_ide/model/h_binary.dart';
import 'package:h_ide/model/h_file.dart';

class HFileFolder extends HFile {
  const HFileFolder(
    super.path, {
    required this.children,
  });

  final List<HFile> children;

  List<HFileFolder> get folderList =>
      children.whereType<HFileFolder>().toList();
  // {
  //   final List<HFileFolder> list = [];
  //   for (final file in children) {
  //     if (file.isFolder) {
  //       list.add(file as HFileFolder);
  //     }
  //   }
  //   return list;
  // }

  List<HFileBinary> get binaryList =>
      children.whereType<HFileBinary>().toList();
  // {
  //   return List<HFileBinary>.from(children.where((e) => !e.isBinary));
  // }

  @override
  Map<String, dynamic> toMap() {
    return {};
  }

  static List<HFile> loadChildren(
    String path, {
    required List<HFile> children,
  }) {
    final Directory directory = Directory(path);
    final rawList = directory.listSync();
    final tmpChildren = [...children];
    final childrenPathList = tmpChildren.map((item) => item.path).toList();
    final List<HFile> fileList = [];

    for (final file in rawList) {
      final path = file.path;
      final index = childrenPathList.indexWhere((item) => item == path);
      if (index != -1) {
        fileList.add(tmpChildren[index]);
      } else {
        final item = HFile.fromPath(path);
        fileList.add(item);
      }
    }
    fileList.sort();
    return fileList;
  }
}
