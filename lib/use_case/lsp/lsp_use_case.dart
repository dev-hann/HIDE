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

  void serverSetSubscriptions() {
    _send(
      LSPRequest.serverSetSubscriptions(id: "SubID"),
    );
  }

  void analysisReAnalyze() {
    _send(
      LSPRequest.analysisReAnalyze(id: "TEstID"),
    );
  }

  void analysisGetErrors(String filePath) {
    _send(
      LSPRequest.analysisGetErrors(id: "TestID", file: filePath),
    );
  }

  void setAnalysisRoots(List<String> fileList) {
    _send(
      LSPRequest.analysisSetAnalysisRoots(id: "TestID", fileList: fileList),
    );
  }

  void setPriorityFiles(String filePath) {
    _send(
      LSPRequest.analysisSetPriorityFiles(id: "TestID", fileList: [filePath]),
    );
  }

  void completionGetSuggestions(String filePath, int offset) {
    _send(
      LSPRequest.completionGetSuggestions(
        id: "TestID",
        file: filePath,
        offset: offset,
      ),
    );
  }

  void _send(LSPRequest request) {
    repo.send(request.toMap());
  }
}
