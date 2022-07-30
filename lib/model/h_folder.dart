import 'dart:io';

import 'package:h_ide/model/h_binary.dart';
import 'package:h_ide/model/h_file.dart';

class HFileFolder extends HFile {
  const HFileFolder(super.path);
  List<HFile> get children {
    final Directory directory = Directory(path);
    final list = directory.listSync();
    final fileList = list.map((e) => HFile.fromPath(e.path)).toList();
    fileList.sort();
    return fileList;
  }

  List<HFileFolder> get folderList {
    final List<HFileFolder> list = [];
    for (final file in children) {
      if (file.isFolder) {
        list.add(file as HFileFolder);
      }
    }
    return list;
  }

  List<HFileBinary> get fileList {
    return List<HFileBinary>.from(children.where((e) => !e.isBinary));
  }
}
