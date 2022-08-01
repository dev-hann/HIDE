import 'dart:async';
import 'dart:io';

import 'package:h_ide/data/data_base/finder_box.dart';
import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderImpl implements FinderRepo {
  final StreamController<List<String>> streamController =
      StreamController.broadcast();
  final FinderBox finderBox = FinderBox();
  late StreamSubscription fileStream;
  @override
  Future init() async {
    await finderBox.openBox();
    // await finderBox.synchronizes([]);
    fileStream = finderBox.stream().listen((_) {
      streamController.add(finderBox.read());
    });
  }

  @override
  void dispose() {
    fileStream.cancel();
  }

  @override
  Stream<List<String>> folderListStream() {
    return streamController.stream;
  }

  @override
  String rootPath() {
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
  Future closeFolder(String path) async {
    await finderBox.closeFolder(path);
  }

  @override
  Future openFolder(String path) async {
    await finderBox.openFolder(path);
  }

  @override
  bool isOpened(String path) {
    return finderBox.isOpened(path);
  }

  @override
  List<String> folderList() {
    return finderBox.read();
  }
}
