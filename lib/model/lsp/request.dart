class LSPRequest {
  LSPRequest(this.id, this.method, this.params);
  final String id;
  final String method;
  final Map<String, dynamic> params;

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "method": method,
      "params": params,
    };
  }

  factory LSPRequest.analysisSetPriorityFiles({
    required String id,
    required List<String> fileList,
  }) {
    return LSPRequest(
      id,
      "analysis.setPriorityFiles",
      {"files": fileList},
    );
  }
  factory LSPRequest.analysisSetAnalysisRoots({
    required String id,
    required List<String> fileList,
  }) {
    return LSPRequest(
      id,
      "analysis.setAnalysisRoots",
      {
        "included": fileList,
        "excluded": [],
      },
    );
  }
}
