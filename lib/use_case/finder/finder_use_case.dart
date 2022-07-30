import 'package:h_ide/model/h_file.dart';
import 'package:h_ide/model/h_folder.dart';
import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderUseCase {
  FinderUseCase(this.repo);
  final FinderRepo repo;

  HFileFolder currentFolder() {
    final currentPath = repo.currentPath();
    return HFileFolder(currentPath);
  }

  Map<HFileFolder, bool> toggleFolderOpen(
      Map<HFileFolder, bool> openedMap, HFile file) {
    final isOpened = openedMap[file] ?? false;
    openedMap[file as HFileFolder] = !isOpened;
    return openedMap;
  }
}
