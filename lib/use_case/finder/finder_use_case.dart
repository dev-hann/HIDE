import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderUseCase {
  FinderUseCase(this.repo);
  final FinderRepo repo;

  Future init() async {
    await repo.init();
  }

  Stream<Map<String, List<HFile>>> fileMapStream() {
    return repo.fileListStream().map((list) {
      final res = list.map((data) => HFile.fromMap(data)).toList();
      res.sort();
      return {};
    });
  }

  String rootPath() {
    return repo.currentPath();
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

  List<HFile> toggleOpenFolder(HFile file) {
    return [];
  }

  Future updateFile(HFile file) async {
    await repo.updateFile(file.path, file.toMap());
  }
}
