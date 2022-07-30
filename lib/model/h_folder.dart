import 'dart:io';

import 'package:h_ide/model/h_file.dart';

class HFolder extends HFile {
  const HFolder(
    super.path, {
    this.isOpened = false,
  });
  final bool isOpened;
  List<HFile> get children {
    final Directory directory = Directory(path);
    final list = directory.listSync();
    return list.map((e) => HFile(e.path)).toList();
  }

  List<HFolder> get folderList {
    final List<HFolder> list = [];
    for (final file in children) {
      if (file.isHFolder) {
        list.add(HFolder(file.path));
      }
    }
    return list;
  }

  List<HFile> get fileList {
    return List<HFile>.from(children.where((e) => !e.isHFolder));
  }
}
