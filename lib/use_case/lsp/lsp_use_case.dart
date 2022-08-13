import 'package:h_ide/repo/lsp/lsp_repo.dart';

class LSPUseCase {
  LSPUseCase(this.repo);
  final LSPRepo repo;

  Future init() async {
    await repo.init();
  }
}
