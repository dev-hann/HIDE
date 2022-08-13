import 'package:h_ide/model/lsp/request.dart';
import 'package:h_ide/model/lsp/response.dart';
import 'package:h_ide/repo/lsp/lsp_repo.dart';

class LSPUseCase {
  LSPUseCase(this.repo);
  final LSPRepo repo;

  Future init() async {
    await repo.init();
  }

  Stream<LSPResponse> stream() {
    return repo.stream().map((event) => LSPResponse.fromMap(event));
  }

  void setAnalysisRoots(String filePath) {
    _send(
      LSPRequest.analysisSetPriorityFiles(id: "TestID2", fileList: [filePath]),
    );
  }

  void setPriorityFiles(String filePath) {
    _send(
      LSPRequest.analysisSetPriorityFiles(id: "TestID", fileList: [filePath]),
    );
  }

  void _send(LSPRequest request) {
    repo.send(request.toMap());
  }
}
