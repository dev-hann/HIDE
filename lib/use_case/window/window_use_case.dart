import 'package:h_ide/repo/window/window_repo.dart';

class WindowUseCase {
  WindowUseCase(this.repo);
  final WindowRepo repo;

  Future init() async {
    await repo.init();
  }
}
