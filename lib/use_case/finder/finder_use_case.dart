import 'package:h_ide/model/h_folder.dart';
import 'package:h_ide/repo/finder/finder_repo.dart';

class FinderUseCase {
  FinderUseCase(this.repo);
  final FinderRepo repo;

  HFolder currentFolder() {
    final currentPath = repo.currentPath();
    return HFolder(currentPath);
  }
}
