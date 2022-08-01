import 'dart:async';
import 'dart:io';

import 'package:h_ide/data/data_base/file_box.dart';
import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderImpl implements FinderRepo {
  final StreamController<List> streamController = StreamController.broadcast();
  final FileBox fileBox = FileBox();
  late StreamSubscription fileStream;
  @override
  Future init() async {
    await fileBox.openBox();
    fileStream = fileBox.stream().listen((_) {
      streamController.add(fileBox.read());
    });
  }

  @override
  void dispose() {
    fileStream.cancel();
  }

  @override
  Stream<List> fileListStream() {
    return streamController.stream;
  }

  @override
  String currentPath() {
    return Directory.current.path;
  }

  @override
  List<String> fileList(String rootPath) {
    final file = File(rootPath);
    final stat = file.statSync();
    if (stat.type == FileSystemEntityType.file) {
      return [];
    }
    final directory = Directory(rootPath);
    return directory.listSync().map((item) => item.path).toList();
  }

  @override
  Future updateFile(String path, data) async {
    await fileBox.update(path, data);
  }
}
