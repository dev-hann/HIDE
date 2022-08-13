import 'package:h_ide/data/service/lsp_service.dart';
import 'package:h_ide/repo/lsp/lsp_repo.dart';

class LSPImpl extends LSPRepo {
  final LSPService service = LSPService();
  @override
  Future init() async {
    await service.init();
  }

  @override
  void send(Map<String, dynamic> data) {
    service.send(data);
  }

  @override
  Stream stream() {
    return service.stream();
  }
}
