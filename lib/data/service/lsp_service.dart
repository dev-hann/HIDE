import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LSPService {
  static final LSPService _instance = LSPService._internal();

  factory LSPService() {
    return _instance;
  }
  LSPService._internal();

  bool _initialized = false;
  late Process process;
  Stream<dynamic> stream() {
    final Stream<String> data =
        process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    return data.map((event) => json.decode(event));
  }

  void send(Map<String, dynamic> data) {
    process.stdin.add(utf8.encode(json.encode(data)));
  }

  Future init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    process = await _runServer();
  }

  Future<Process> _runServer() async {
    final env = Platform.environment;
    final homePath = env["HOME"]!;
    final path = "$homePath/flutter/bin/cache/dart-sdk/bin/snapshots";
    final Completer<Process> serverCompleter = Completer();
    Process.start(
      "dart",
      ["analysis_server.dart.snapshot"],
      workingDirectory: path,
    ).then(serverCompleter.complete);
    return await serverCompleter.future;
  }
}
