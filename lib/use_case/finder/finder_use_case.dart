import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderUseCase {
  FinderUseCase(this.repo);
  final FinderRepo repo;

  Future init() async {
    await repo.init();
  }

  Stream<List<String>> folderListStream() {
    return repo.folderListStream();
  }

  String rootPath() {
    return repo.rootPath();
  }

  List<HFile> fileList(String path) {
    final list = repo.fileList(path);
    final res = list.map((item) {
      final file = HFile(item);
      return file;
    }).toList();
    res.sort();
    return res;
  }

  List<String> folderList() {
    return repo.folderList();
  }

  bool isOpened(String path) {
    return repo.isOpened(path);
  }

  Future toggleFolder(String path) async {
    final isOpened = repo.isOpened(path);
    if (isOpened) {
      await repo.closeFolder(path);
    } else {
      await repo.openFolder(path);
    }
  }
}
