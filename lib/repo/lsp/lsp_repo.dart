abstract class LSPRepo {
  Future init();
  Stream<dynamic> stream();
  void send(Map<String, dynamic> data);
}
