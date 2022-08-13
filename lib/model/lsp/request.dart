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
  factory LSPRequest.analysisGetErrors({
    required String id,
    required String file,
  }) {
    return LSPRequest(
      id,
      "analysis.getErrors",
      {
        "file": file,
      },
    );
  }
  factory LSPRequest.serverSetSubscriptions({
    required String id,
  }) {
    return LSPRequest(
      id,
      "server.setSubscriptions",
      {
        "subscriptions": ["LOG", "STATUS"],
      },
    );
  }
  factory LSPRequest.analysisGetHover({
    required String id,
    required String file,
    required int offset,
  }) {
    return LSPRequest(
      id,
      "analysis.getHover",
      {
        "file": file,
        "offset": offset,
      },
    );
  }
  factory LSPRequest.analysisReAnalyze({
    required String id,
  }) {
    return LSPRequest(
      id,
      "analysis.reanalyze",
      {},
    );
  }
}
